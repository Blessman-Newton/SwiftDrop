from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_rider_dep, get_current_user_dep
from app.core.database import get_db
from app.models.order import Order, OrderItem
from app.models.payout import Payout
from app.models.user import User, RiderProfile
from app.models.notification import Notification
from app.schemas.rider_profile import (
    RiderActiveDeliveryResponse,
    RiderDashboardResponse,
    RiderEarningsResponse,
    RiderStatsResponse,
    RiderTransactionResponse,
    UpdateDeliveryStatusRequest,
    RiderOnlineRequest,
)

router = APIRouter(prefix="/rider-profile", tags=["rider-profile"])


@router.get("/dashboard", response_model=RiderDashboardResponse)
async def get_rider_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
    profile = (await db.execute(profile_q)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider profile not found")

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    today_earnings_q = select(func.coalesce(func.sum(Order.delivery_fee), 0)).where(
        Order.rider_id == current_user.id,
        Order.status == "DELIVERED",
        Order.delivered_at >= today_start,
    )
    today_earnings = float((await db.execute(today_earnings_q)).scalar() or 0)

    today_trips_q = select(func.count(Order.id)).where(
        Order.rider_id == current_user.id,
        Order.status == "DELIVERED",
        Order.delivered_at >= today_start,
    )
    today_trips = (await db.execute(today_trips_q)).scalar() or 0

    pending_q = select(func.count(Order.id)).where(
        Order.rider_id == current_user.id,
        Order.status.in_(["PICKED_UP", "EN_ROUTE"]),
    )
    pending_count = (await db.execute(pending_q)).scalar() or 0

    return RiderDashboardResponse(
        today_earnings=today_earnings,
        today_trips=today_trips,
        today_distance=0.0,
        today_active_time=0,
        rating=float(profile.rating),
        total_deliveries=profile.total_deliveries,
        is_online=profile.is_online,
        daily_goal=200.0,
        goal_progress=min(today_earnings / 200.0 * 100, 100),
        pending_order_count=pending_count,
        completed_today=today_trips,
    )


@router.post("/online")
async def go_online(
    request: RiderOnlineRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
    profile = (await db.execute(profile_q)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider profile not found")

    profile.is_online = True
    await db.flush()
    return {"message": "Rider is now online", "is_online": True}


@router.post("/offline")
async def go_offline(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
    profile = (await db.execute(profile_q)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider profile not found")

    profile.is_online = False
    await db.flush()
    return {"message": "Rider is now offline", "is_online": False}


@router.get("/active-delivery", response_model=RiderActiveDeliveryResponse | None)
async def get_active_delivery(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    query = (
        select(Order)
        .options(selectinload(Order.items))
        .where(
            Order.rider_id == current_user.id,
            Order.status.in_(["READY_FOR_PICKUP", "PICKED_UP", "EN_ROUTE"]),
        )
        .order_by(Order.created_at.desc())
        .limit(1)
    )
    result = await db.execute(query)
    order = result.scalar_one_or_none()
    if not order:
        return None

    items = [{"name": i.name, "quantity": i.quantity, "price": float(i.price)} for i in order.items]

    cust_q = select(User.name).where(User.id == order.customer_id)
    cust_name = (await db.execute(cust_q)).scalar() or "Customer"

    return RiderActiveDeliveryResponse(
        order_id=str(order.id),
        order_no=f"SD-{str(order.id)[:4].upper()}",
        status=order.status,
        restaurant_name=order.restaurant_name,
        pickup_address=order.pickup_address,
        delivery_address=order.delivery_address,
        items=items,
        total=float(order.total),
        customer_name=cust_name,
        delivery_notes=order.metadata_.get("delivery_notes") if order.metadata_ else None,
        created_at=order.created_at,
    )


@router.put("/active-delivery/status")
async def update_delivery_status(
    request: UpdateDeliveryStatusRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    query = (
        select(Order)
        .where(
            Order.rider_id == current_user.id,
            Order.status.in_(["READY_FOR_PICKUP", "PICKED_UP", "EN_ROUTE"]),
        )
        .order_by(Order.created_at.desc())
        .limit(1)
    )
    result = await db.execute(query)
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="No active delivery found")

    status_map = {
        "en_route": "EN_ROUTE",
        "arrived": "EN_ROUTE",
        "picked_up": "PICKED_UP",
        "delivered": "DELIVERED",
    }
    new_status = status_map.get(request.status, request.status.upper())
    order.status = new_status

    now = datetime.now(timezone.utc)
    if new_status == "DELIVERED":
        order.delivered_at = now
    elif new_status == "PICKED_UP":
        order.picked_up_at = now

    rider_result = await db.execute(select(User).where(User.id == current_user.id))
    rider = rider_result.scalar_one_or_none()
    rider_name = rider.name if rider else "Your rider"

    if new_status == "PICKED_UP":
        customer_notification = Notification(
            user_id=order.customer_id,
            title="Your Order is On the Way",
            body=f"Your order has been handed over to {rider_name} and is now on its way to your delivery location.",
            type="order",
            metadata_={
                "order_id": str(order.id),
                "rider_name": rider_name,
                "status": "on_the_way",
            },
        )
        db.add(customer_notification)

    elif new_status == "DELIVERED":
        customer_notification = Notification(
            user_id=order.customer_id,
            title="Order Delivered",
            body="Your order has been delivered successfully. Thank you for ordering with us!",
            type="order",
            metadata_={
                "order_id": str(order.id),
                "status": "delivered",
            },
        )
        db.add(customer_notification)

    await db.flush()

    if new_status == "DELIVERED":
        profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
        profile = (await db.execute(profile_q)).scalar_one_or_none()
        if profile:
            profile.total_deliveries += 1
            profile.current_order_id = None
            await db.flush()

    return {"message": f"Delivery status updated to {new_status}", "status": new_status}


@router.get("/earnings", response_model=RiderEarningsResponse)
async def get_earnings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
    profile = (await db.execute(profile_q)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider profile not found")

    total_earned_q = select(func.coalesce(func.sum(Order.delivery_fee), 0)).where(
        Order.rider_id == current_user.id,
        Order.status == "DELIVERED",
    )
    total_earned = float((await db.execute(total_earned_q)).scalar() or 0)

    withdrawn_q = select(func.coalesce(func.sum(Payout.amount), 0)).where(
        Payout.rider_id == current_user.id,
        Payout.status == "completed",
    )
    withdrawn = float((await db.execute(withdrawn_q)).scalar() or 0)

    pending_q = select(func.coalesce(func.sum(Payout.amount), 0)).where(
        Payout.rider_id == current_user.id,
        Payout.status.in_(["pending", "processing"]),
    )
    pending = float((await db.execute(pending_q)).scalar() or 0)

    trips_q = select(func.count(Order.id)).where(
        Order.rider_id == current_user.id, Order.status == "DELIVERED"
    )
    total_trips = (await db.execute(trips_q)).scalar() or 0

    weekly = []
    for i in range(6, -1, -1):
        day = datetime.now(timezone.utc) - timedelta(days=i)
        day_start = day.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start + timedelta(days=1)
        day_earnings_q = select(func.coalesce(func.sum(Order.delivery_fee), 0)).where(
            Order.rider_id == current_user.id,
            Order.status == "DELIVERED",
            Order.delivered_at >= day_start,
            Order.delivered_at < day_end,
        )
        day_earnings = float((await db.execute(day_earnings_q)).scalar() or 0)
        weekly.append({
            "day": day.strftime("%a"),
            "date": day_start.date().isoformat(),
            "amount": day_earnings,
        })

    avg_daily = total_earned / 7 if total_earned > 0 else 0

    return RiderEarningsResponse(
        available_balance=float(profile.earnings_balance),
        weekly_earnings=weekly,
        total_base_fare=total_earned * 0.7,
        total_tips=total_earned * 0.15,
        total_bonuses=total_earned * 0.1,
        total_fees=total_earned * 0.05,
        average_daily=avg_daily,
        total_trips=total_trips,
    )


@router.get("/transactions", response_model=list[RiderTransactionResponse])
async def get_transactions(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    query = (
        select(Order)
        .where(
            Order.rider_id == current_user.id,
            Order.status == "DELIVERED",
        )
        .order_by(Order.delivered_at.desc())
        .limit(20)
    )
    result = await db.execute(query)
    orders = result.scalars().all()

    return [
        RiderTransactionResponse(
            id=str(o.id),
            title=f"Order SD-{str(o.id)[:4].upper()}",
            amount=float(o.delivery_fee),
            is_bonus=False,
            created_at=o.delivered_at or o.created_at,
        )
        for o in orders
    ]


@router.get("/stats", response_model=RiderStatsResponse)
async def get_rider_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    profile_q = select(RiderProfile).where(RiderProfile.user_id == current_user.id)
    profile = (await db.execute(profile_q)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Rider profile not found")

    return RiderStatsResponse(
        rating=float(profile.rating),
        acceptance_rate=95.0,
        cancellation_rate=2.0,
        total_deliveries=profile.total_deliveries,
        on_time_rate=97.0,
    )
