from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select, case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_admin_dep
from app.core.database import get_db
from app.models.order import Order, OrderItem
from app.models.restaurant import Restaurant, MenuItem
from app.models.user import User, RiderProfile
from app.models.audit import AuditLog
from app.schemas.admin import (
    AdminDashboardStatsResponse,
    AdminUserResponse,
    AdminRiderResponse,
    AdminOrderResponse,
    AdminRestaurantResponse,
    AdminMenuItemResponse,
    BanUserRequest,
    PlatformAnalyticsResponse,
)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard", response_model=AdminDashboardStatsResponse)
async def get_admin_dashboard(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    total_users_q = select(func.count(User.id))
    total_users = (await db.execute(total_users_q)).scalar() or 0

    total_riders_q = select(func.count(User.id)).where(User.role == "rider")
    total_riders = (await db.execute(total_riders_q)).scalar() or 0

    total_merchants_q = select(func.count(User.id)).where(User.role == "customer")
    total_merchants = (await db.execute(total_merchants_q)).scalar() or 0

    total_orders_q = select(func.count(Order.id))
    total_orders = (await db.execute(total_orders_q)).scalar() or 0

    total_revenue_q = select(func.coalesce(func.sum(Order.total), 0)).where(
        Order.status != "CANCELLED"
    )
    total_revenue = float((await db.execute(total_revenue_q)).scalar() or 0)

    orders_today_q = select(func.count(Order.id)).where(Order.created_at >= today_start)
    orders_today = (await db.execute(orders_today_q)).scalar() or 0

    revenue_today_q = select(func.coalesce(func.sum(Order.total), 0)).where(
        Order.created_at >= today_start, Order.status != "CANCELLED"
    )
    revenue_today = float((await db.execute(revenue_today_q)).scalar() or 0)

    active_riders_q = select(func.count(RiderProfile.user_id)).where(RiderProfile.is_online == True)
    active_riders = (await db.execute(active_riders_q)).scalar() or 0

    pending_q = select(func.count(Order.id)).where(
        Order.status.in_(["CREATED", "CONFIRMED", "PREPARING", "READY_FOR_PICKUP", "PICKED_UP", "EN_ROUTE"])
    )
    pending_orders = (await db.execute(pending_q)).scalar() or 0

    completed_today_q = select(func.count(Order.id)).where(
        Order.status == "DELIVERED", Order.created_at >= today_start
    )
    completed_today = (await db.execute(completed_today_q)).scalar() or 0

    cancelled_today_q = select(func.count(Order.id)).where(
        Order.status == "CANCELLED", Order.created_at >= today_start
    )
    cancelled_today = (await db.execute(cancelled_today_q)).scalar() or 0

    new_users_today_q = select(func.count(User.id)).where(User.created_at >= today_start)
    new_users_today = (await db.execute(new_users_today_q)).scalar() or 0

    return AdminDashboardStatsResponse(
        total_users=total_users,
        total_riders=total_riders,
        total_merchants=total_merchants,
        total_orders=total_orders,
        total_revenue=total_revenue,
        orders_today=orders_today,
        revenue_today=revenue_today,
        active_riders=active_riders,
        pending_orders=pending_orders,
        completed_orders_today=completed_today,
        cancelled_orders_today=cancelled_today,
        new_users_today=new_users_today,
    )


@router.get("/users", response_model=list[AdminUserResponse])
async def list_users(
    role: str | None = None,
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(User).order_by(User.created_at.desc())
    if role:
        query = query.where(User.role == role)
    if search:
        query = query.where(
            User.name.ilike(f"%{search}%") | User.phone.ilike(f"%{search}%")
        )
    result = await db.execute(query)
    users = result.scalars().all()
    return [
        AdminUserResponse(
            id=str(u.id),
            phone=u.phone,
            name=u.name,
            email=u.email,
            role=u.role,
            avatar_url=u.avatar_url,
            is_active=u.is_active,
            is_verified=u.is_verified,
            created_at=u.created_at,
        )
        for u in users
    ]


@router.get("/users/{user_id}", response_model=AdminUserResponse)
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(User).where(User.id == user_id)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return AdminUserResponse(
        id=str(user.id),
        phone=user.phone,
        name=user.name,
        email=user.email,
        role=user.role,
        avatar_url=user.avatar_url,
        is_active=user.is_active,
        is_verified=user.is_verified,
        created_at=user.created_at,
    )


@router.patch("/users/{user_id}/ban")
async def ban_user(
    user_id: UUID,
    request: BanUserRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(User).where(User.id == user_id)
    result = await db.execute(query)
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = not user.is_active

    log = AuditLog(
        admin_id=admin.id,
        action="ban_user" if not user.is_active else "unban_user",
        entity_type="user",
        entity_id=str(user_id),
        new_value={"is_active": user.is_active, "reason": request.reason},
    )
    db.add(log)
    await db.flush()

    return {"message": f"User {'banned' if not user.is_active else 'unbanned'}", "is_active": user.is_active}


@router.get("/riders", response_model=list[AdminRiderResponse])
async def list_riders(
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = (
        select(User, RiderProfile)
        .join(RiderProfile, User.id == RiderProfile.user_id)
        .where(User.role == "rider")
        .order_by(User.created_at.desc())
    )
    if search:
        query = query.where(
            User.name.ilike(f"%{search}%") | User.phone.ilike(f"%{search}%")
        )
    result = await db.execute(query)
    rows = result.all()
    return [
        AdminRiderResponse(
            id=str(u.id),
            phone=u.phone,
            name=u.name,
            email=u.email,
            avatar_url=u.avatar_url,
            is_active=u.is_active,
            is_online=rp.is_online,
            rating=float(rp.rating),
            total_deliveries=rp.total_deliveries,
            earnings_balance=float(rp.earnings_balance),
            vehicle_type=rp.vehicle_type,
            is_banned=rp.is_banned,
            created_at=u.created_at,
        )
        for u, rp in rows
    ]


@router.patch("/riders/{rider_id}/ban")
async def ban_rider(
    rider_id: UUID,
    request: BanUserRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(RiderProfile).where(RiderProfile.user_id == rider_id)
    result = await db.execute(query)
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider not found")

    profile.is_banned = not profile.is_banned

    log = AuditLog(
        admin_id=admin.id,
        action="ban_rider" if not profile.is_banned else "unban_rider",
        entity_type="rider",
        entity_id=str(rider_id),
        new_value={"is_banned": profile.is_banned, "reason": request.reason},
    )
    db.add(log)
    await db.flush()

    return {"message": f"Rider {'banned' if profile.is_banned else 'unbanned'}", "is_banned": profile.is_banned}


@router.get("/orders", response_model=list[AdminOrderResponse])
async def list_all_orders(
    status: str | None = None,
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = (
        select(Order)
        .options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
    )
    if status:
        query = query.where(Order.status == status.upper())
    if search:
        query = query.where(Order.restaurant_name.ilike(f"%{search}%"))

    result = await db.execute(query)
    orders = result.scalars().all()

    response = []
    for o in orders:
        customer_name = "Customer"
        rider_name = None

        cust_q = select(User.name).where(User.id == o.customer_id)
        cust_result = await db.execute(cust_q)
        cust_name = cust_result.scalar()
        if cust_name:
            customer_name = cust_name

        if o.rider_id:
            rider_q = select(User.name).where(User.id == o.rider_id)
            rider_result = await db.execute(rider_q)
            rider_name = rider_result.scalar()

        response.append(
            AdminOrderResponse(
                id=str(o.id),
                order_no=f"SD-{str(o.id)[:4].upper()}",
                status=o.status,
                customer_name=customer_name,
                rider_name=rider_name,
                restaurant_name=o.restaurant_name,
                order_type=o.order_type,
                total=float(o.total),
                payment_status=o.payment_status,
                created_at=o.created_at,
            )
        )
    return response


@router.get("/restaurants", response_model=list[AdminRestaurantResponse])
async def list_all_restaurants(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(Restaurant).order_by(Restaurant.created_at.desc())
    result = await db.execute(query)
    restaurants = result.scalars().all()

    response = []
    for r in restaurants:
        menu_q = select(func.count(MenuItem.id)).where(MenuItem.restaurant_id == r.id)
        menu_count = (await db.execute(menu_q)).scalar() or 0

        order_q = select(func.count(Order.id)).where(Order.restaurant_name == r.name)
        order_count = (await db.execute(order_q)).scalar() or 0

        response.append(
            AdminRestaurantResponse(
                id=str(r.id),
                name=r.name,
                slug=r.slug,
                address=r.address,
                phone=r.phone,
                email=r.email,
                logo_url=r.logo_url,
                restaurant_type=r.restaurant_type,
                rating=float(r.rating),
                is_active=r.is_active,
                menu_item_count=menu_count,
                total_orders=order_count,
                created_at=r.created_at,
            )
        )
    return response


@router.patch("/restaurants/{restaurant_id}/toggle")
async def toggle_restaurant(
    restaurant_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    query = select(Restaurant).where(Restaurant.id == restaurant_id)
    result = await db.execute(query)
    restaurant = result.scalar_one_or_none()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    restaurant.is_active = not restaurant.is_active

    log = AuditLog(
        admin_id=admin.id,
        action="toggle_restaurant",
        entity_type="restaurant",
        entity_id=str(restaurant_id),
        new_value={"is_active": restaurant.is_active},
    )
    db.add(log)
    await db.flush()

    return {"message": f"Restaurant {'activated' if restaurant.is_active else 'deactivated'}", "is_active": restaurant.is_active}


@router.get("/restaurants/{restaurant_id}/menu", response_model=list[AdminMenuItemResponse])
async def get_restaurant_menu(
    restaurant_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    """Get menu items for a specific restaurant (admin only)."""
    query = select(Restaurant).where(Restaurant.id == restaurant_id)
    result = await db.execute(query)
    restaurant = result.scalar_one_or_none()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    menu_query = (
        select(MenuItem)
        .options(selectinload(MenuItem.category))
        .where(MenuItem.restaurant_id == restaurant_id)
        .order_by(MenuItem.created_at.desc())
    )
    result = await db.execute(menu_query)
    items = result.scalars().all()

    return [
        AdminMenuItemResponse(
            id=str(mi.id),
            name=mi.name,
            description=mi.description,
            price=float(mi.price),
            category_name=mi.category.name if mi.category else None,
            image_url=mi.image_url,
            is_available=mi.is_available,
            is_vegetarian=mi.is_vegetarian,
            is_spicy=mi.is_spicy,
            created_at=mi.created_at,
        )
        for mi in items
    ]


@router.get("/analytics", response_model=PlatformAnalyticsResponse)
async def get_analytics(
    days: int = 30,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    since = datetime.now(timezone.utc) - timedelta(days=days)

    status_q = (
        select(Order.status, func.count(Order.id))
        .where(Order.created_at >= since)
        .group_by(Order.status)
    )
    status_result = await db.execute(status_q)
    orders_by_status = {row[0]: row[1] for row in status_result.all()}

    orders_day_q = (
        select(
            func.date_trunc("day", Order.created_at).label("day"),
            func.count(Order.id),
        )
        .where(Order.created_at >= since)
        .group_by("day")
        .order_by("day")
    )
    orders_day_result = await db.execute(orders_day_q)
    orders_by_day = [{"date": str(row[0].date()), "count": row[1]} for row in orders_day_result.all()]

    revenue_day_q = (
        select(
            func.date_trunc("day", Order.created_at).label("day"),
            func.coalesce(func.sum(Order.total), 0),
        )
        .where(Order.created_at >= since, Order.status != "CANCELLED")
        .group_by("day")
        .order_by("day")
    )
    revenue_day_result = await db.execute(revenue_day_q)
    revenue_by_day = [{"date": str(row[0].date()), "amount": float(row[1])} for row in revenue_day_result.all()]

    top_rest_q = (
        select(Order.restaurant_name, func.count(Order.id).label("cnt"))
        .where(Order.created_at >= since, Order.restaurant_name.isnot(None))
        .group_by(Order.restaurant_name)
        .order_by(func.count(Order.id).desc())
        .limit(10)
    )
    top_rest_result = await db.execute(top_rest_q)
    top_restaurants = [{"name": row[0], "orders": row[1]} for row in top_rest_result.all()]

    top_rider_q = (
        select(
            User.name,
            func.count(Order.id).label("cnt"),
        )
        .join(Order, Order.rider_id == User.id)
        .where(Order.created_at >= since, Order.status == "DELIVERED")
        .group_by(User.name)
        .order_by(func.count(Order.id).desc())
        .limit(10)
    )
    top_rider_result = await db.execute(top_rider_q)
    top_riders = [{"name": row[0], "deliveries": row[1]} for row in top_rider_result.all()]

    user_day_q = (
        select(
            func.date_trunc("day", User.created_at).label("day"),
            func.count(User.id),
        )
        .where(User.created_at >= since)
        .group_by("day")
        .order_by("day")
    )
    user_day_result = await db.execute(user_day_q)
    user_growth = [{"date": str(row[0].date()), "count": row[1]} for row in user_day_result.all()]

    return PlatformAnalyticsResponse(
        orders_by_status=orders_by_status,
        orders_by_day=orders_by_day,
        revenue_by_day=revenue_by_day,
        top_restaurants=top_restaurants,
        top_riders=top_riders,
        user_growth=user_growth,
    )
