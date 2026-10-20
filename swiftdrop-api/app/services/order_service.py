from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.models.order import Order, OrderItem
from app.models.restaurant import MenuItem, Restaurant
from app.models.user import User
from app.schemas.order import CreateOrderRequest, OrderResponse
from app.config import get_settings
from app.services.pricing_service import price_cosmetics, price_gas, price_parcel

settings = get_settings()


VALID_TRANSITIONS = {
    "CREATED": ["CONFIRMED", "CANCELLED"],
    "CONFIRMED": ["PREPARING", "CANCELLED"],
    "PREPARING": ["READY_FOR_PICKUP", "CANCELLED"],
    "READY_FOR_PICKUP": ["PICKED_UP"],
    "PICKED_UP": ["EN_ROUTE"],
    "EN_ROUTE": ["DELIVERED"],
    "DELIVERY_FAILED": [],
    "DELIVERED": [],
    "CANCELLED": [],
}


def _validate_transition(current_status: str, new_status: str) -> None:
    allowed = VALID_TRANSITIONS.get(current_status, [])
    if new_status not in allowed:
        raise BadRequestException(
            f"Cannot transition from {current_status} to {new_status}"
        )


def _actor_can_transition(order: Order, new_status: str, actor: User | None) -> None:
    if actor is None:
        return
    if actor.role == "admin":
        return
    if actor.role == "customer":
        if order.customer_id != actor.id or new_status != "CANCELLED":
            raise ForbiddenException("Customer cannot perform this order transition")
        return
    if actor.role == "merchant":
        if new_status not in {"CONFIRMED", "PREPARING", "READY_FOR_PICKUP", "CANCELLED"}:
            raise ForbiddenException("Merchant cannot perform this order transition")
        return
    if actor.role == "rider":
        if order.rider_id != actor.id or new_status not in {
            "PICKED_UP", "EN_ROUTE", "DELIVERED", "DELIVERY_FAILED"
        }:
            raise ForbiddenException("Rider cannot perform this order transition")
        return
    raise ForbiddenException("User cannot perform order transitions")


