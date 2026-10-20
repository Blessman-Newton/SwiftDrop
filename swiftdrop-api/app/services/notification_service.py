import logging
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.models.user import User
from app.services.firebase_service import send_fcm_notification

logger = logging.getLogger(__name__)


async def create_notification(
    db: AsyncSession,
    user_id: UUID,
    title: str,
    body: str,
    type: str = "system",
    metadata: dict | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        title=title,
        body=body,
        type=type,
        metadata_=metadata or {},
    )
    db.add(notification)
    await db.flush()
    return notification


async def send_push_to_user(
    db: AsyncSession,
    user_id: UUID,
    title: str,
    body: str,
    type: str = "system",
    metadata: dict | None = None,
) -> bool:
    notification = await create_notification(db, user_id, title, body, type, metadata)

    result = await db.execute(
        select(User.fcm_token).where(User.id == user_id, User.fcm_token.is_not(None))
    )
    fcm_token = result.scalar_one_or_none()

    if not fcm_token:
        logger.info(f"No FCM token for user {user_id}, notification saved to DB only")
        return False

    success = send_fcm_notification(
        token=fcm_token,
        title=title,
        body=body,
        data={**(metadata or {}), "notification_id": str(notification.id)},
    )

    return success


async def notify_order_confirmation(db: AsyncSession, customer_id: UUID, order_id: str, restaurant_name: str) -> None:
    await send_push_to_user(
        db,
        customer_id,
        "Order Confirmed",
        f"Your order from {restaurant_name} has been confirmed.",
        type="order",
        metadata={"order_id": order_id, "status": "confirmed"},
    )


async def notify_payment_status(db: AsyncSession, customer_id: UUID, order_id: str, status: str) -> None:
    title = "Payment Successful" if status == "paid" else "Payment Failed"
    body = "Your payment has been processed successfully." if status == "paid" else "Your payment could not be processed. Please try again."
    await send_push_to_user(
        db,
        customer_id,
        title,
        body,
        type="payment",
        metadata={"order_id": order_id, "status": status},
    )


async def notify_rider_assigned(db: AsyncSession, customer_id: UUID, order_id: str, rider_name: str) -> None:
    await send_push_to_user(
        db,
        customer_id,
        "Rider Assigned",
        f"{rider_name} has been assigned to your order and is on the way.",
        type="order",
        metadata={"order_id": order_id, "status": "rider_assigned", "rider_name": rider_name},
    )


async def notify_order_status_update(db: AsyncSession, customer_id: UUID, order_id: str, status: str) -> None:
    status_messages = {
        "PREPARING": ("Preparing Your Order", "The restaurant is preparing your order."),
        "READY_FOR_PICKUP": ("Order Ready", "Your order is ready for pickup."),
        "PICKED_UP": ("Order Picked Up", "Your order has been picked up by the rider."),
        "EN_ROUTE": ("On the Way", "Your order is on its way to you."),
        "DELIVERED": ("Order Delivered", "Your order has been delivered. Enjoy!"),
        "CANCELLED": ("Order Cancelled", "Your order has been cancelled."),
    }
    title, body = status_messages.get(status, ("Order Update", f"Order status: {status}"))
    await send_push_to_user(
        db,
        customer_id,
        title,
        body,
        type="order",
        metadata={"order_id": order_id, "status": status},
    )


async def notify_new_order_merchant(db: AsyncSession, merchant_id: UUID, order_id: str, order_total: float) -> None:
    await send_push_to_user(
        db,
        merchant_id,
        "New Order Received",
        f"A new order worth GHS {order_total:.2f} has been placed.",
        type="order",
        metadata={"order_id": order_id, "status": "new_order"},
    )


async def notify_new_delivery_request(db: AsyncSession, rider_id: UUID, order_id: str, pickup_address: str) -> None:
    await send_push_to_user(
        db,
        rider_id,
        "New Delivery Request",
        f"A new delivery is available. Pickup: {pickup_address}",
        type="rider",
        metadata={"order_id": order_id, "status": "new_request"},
    )


async def notify_order_cancelled_rider(db: AsyncSession, rider_id: UUID, order_id: str) -> None:
    await send_push_to_user(
        db,
        rider_id,
        "Order Cancelled",
        "The order you were assigned to has been cancelled.",
        type="rider",
        metadata={"order_id": order_id, "status": "cancelled"},
    )
