from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.address import Address
from app.models.order import Order
from app.models.user import User
from app.schemas.customer import (
    AddressCreateRequest,
    AddressResponse,
    CustomerProfileUpdateRequest,
    OrderHistoryResponse,
    TopUpRequest,
    RedeemPointsRequest,
)

router = APIRouter(prefix="/customer", tags=["customer"])


@router.patch("/profile")
async def update_profile(
    request: CustomerProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    await db.flush()
    return {"message": "Profile updated"}


@router.get("/addresses", response_model=list[AddressResponse])
async def list_addresses(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = (
        select(Address)
        .where(Address.user_id == current_user.id)
        .order_by(Address.is_default.desc(), Address.created_at.desc())
    )
    result = await db.execute(query)
    addresses = result.scalars().all()
    return [
        AddressResponse(
            id=str(a.id),
            label=a.label,
            address_line=a.address_line,
            latitude=float(a.latitude) if a.latitude else None,
            longitude=float(a.longitude) if a.longitude else None,
            is_default=a.is_default,
            created_at=a.created_at,
        )
        for a in addresses
    ]


@router.post("/addresses", response_model=AddressResponse)
async def create_address(
    request: AddressCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if request.is_default:
        reset_q = select(Address).where(
            Address.user_id == current_user.id, Address.is_default == True
        )
        reset_result = await db.execute(reset_q)
        for addr in reset_result.scalars().all():
            addr.is_default = False

    address = Address(
        user_id=current_user.id,
        label=request.label,
        address_line=request.address_line,
        latitude=request.latitude,
        longitude=request.longitude,
        is_default=request.is_default,
    )
    db.add(address)
    await db.flush()

    return AddressResponse(
        id=str(address.id),
        label=address.label,
        address_line=address.address_line,
        latitude=float(address.latitude) if address.latitude else None,
        longitude=float(address.longitude) if address.longitude else None,
        is_default=address.is_default,
        created_at=address.created_at,
    )


@router.delete("/addresses/{address_id}")
async def delete_address(
    address_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = select(Address).where(
        Address.id == address_id, Address.user_id == current_user.id
    )
    result = await db.execute(query)
    address = result.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")

    await db.delete(address)
    return {"message": "Address deleted"}


@router.get("/orders/history", response_model=OrderHistoryResponse)
async def order_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = (
        select(Order)
        .where(Order.customer_id == current_user.id)
        .order_by(Order.created_at.desc())
        .limit(50)
    )
    result = await db.execute(query)
    orders = result.scalars().all()

    total_q = select(func.count(Order.id)).where(Order.customer_id == current_user.id)
    total = (await db.execute(total_q)).scalar() or 0

    return OrderHistoryResponse(
        orders=[
            {
                "id": str(o.id),
                "order_no": f"SD-{str(o.id)[:4].upper()}",
                "status": o.status,
                "restaurant_name": o.restaurant_name,
                "total": float(o.total),
                "order_type": o.order_type,
                "created_at": o.created_at.isoformat() if o.created_at else None,
            }
            for o in orders
        ],
        total_count=total,
    )


@router.post("/wallet/topup")
async def topup_wallet(
    request: TopUpRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    current_user.wallet_balance = (current_user.wallet_balance or 0.0) + request.amount
    # Give loyalty points: 10 points per 1 GHS topup
    points_earned = int(request.amount * 10)
    current_user.loyalty_points = (current_user.loyalty_points or 0) + points_earned
    
    # Calculate membership tier
    if current_user.loyalty_points >= 5000:
        current_user.membership_tier = "Gold"
    elif current_user.loyalty_points >= 2000:
        current_user.membership_tier = "Silver"
    else:
        current_user.membership_tier = "Bronze"

    await db.flush()
    return {
        "message": f"Successfully topped up GHS {request.amount:.2f}",
        "wallet_balance": float(current_user.wallet_balance),
        "loyalty_points": current_user.loyalty_points,
        "membership_tier": current_user.membership_tier,
    }


@router.post("/wallet/redeem-points")
async def redeem_points(
    request: RedeemPointsRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if (current_user.loyalty_points or 0) < request.points:
        raise HTTPException(status_code=400, detail="Insufficient loyalty points")
    
    # Redeem rate: 100 points = 1 GHS
    cash_value = request.points / 100.0
    current_user.loyalty_points -= request.points
    current_user.wallet_balance = (current_user.wallet_balance or 0.0) + cash_value
    await db.flush()
    return {
        "message": f"Redeemed {request.points} points for GHS {cash_value:.2f}",
        "wallet_balance": float(current_user.wallet_balance),
        "loyalty_points": current_user.loyalty_points,
    }

