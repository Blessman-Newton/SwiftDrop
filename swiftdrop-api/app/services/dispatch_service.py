import json
import math
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.order import DispatchLog, Order
from app.models.user import RiderProfile, User
from app.models.notification import Notification
from app.services.order_service import update_order_status


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
        .where(Order.status.in_(["CONFIRMED", "PREPARING", "READY_FOR_PICKUP"]), Order.rider_id.is_(None))
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
        select(Order).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.status not in ["CONFIRMED", "PREPARING", "READY_FOR_PICKUP"]:
        raise BadRequestException("Order not available for pickup")
    if order.rider_id is not None:
        raise BadRequestException("Order already assigned")

    order.rider_id = rider_id
    order.status = "READY_FOR_PICKUP"
    order.status_history = (order.status_history or []) + [
        {"status": "READY_FOR_PICKUP", "timestamp": datetime.now(timezone.utc).isoformat(), "rider_id": str(rider_id)}
    ]

    log = DispatchLog(order_id=order_id, rider_id=rider_id, action="ACCEPTED")
    db.add(log)

    profile_result = await db.execute(select(RiderProfile).where(RiderProfile.user_id == rider_id))
    profile = profile_result.scalar_one_or_none()
    if profile:
        profile.current_order_id = order_id

    rider_result = await db.execute(select(User).where(User.id == rider_id))
    rider = rider_result.scalar_one_or_none()
    rider_name = rider.name if rider else "Your rider"

    customer_notification = Notification(
        user_id=order.customer_id,
        title="Rider Assigned",
        body=f"Good news! {rider_name} has been assigned to deliver your order. They will arrive at the merchant shortly to pick it up.",
        type="order",
        metadata_={
            "order_id": str(order_id),
            "rider_name": rider_name,
            "rider_id": str(rider_id),
            "status": "rider_assigned",
        },
    )
    db.add(customer_notification)

    await db.flush()
    return {"message": "Order accepted", "order_id": str(order_id)}


async def reject_order(db: AsyncSession, order_id: UUID, rider_id: UUID, reason: str | None = None) -> dict:
    log = DispatchLog(order_id=order_id, rider_id=rider_id, action="REJECTED", reason=reason)
    db.add(log)
    await db.flush()
    return {"message": "Order rejected"}


async def auto_match_rider(db: AsyncSession, order_id: UUID) -> dict:
    order_result = await db.execute(select(Order).where(Order.id == order_id))
    order = order_result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.rider_id is not None:
        return {"status": "already_assigned", "rider_id": str(order.rider_id)}

    pickup_lat = order.pickup_lat
    pickup_lng = order.pickup_lng
    if pickup_lat is None or pickup_lng is None:
        pickup_lat = 7.3349
        pickup_lng = -2.3266

    riders_query = select(RiderProfile).where(
        RiderProfile.is_online == True,
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

    order.rider_id = closest_rider.user_id
    order.status = "READY_FOR_PICKUP"
    order.status_history = (order.status_history or []) + [
        {"status": "READY_FOR_PICKUP", "timestamp": datetime.now(timezone.utc).isoformat(), "rider_id": str(closest_rider.user_id)}
    ]

    closest_rider.current_order_id = order.id
    
    rider_notification = Notification(
        user_id=closest_rider.user_id,
        title="New Order Assigned",
        body=f"You have been assigned a new delivery to pickup at {order.restaurant_name or 'merchant'}.",
        type="order",
        metadata_={
            "order_id": str(order_id),
            "status": "assigned",
        },
    )
    db.add(rider_notification)

    rider_user = (await db.execute(select(User).where(User.id == closest_rider.user_id))).scalar_one_or_none()
    rider_name = rider_user.name if rider_user else "Your rider"

    customer_notification = Notification(
        user_id=order.customer_id,
        title="Rider Assigned",
        body=f"{rider_name} is on their way to pick up your order.",
        type="order",
        metadata_={
            "order_id": str(order_id),
            "rider_name": rider_name,
            "status": "rider_assigned",
        },
    )
    db.add(customer_notification)

    db.add(DispatchLog(order_id=order_id, rider_id=closest_rider.user_id, action="AUTO_MATCHED"))
    await db.flush()

    return {
        "status": "assigned",
        "rider_id": str(closest_rider.user_id),
        "rider_name": rider_name,
        "distance_km": round(min_distance, 2)
    }

