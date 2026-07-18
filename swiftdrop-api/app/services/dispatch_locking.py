import uuid
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException
from app.models.order import DispatchLog, Order
from app.models.user import RiderProfile, User
from app.models.notification import Notification
from app.services.dispatch_service import calculate_distance


async def safe_auto_match_rider(db: AsyncSession, order_id: UUID) -> dict:
    """
    Safely match a rider to an order using database locks to prevent concurrent matches.
    Uses SELECT ... FOR UPDATE to lock the order and SELECT ... FOR UPDATE SKIP LOCKED
    to safely find available riders without deadlocks.
    """
    order_result = await db.execute(
        select(Order).where(Order.id == order_id).with_for_update()
    )
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
    ).with_for_update(skip_locked=True)
    
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
