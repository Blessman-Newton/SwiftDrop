import json
import math
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.order import DispatchLog, Order
from app.models.user import RiderProfile, User
from app.services.notification_service import (
    notify_new_delivery_request,
    notify_rider_assigned,
    send_push_to_user,
)
from app.config import get_settings

settings = get_settings()


def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c



async def get_available_orders(db: AsyncSession) -> list[dict]:
    result = await db.execute(
        select(Order)
        .where(
            (
                (Order.order_type != "food") & Order.status.in_(["CONFIRMED", "PREPARING", "READY_FOR_PICKUP"])
            ) | (
                (Order.order_type == "food") & Order.status.in_(["PREPARING", "READY_FOR_PICKUP"])
            ),
            Order.rider_id.is_(None)
        )
        .order_by(Order.created_at.asc())
    )
    orders = result.scalars().all()
    return [
        {
            "id": str(o.id),
            "order_type": o.order_type,
            "restaurant_name": o.restaurant_name,
            "pickup_address": o.pickup_address,
            "delivery_address": o.delivery_address,
            "total": float(o.total),
            "delivery_fee": float(o.delivery_fee),
            "pickup_lat": o.pickup_lat,
            "pickup_lng": o.pickup_lng,
            "delivery_lat": o.delivery_lat,
            "delivery_lng": o.delivery_lng,
            "created_at": o.created_at.isoformat(),
        }
        for o in orders
    ]


