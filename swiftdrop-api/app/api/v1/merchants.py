from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.category import Category
from app.models.order import Order, OrderItem
from app.models.restaurant import MenuItem, Restaurant
from app.models.user import User
from app.schemas.merchant import (
    DashboardStatsResponse,
    MenuItemCreateRequest,
    MenuItemResponse,
    MenuItemUpdateRequest,
    MerchantInfoResponse,
    OrderItemResponse,
    OrderResponse,
    RestaurantCreateRequest,
    RestaurantResponse,
    RestaurantUpdateRequest,
    UpdateOrderStatusRequest,
)

router = APIRouter(prefix="/merchants", tags=["merchants"])


async def _get_merchant_restaurant(db: AsyncSession, user: User) -> Restaurant:
    """Get the restaurant owned by this merchant user."""
    query = select(Restaurant).where(Restaurant.owner_id == user.id, Restaurant.is_active == True)
    result = await db.execute(query)
    restaurant = result.scalar_one_or_none()
    if not restaurant:
        raise HTTPException(status_code=404, detail="No restaurant found for this merchant. Please create a restaurant first.")
    return restaurant


@router.get("/info", response_model=MerchantInfoResponse)
async def get_merchant_info(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)

    order_count_q = select(func.count(Order.id)).where(
        Order.restaurant_name == restaurant.name
    )
    result = await db.execute(order_count_q)
    total_orders = result.scalar() or 0

    return MerchantInfoResponse(
        restaurant_id=str(restaurant.id),
        restaurant_name=restaurant.name,
        merchant_name=current_user.name or "Merchant",
        avatar_url=current_user.avatar_url,
        is_online=True,
        rating=float(restaurant.rating),
        total_orders=total_orders,
    )


