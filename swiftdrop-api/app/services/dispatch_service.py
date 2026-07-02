import json
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.order import DispatchLog, Order
from app.models.user import RiderProfile, User
from app.services.order_service import update_order_status


async def get_available_orders(db: AsyncSession) -> list[dict]:
    result = await db.execute(
        select(Order)
        .where(Order.status == "CONFIRMED", Order.rider_id.is_(None))
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
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.status != "CONFIRMED":
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

    await db.flush()
    return {"message": "Order accepted", "order_id": str(order_id)}


async def reject_order(db: AsyncSession, order_id: UUID, rider_id: UUID, reason: str | None = None) -> dict:
    log = DispatchLog(order_id=order_id, rider_id=rider_id, action="REJECTED", reason=reason)
    db.add(log)
    await db.flush()
    return {"message": "Order rejected"}
