from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.models.order import Order, OrderItem
from app.models.user import User
from app.schemas.order import CreateOrderRequest, OrderResponse


VALID_TRANSITIONS = {
    "CREATED": ["CONFIRMED", "CANCELLED"],
    "CONFIRMED": ["PREPARING", "CANCELLED"],
    "PREPARING": ["READY_FOR_PICKUP", "CANCELLED"],
    "READY_FOR_PICKUP": ["PICKED_UP"],
    "PICKED_UP": ["EN_ROUTE"],
    "EN_ROUTE": ["DELIVERED"],
    "DELIVERED": [],
    "CANCELLED": [],
}


def _validate_transition(current_status: str, new_status: str) -> None:
    allowed = VALID_TRANSITIONS.get(current_status, [])
    if new_status not in allowed:
        raise BadRequestException(
            f"Cannot transition from {current_status} to {new_status}"
        )


async def create_order(
    db: AsyncSession, customer_id: UUID, request: CreateOrderRequest
) -> OrderResponse:
    order = Order(
        customer_id=customer_id,
        order_type=request.order_type,
        restaurant_name=request.restaurant_name,
        pickup_address=request.pickup_address,
        pickup_lat=request.pickup_lat,
        pickup_lng=request.pickup_lng,
        delivery_address=request.delivery_address,
        delivery_lat=request.delivery_lat,
        delivery_lng=request.delivery_lng,
        subtotal=request.subtotal,
        delivery_fee=request.delivery_fee,
        tax=request.tax,
        discount=request.discount,
        total=request.total,
        promo_code=request.promo_code,
        status="CREATED",
    )
    db.add(order)
    await db.flush()

    order_items = []
    for item in request.items:
        order_item = OrderItem(
            order_id=order.id,
            name=item.name,
            quantity=item.quantity,
            price=item.price,
            notes=item.notes,
        )
        db.add(order_item)
        order_items.append(order_item)

    await db.flush()

    order.status_history = [
        {
            "status": "CREATED",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "note": "Order created",
        }
    ]
    await db.flush()

    return _order_to_response(order, order_items)


async def list_orders(
    db: AsyncSession, customer_id: UUID | None = None, rider_id: UUID | None = None
) -> list[OrderResponse]:
    query = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.rider).selectinload(User.rider_profile)
    )
    if customer_id:
        query = query.where(Order.customer_id == customer_id)
    if rider_id:
        query = query.where(Order.rider_id == rider_id)
    query = query.order_by(Order.created_at.desc())

    result = await db.execute(query)
    orders = result.scalars().all()
    return [_order_to_response(o) for o in orders]


async def get_order(db: AsyncSession, order_id: UUID) -> OrderResponse:
    result = await db.execute(
        select(Order).options(
            selectinload(Order.items),
            selectinload(Order.rider).selectinload(User.rider_profile)
        ).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    return _order_to_response(order)


async def cancel_order(
    db: AsyncSession, order_id: UUID, customer_id: UUID
) -> OrderResponse:
    result = await db.execute(
        select(Order).options(selectinload(Order.items)).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.customer_id != customer_id:
        raise ForbiddenException("Not your order")
    _validate_transition(order.status, "CANCELLED")
    order.status = "CANCELLED"
    order.cancelled_at = datetime.now(timezone.utc)
    order.status_history = (order.status_history or []) + [
        {
            "status": "CANCELLED",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    ]
    await db.flush()
    return _order_to_response(order)


async def update_order_status(
    db: AsyncSession, order_id: UUID, new_status: str
) -> OrderResponse:
    result = await db.execute(
        select(Order).options(selectinload(Order.items)).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    _validate_transition(order.status, new_status)
    now = datetime.now(timezone.utc)
    order.status = new_status
    status_time_map = {
        "CONFIRMED": "confirmed_at",
        "PREPARING": "preparing_at",
        "PICKED_UP": "picked_up_at",
        "DELIVERED": "delivered_at",
        "CANCELLED": "cancelled_at",
    }
    attr = status_time_map.get(new_status)
    if attr:
        setattr(order, attr, now)
    order.status_history = (order.status_history or []) + [
        {"status": new_status, "timestamp": now.isoformat()}
    ]
    await db.flush()
    return _order_to_response(order)


def _order_to_response(order: Order, items: list[OrderItem] | None = None) -> OrderResponse:
    rider_name = None
    rider_phone = None
    rider_avatar = None
    rider_vehicle_type = None
    if order.rider:
        rider_name = order.rider.name
        rider_phone = order.rider.phone
        rider_avatar = order.rider.avatar_url
        if hasattr(order.rider, 'rider_profile') and order.rider.rider_profile:
            rider_vehicle_type = order.rider.rider_profile.vehicle_type

    return OrderResponse(
        id=str(order.id),
        customer_id=str(order.customer_id),
        rider_id=str(order.rider_id) if order.rider_id else None,
        rider_name=rider_name,
        rider_phone=rider_phone,
        rider_avatar=rider_avatar,
        rider_vehicle_type=rider_vehicle_type,
        order_type=order.order_type,
        status=order.status,
        restaurant_name=order.restaurant_name,
        pickup_address=order.pickup_address,
        pickup_lat=order.pickup_lat,
        pickup_lng=order.pickup_lng,
        delivery_address=order.delivery_address,
        delivery_lat=order.delivery_lat,
        delivery_lng=order.delivery_lng,
        subtotal=float(order.subtotal),
        delivery_fee=float(order.delivery_fee),
        tax=float(order.tax),
        discount=float(order.discount),
        total=float(order.total),
        promo_code=order.promo_code,
        payment_ref=order.payment_ref,
        payment_status=order.payment_status,
        created_at=order.created_at,
        confirmed_at=order.confirmed_at,
        preparing_at=order.preparing_at,
        picked_up_at=order.picked_up_at,
        delivered_at=order.delivered_at,
        cancelled_at=order.cancelled_at,
        items=[
            {
                "id": str(item.id),
                "name": item.name,
                "quantity": item.quantity,
                "price": float(item.price),
                "notes": item.notes,
            }
            for item in (items if items is not None else order.items or [])
        ],
    )