# Restaurant profile management (onboarding)
@router.post("/restaurant", response_model=RestaurantResponse)
async def create_restaurant(
    request: RestaurantCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    """Create a restaurant for the merchant (onboarding)."""
    # Check if merchant already has a restaurant (without raising 404)
    existing_q = select(Restaurant).where(
        Restaurant.owner_id == current_user.id,
        Restaurant.is_active == True,
    )
    result = await db.execute(existing_q)
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Merchant already has a restaurant")

    slug = request.name.lower().replace(" ", "-").replace("&", "and")

    restaurant = Restaurant(
        name=request.name,
        slug=slug,
        description=request.description,
        address=request.address,
        latitude=request.latitude,
        longitude=request.longitude,
        logo_url=request.logo_url,
        phone=request.phone,
        email=request.email,
        opening_hours=request.opening_hours,
        restaurant_type=request.restaurant_type,
        delivery_time=request.delivery_time,
        delivery_fee=request.delivery_fee,
        minimum_order=request.minimum_order,
        owner_id=current_user.id,
        is_active=True,
    )
    db.add(restaurant)
    await db.flush()

    return RestaurantResponse(
        id=str(restaurant.id),
        name=restaurant.name,
        slug=restaurant.slug,
        description=restaurant.description,
        image_url=restaurant.image_url,
        logo_url=restaurant.logo_url,
        address=restaurant.address,
        latitude=restaurant.latitude,
        longitude=restaurant.longitude,
        rating=float(restaurant.rating),
        delivery_time=restaurant.delivery_time,
        delivery_fee=float(restaurant.delivery_fee),
        minimum_order=float(restaurant.minimum_order),
        tags=restaurant.tags or [],
        is_active=restaurant.is_active,
        phone=restaurant.phone,
        email=restaurant.email,
        opening_hours=restaurant.opening_hours,
        restaurant_type=restaurant.restaurant_type,
        owner_id=str(restaurant.owner_id) if restaurant.owner_id else None,
        created_at=restaurant.created_at,
        updated_at=restaurant.updated_at,
    )


@router.get("/restaurant", response_model=RestaurantResponse)
async def get_restaurant(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    """Get the merchant's restaurant profile."""
    restaurant = await _get_merchant_restaurant(db, current_user)

    return RestaurantResponse(
        id=str(restaurant.id),
        name=restaurant.name,
        slug=restaurant.slug,
        description=restaurant.description,
        image_url=restaurant.image_url,
        logo_url=restaurant.logo_url,
        address=restaurant.address,
        latitude=restaurant.latitude,
        longitude=restaurant.longitude,
        rating=float(restaurant.rating),
        delivery_time=restaurant.delivery_time,
        delivery_fee=float(restaurant.delivery_fee),
        minimum_order=float(restaurant.minimum_order),
        tags=restaurant.tags or [],
        is_active=restaurant.is_active,
        phone=restaurant.phone,
        email=restaurant.email,
        opening_hours=restaurant.opening_hours,
        restaurant_type=restaurant.restaurant_type,
        owner_id=str(restaurant.owner_id) if restaurant.owner_id else None,
        created_at=restaurant.created_at,
        updated_at=restaurant.updated_at,
    )


@router.patch("/restaurant", response_model=RestaurantResponse)
async def update_restaurant(
    request: RestaurantUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    """Update the merchant's restaurant profile."""
    restaurant = await _get_merchant_restaurant(db, current_user)

    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(restaurant, field, value)

    await db.flush()

    return RestaurantResponse(
        id=str(restaurant.id),
        name=restaurant.name,
        slug=restaurant.slug,
        description=restaurant.description,
        image_url=restaurant.image_url,
        logo_url=restaurant.logo_url,
        address=restaurant.address,
        latitude=restaurant.latitude,
        longitude=restaurant.longitude,
        rating=float(restaurant.rating),
        delivery_time=restaurant.delivery_time,
        delivery_fee=float(restaurant.delivery_fee),
        minimum_order=float(restaurant.minimum_order),
        tags=restaurant.tags or [],
        is_active=restaurant.is_active,
        phone=restaurant.phone,
        email=restaurant.email,
        opening_hours=restaurant.opening_hours,
        restaurant_type=restaurant.restaurant_type,
        owner_id=str(restaurant.owner_id) if restaurant.owner_id else None,
        created_at=restaurant.created_at,
        updated_at=restaurant.updated_at,
    )


@router.get("/menu", response_model=list[MenuItemResponse])
async def list_menu_items(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = (
        select(MenuItem)
        .options(selectinload(MenuItem.category))
        .where(MenuItem.restaurant_id == restaurant.id)
        .order_by(MenuItem.created_at.desc())
    )
    result = await db.execute(query)
    items = result.scalars().all()

    return [
        MenuItemResponse(
            id=str(mi.id),
            restaurant_id=str(mi.restaurant_id),
            category_id=str(mi.category_id) if mi.category_id else None,
            category_name=mi.category.name if mi.category else None,
            name=mi.name,
            description=mi.description,
            price=float(mi.price),
            image_url=mi.image_url,
            is_available=mi.is_available,
            is_vegetarian=mi.is_vegetarian,
            is_spicy=mi.is_spicy,
            rating=float(mi.rating),
            tags=mi.tags or [],
            created_at=mi.created_at,
        )
        for mi in items
    ]


@router.post("/menu", response_model=MenuItemResponse)
async def create_menu_item(
    request: MenuItemCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)

    item = MenuItem(
        restaurant_id=restaurant.id,
        category_id=UUID(request.category_id) if request.category_id else None,
        name=request.name,
        description=request.description,
        price=request.price,
        image_url=request.image_url,
        is_available=request.is_available,
        is_vegetarian=request.is_vegetarian,
        is_spicy=request.is_spicy,
        tags=request.tags or [],
    )
    db.add(item)
    await db.flush()

    # Load category relationship
    if item.category_id:
        await db.refresh(item, ["category"])

    return MenuItemResponse(
        id=str(item.id),
        restaurant_id=str(item.restaurant_id),
        category_id=str(item.category_id) if item.category_id else None,
        category_name=item.category.name if item.category else None,
        name=item.name,
        description=item.description,
        price=float(item.price),
        image_url=item.image_url,
        is_available=item.is_available,
        is_vegetarian=item.is_vegetarian,
        is_spicy=item.is_spicy,
        rating=float(item.rating),
        tags=item.tags or [],
        created_at=item.created_at,
    )


@router.patch("/menu/{item_id}", response_model=MenuItemResponse)
async def update_menu_item(
    item_id: UUID,
    request: MenuItemUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = select(MenuItem).where(
        MenuItem.id == item_id,
        MenuItem.restaurant_id == restaurant.id,
    )
    result = await db.execute(query)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")

    update_data = request.model_dump(exclude_unset=True)
    if "category_id" in update_data and update_data["category_id"]:
        update_data["category_id"] = UUID(update_data["category_id"])
    for field, value in update_data.items():
        setattr(item, field, value)

    await db.flush()

    # Load category relationship
    if item.category_id:
        await db.refresh(item, ["category"])

    return MenuItemResponse(
        id=str(item.id),
        restaurant_id=str(item.restaurant_id),
        category_id=str(item.category_id) if item.category_id else None,
        category_name=item.category.name if item.category else None,
        name=item.name,
        description=item.description,
        price=float(item.price),
        image_url=item.image_url,
        is_available=item.is_available,
        is_vegetarian=item.is_vegetarian,
        is_spicy=item.is_spicy,
        rating=float(item.rating),
        tags=item.tags or [],
        created_at=item.created_at,
    )


@router.delete("/menu/{item_id}")
async def delete_menu_item(
    item_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = select(MenuItem).where(
        MenuItem.id == item_id,
        MenuItem.restaurant_id == restaurant.id,
    )
    result = await db.execute(query)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")

    await db.delete(item)
    return {"message": "Item deleted"}


@router.patch("/menu/{item_id}/toggle-stock")
async def toggle_stock(
    item_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = select(MenuItem).where(
        MenuItem.id == item_id,
        MenuItem.restaurant_id == restaurant.id,
    )
    result = await db.execute(query)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")

    item.is_available = not item.is_available
    await db.flush()

    return {"id": str(item.id), "is_available": item.is_available}


@router.get("/orders", response_model=list[OrderResponse])
async def list_merchant_orders(
    status: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = (
        select(Order)
        .options(selectinload(Order.items))
        .where(Order.restaurant_name == restaurant.name)
        .order_by(Order.created_at.desc())
    )
    if status:
        query = query.where(Order.status == status.upper())

    result = await db.execute(query)
    orders = result.scalars().all()

    now = datetime.now(timezone.utc)
    response = []
    for o in orders:
        elapsed = int((now - o.created_at).total_seconds()) if o.created_at else 0
        order_items = [
            OrderItemResponse(name=oi.name, quantity=oi.quantity, price=float(oi.price))
            for oi in o.items
        ]
        response.append(
            OrderResponse(
                id=str(o.id),
                order_no=f"SD-{str(o.id)[:4].upper()}",
                status=o.status.lower(),
                customer_name=current_user.name or "Customer",
                items=order_items,
                total=float(o.total),
                created_at=o.created_at,
                elapsed_seconds=elapsed,
            )
        )
    return response


@router.patch("/orders/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: UUID,
    request: UpdateOrderStatusRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)
    query = (
        select(Order)
        .options(selectinload(Order.items))
        .where(Order.id == order_id, Order.restaurant_name == restaurant.name)
    )
    result = await db.execute(query)
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    status_map = {
        "confirmed": "CONFIRMED",
        "preparing": "PREPARING",
        "ready": "READY_FOR_PICKUP",
        "completed": "DELIVERED",
        "declined": "CANCELLED",
    }
    new_status = status_map.get(request.status, request.status.upper())
    order.status = new_status

    now = datetime.now(timezone.utc)
    if new_status == "CONFIRMED":
        order.confirmed_at = now
    elif new_status == "PREPARING":
        order.preparing_at = now
    elif new_status == "DELIVERED":
        order.delivered_at = now
    elif new_status == "CANCELLED":
        order.cancelled_at = now

    await db.flush()

    now_utc = datetime.now(timezone.utc)
    elapsed = int((now_utc - order.created_at).total_seconds()) if order.created_at else 0
    order_items = [
        OrderItemResponse(name=oi.name, quantity=oi.quantity, price=float(oi.price))
        for oi in order.items
    ]

    return OrderResponse(
        id=str(order.id),
        order_no=f"SD-{str(order.id)[:4].upper()}",
        status=order.status.lower(),
        customer_name=current_user.name or "Customer",
        items=order_items,
        total=float(order.total),
        created_at=order.created_at,
        elapsed_seconds=elapsed,
    )


@router.get("/dashboard", response_model=DashboardStatsResponse)
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    restaurant = await _get_merchant_restaurant(db, current_user)

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    total_q = select(func.count(Order.id)).where(
        Order.restaurant_name == restaurant.name,
        Order.created_at >= today_start,
    )
    total_result = await db.execute(total_q)
    total_orders = total_result.scalar() or 0

    earnings_q = select(func.coalesce(func.sum(Order.total), 0)).where(
        Order.restaurant_name == restaurant.name,
        Order.created_at >= today_start,
        Order.status != "CANCELLED",
    )
    earnings_result = await db.execute(earnings_q)
    total_earnings = float(earnings_result.scalar() or 0)

    active_q = select(func.count(Order.id)).where(
        Order.restaurant_name == restaurant.name,
        Order.status.in_(["CREATED", "CONFIRMED", "PREPARING", "READY_FOR_PICKUP"]),
    )
    active_result = await db.execute(active_q)
    active_orders = active_result.scalar() or 0

    completed_q = select(func.count(Order.id)).where(
        Order.restaurant_name == restaurant.name,
        Order.status == "DELIVERED",
        Order.created_at >= today_start,
    )
    completed_result = await db.execute(completed_q)
    completed_orders = completed_result.scalar() or 0

    cancelled_q = select(func.count(Order.id)).where(
        Order.restaurant_name == restaurant.name,
        Order.status == "CANCELLED",
        Order.created_at >= today_start,
    )
    cancelled_result = await db.execute(cancelled_q)
    cancelled_orders = cancelled_result.scalar() or 0

    return DashboardStatsResponse(
        total_orders_today=total_orders,
        total_earnings_today=total_earnings,
        avg_preparation_time=12.5,
        cancelled_orders=cancelled_orders,
        active_orders=active_orders,
        completed_orders=completed_orders,
    )