async def go_online(
    db: AsyncSession, user_id: UUID, vehicle_type: str | None = None, license_number: str | None = None
) -> dict:
    result = await db.execute(select(RiderProfile).where(RiderProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = RiderProfile(user_id=user_id)
        db.add(profile)

    profile.is_online = True
    if vehicle_type:
        profile.vehicle_type = vehicle_type
    if license_number:
        profile.license_number = license_number
    await db.flush()
    return {"message": "Now online", "is_online": True}


async def go_offline(db: AsyncSession, user_id: UUID) -> dict:
    result = await db.execute(select(RiderProfile).where(RiderProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if profile:
        profile.is_online = False
        await db.flush()
    return {"message": "Now offline", "is_online": False}


async def accept_order(db: AsyncSession, order_id: UUID, rider_id: UUID) -> dict:
    result = await db.execute(
        select(Order).where(Order.id == order_id).with_for_update()
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    allowed_statuses = ["PREPARING", "READY_FOR_PICKUP"] if order.order_type == "food" else ["CONFIRMED", "PREPARING", "READY_FOR_PICKUP"]
    if order.status not in allowed_statuses:
        raise BadRequestException("Order not available for pickup yet. Merchant must accept it first.")
    rider_profile_result = await db.execute(
        select(RiderProfile).where(RiderProfile.user_id == rider_id).with_for_update()
    )
    profile = rider_profile_result.scalar_one_or_none()
    if not profile or profile.is_banned or not profile.is_online:
        raise BadRequestException("Rider must be online and eligible for dispatch")
    if profile.current_order_id is not None:
        raise BadRequestException("Rider already has an active order")
    if order.rider_id is not None:
        raise BadRequestException("Order already assigned")

    order.rider_id = rider_id
    from datetime import datetime, timedelta, timezone
    order.dispatch_offer_deadline = datetime.now(timezone.utc) + timedelta(
        minutes=settings.RIDER_ACCEPTANCE_WINDOW_MINUTES
    )
    order.dispatch_attempts += 1
    log = DispatchLog(order_id=order_id, rider_id=rider_id, action="ACCEPTED")
    db.add(log)

    profile.current_order_id = order_id

    rider_result = await db.execute(select(User).where(User.id == rider_id))
    rider = rider_result.scalar_one_or_none()
    rider_name = rider.name if rider else "Your rider"

    await db.flush()
    await notify_rider_assigned(db, order.customer_id, str(order_id), rider_name)
    return {"message": "Order accepted", "order_id": str(order_id)}


async def reject_order(db: AsyncSession, order_id: UUID, rider_id: UUID, reason: str | None = None) -> dict:
    result = await db.execute(select(Order).where(Order.id == order_id).with_for_update())
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.rider_id not in {None, rider_id}:
        raise BadRequestException("Order is assigned to another rider")
    log = DispatchLog(order_id=order_id, rider_id=rider_id, action="REJECTED", reason=reason)
    db.add(log)
    if order.rider_id == rider_id:
        profile = await db.scalar(
            select(RiderProfile).where(RiderProfile.user_id == rider_id).with_for_update()
        )
        order.rider_id = None
        order.dispatch_offer_deadline = None
        if profile and profile.current_order_id == order_id:
            profile.current_order_id = None
    await db.flush()
    return {"message": "Order rejected"}


async def reassign_order(db: AsyncSession, order_id: UUID) -> dict:
    result = await db.execute(select(Order).where(Order.id == order_id).with_for_update())
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.rider_id:
        profile = await db.scalar(
            select(RiderProfile).where(RiderProfile.user_id == order.rider_id).with_for_update()
        )
        if profile and profile.current_order_id == order_id:
            profile.current_order_id = None
        db.add(DispatchLog(order_id=order_id, rider_id=order.rider_id, action="REASSIGNED"))
        order.rider_id = None
        order.dispatch_offer_deadline = None
    await db.flush()
    return await auto_match_rider(db, order_id)


async def auto_match_rider(db: AsyncSession, order_id: UUID) -> dict:
    order_result = await db.execute(select(Order).where(Order.id == order_id).with_for_update())
    order = order_result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.rider_id is not None:
        return {"status": "already_assigned", "rider_id": str(order.rider_id)}
    if order.payment_status != "paid":
        return {"status": "unpaid", "message": "Order has not been paid yet"}

    pickup_lat = order.pickup_lat
    pickup_lng = order.pickup_lng
    if pickup_lat is None or pickup_lng is None:
        pickup_lat = 7.3349
        pickup_lng = -2.3266

    riders_query = select(RiderProfile).where(
        RiderProfile.is_online == True,
        RiderProfile.is_banned == False,
        RiderProfile.current_order_id.is_(None),
        RiderProfile.last_lat.is_not(None),
        RiderProfile.last_lng.is_not(None),
    )
    riders_result = await db.execute(riders_query)
    rider_profiles = riders_result.scalars().all()

    if not rider_profiles:
        return {"status": "no_riders_available"}

    closest_rider = None
    min_distance = float('inf')

    for profile in rider_profiles:
        dist = calculate_distance(
            float(pickup_lat), float(pickup_lng),
            float(profile.last_lat), float(profile.last_lng)
        )
        if dist < min_distance:
            min_distance = dist
            closest_rider = profile

    if not closest_rider:
        return {"status": "no_riders_available"}

    closest_rider = (await db.execute(
        select(RiderProfile)
        .where(RiderProfile.user_id == closest_rider.user_id)
        .with_for_update()
    )).scalar_one()
    if closest_rider.current_order_id is not None:
        return {"status": "rider_taken"}
    order.rider_id = closest_rider.user_id
    closest_rider.current_order_id = order.id
    from datetime import datetime, timedelta, timezone
    order.dispatch_offer_deadline = datetime.now(timezone.utc) + timedelta(
        minutes=settings.RIDER_ACCEPTANCE_WINDOW_MINUTES
    )
    order.dispatch_attempts += 1
    
    rider_user = (await db.execute(select(User).where(User.id == closest_rider.user_id))).scalar_one_or_none()
    rider_name = rider_user.name if rider_user else "Your rider"

    db.add(DispatchLog(order_id=order_id, rider_id=closest_rider.user_id, action="AUTO_MATCHED"))
    await db.flush()
    await notify_new_delivery_request(
        db,
        closest_rider.user_id,
        str(order_id),
        order.pickup_address,
    )
    await notify_rider_assigned(db, order.customer_id, str(order_id), rider_name)

    return {
        "status": "assigned",
        "rider_id": str(closest_rider.user_id),
        "rider_name": rider_name,
        "distance_km": round(min_distance, 2)
    }


async def expire_dispatch_offers(db: AsyncSession, limit: int = 50) -> dict:
    """Expire assigned rider offers and safely requeue each order."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(Order)
        .where(
            Order.rider_id.is_not(None),
            Order.dispatch_offer_deadline.is_not(None),
            Order.dispatch_offer_deadline <= now,
            Order.status.in_(["CONFIRMED", "PREPARING", "READY_FOR_PICKUP"]),
        )
        .order_by(Order.dispatch_offer_deadline.asc())
        .limit(limit)
        .with_for_update(skip_locked=True)
    )
    expired = result.scalars().all()
    reassigned = 0
    for order in expired:
        rider_id = order.rider_id
        profile = await db.scalar(
            select(RiderProfile)
            .where(RiderProfile.user_id == rider_id)
            .with_for_update()
        )
        if profile and profile.current_order_id == order.id:
            profile.current_order_id = None
        db.add(DispatchLog(order_id=order.id, rider_id=rider_id, action="EXPIRED"))
        await send_push_to_user(
            db,
            rider_id,
            "Order offer expired",
            "This delivery offer expired and has been returned to dispatch.",
            type="rider",
            metadata={"order_id": str(order.id), "status": "dispatch_expired"},
        )
        order.rider_id = None
        order.dispatch_offer_deadline = None
        await db.flush()
        match = await auto_match_rider(db, order.id)
        if match.get("status") == "assigned":
            reassigned += 1
    await db.flush()
    return {"expired": len(expired), "reassigned": reassigned}