async def transition_order(
    db: AsyncSession,
    order_id: UUID,
    new_status: str,
    *,
    actor: User | None = None,
    reason: str | None = None,
    metadata: dict | None = None,
) -> OrderResponse:
    result = await db.execute(
        select(Order)
        .options(selectinload(Order.items), selectinload(Order.rider).selectinload(User.rider_profile))
        .where(Order.id == order_id)
        .with_for_update()
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    _actor_can_transition(order, new_status, actor)
    _validate_transition(order.status, new_status)

    now = datetime.now(timezone.utc)
    previous_status = order.status
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
    if new_status == "CONFIRMED":
        order.vendor_responded_at = now
    transition = {
        "status": new_status,
        "from_status": previous_status,
        "timestamp": now.isoformat(),
        "actor_id": str(actor.id) if actor else None,
        "actor_role": actor.role if actor else "system",
        "reason": reason,
        "metadata": metadata or {},
    }
    order.status_history = (order.status_history or []) + [transition]
    await db.flush()
    return _order_to_response(order)


async def create_order(
    db: AsyncSession, customer_id: UUID, request: CreateOrderRequest
) -> OrderResponse:
    existing = await db.execute(
        select(Order).options(
            selectinload(Order.items),
            selectinload(Order.rider).selectinload(User.rider_profile),
        ).where(
            Order.customer_id == customer_id,
            Order.idempotency_key == request.idempotency_key,
        )
    )
    existing_order = existing.scalar_one_or_none()
    if existing_order:
        if existing_order.status == "CANCELLED":
            raise ConflictException("This order request was already cancelled")
        return _order_to_response(existing_order)

    priced_items = []
    if request.order_type == "food":
        if not request.items:
            raise BadRequestException("Food orders must contain at least one item")
        restaurant_query = select(Restaurant).where(
            Restaurant.name == request.restaurant_name,
            Restaurant.is_active.is_(True),
        )
        restaurant = (await db.execute(restaurant_query)).scalar_one_or_none()
        if not restaurant:
            raise BadRequestException("Restaurant is unavailable")
        menu_ids = [item.menu_item_id for item in request.items]
        if any(not item_id for item_id in menu_ids):
            raise BadRequestException("Food items must include menu item IDs")
        menu_result = await db.execute(
            select(MenuItem).where(
                MenuItem.restaurant_id == restaurant.id,
                MenuItem.id.in_(menu_ids),
                MenuItem.is_available.is_(True),
            )
        )
        menu_by_id = {str(item.id): item for item in menu_result.scalars().all()}
        if len(menu_by_id) != len(set(menu_ids)):
            raise BadRequestException("One or more food items are unavailable")
        subtotal = round(
            sum(float(menu_by_id[item.menu_item_id].price) * item.quantity for item in request.items),
            2,
        )
        delivery_fee = round(float(restaurant.delivery_fee), 2)
        tax = round(subtotal * 0.0, 2)
        discount = 0.0
        total = round(subtotal + delivery_fee + tax - discount, 2)
        priced_items = [
            {"name": item.name, "quantity": item.quantity,
             "price": float(menu_by_id[item.menu_item_id].price), "notes": item.notes}
            for item in request.items
        ]
    elif request.order_type == "cosmetics":
        subtotal, priced_items = await price_cosmetics(db, request.items)
        delivery_fee = 5.0
        tax = 0.0
        discount = 0.0
        total = round(subtotal + delivery_fee, 2)
    elif request.restaurant_name == "LPG Gas Depot (Tarkwa)":
        metadata = request.metadata or {}
        subtotal, delivery_fee = await price_gas(db, metadata)
        tax = 0.0
        discount = 0.0
        total = round(subtotal + delivery_fee, 2)
    else:
        subtotal, delivery_fee = await price_parcel(
            request.metadata or {}, request.pickup_lat, request.pickup_lng,
            request.delivery_lat, request.delivery_lng
        )
        tax = 0.0
        discount = 0.0
        total = round(subtotal + delivery_fee, 2)

    import random
    delivery_pin = "".join([str(random.randint(0, 9)) for _ in range(4)])
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
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        tax=tax,
        discount=discount,
        total=total,
        promo_code=request.promo_code,
        idempotency_key=request.idempotency_key,
        status="CREATED",
        delivery_pin=delivery_pin,
        metadata_={"delivery_pin": delivery_pin, **(request.metadata or {})},
        vendor_response_deadline=(
            datetime.now(timezone.utc)
            + timedelta(minutes=settings.VENDOR_RESPONSE_WINDOW_MINUTES)
            if request.order_type == "food"
            else None
        ),
    )
    db.add(order)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        duplicate_result = await db.execute(
            select(Order).options(
                selectinload(Order.items),
                selectinload(Order.rider).selectinload(User.rider_profile),
            ).where(
                Order.customer_id == customer_id,
                Order.idempotency_key == request.idempotency_key,
            )
        )
        duplicate_order = duplicate_result.scalar_one_or_none()
        if duplicate_order:
            return _order_to_response(duplicate_order)
        raise

    order_items = []
    for index, item in enumerate(request.items):
        priced = priced_items[index] if index < len(priced_items) else None
        order_item = OrderItem(
            order_id=order.id,
            menu_item_id=UUID(item.menu_item_id) if item.menu_item_id else None,
            name=item.name,
            quantity=item.quantity,
            cosmetic_product_id=(
                UUID(item.cosmetic_product_id)
                if item.cosmetic_product_id else None
            ),
            price=priced["price"] if priced else item.price,
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


async def get_order(
    db: AsyncSession, order_id: UUID, customer_id: UUID | None = None
) -> OrderResponse:
    query = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.rider).selectinload(User.rider_profile),
    ).where(Order.id == order_id)
    if customer_id:
        query = query.where(Order.customer_id == customer_id)
    result = await db.execute(query)
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
    return await transition_order(
        db, order_id, "CANCELLED",
        actor=await _get_user(db, customer_id),
        reason="customer_requested",
    )


async def update_order_status(
    db: AsyncSession, order_id: UUID, new_status: str, actor: User | None = None,
    reason: str | None = None,
) -> OrderResponse:
    return await transition_order(db, order_id, new_status, actor=actor, reason=reason)


async def _get_user(db: AsyncSession, user_id: UUID) -> User:
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")
    return user


def _order_to_response(order: Order, items: list[OrderItem] | None = None) -> OrderResponse:
    rider_name = None
    rider_phone = None
    rider_avatar = None
    rider_vehicle_type = None
    rider_lat = None
    rider_lng = None
    if order.rider:
        rider_name = order.rider.name
        rider_phone = order.rider.phone
        rider_avatar = order.rider.avatar_url
        if hasattr(order.rider, 'rider_profile') and order.rider.rider_profile:
            rider_vehicle_type = order.rider.rider_profile.vehicle_type
            rider_lat = float(order.rider.rider_profile.last_lat) if order.rider.rider_profile.last_lat else None
            rider_lng = float(order.rider.rider_profile.last_lng) if order.rider.rider_profile.last_lng else None

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
        rider_lat=rider_lat,
        rider_lng=rider_lng,
        delivery_pin=order.metadata_.get("delivery_pin") if order.metadata_ else None,
        tracking_url=f"{settings.APP_BASE_URL}/api/v1/orders/{order.id}/tracking",
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


async def expire_vendor_orders(db: AsyncSession) -> int:
    """Expire unacknowledged food orders; safe to call repeatedly from a scheduler."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(Order)
        .where(
            Order.order_type == "food",
            Order.status == "CREATED",
            Order.vendor_response_deadline.is_not(None),
            Order.vendor_response_deadline <= now,
        )
        .with_for_update(skip_locked=True)
    )
    orders = result.scalars().all()
    for order in orders:
        await transition_order(
            db, order.id, "CANCELLED", reason="vendor_response_timeout"
        )
    return len(orders)
