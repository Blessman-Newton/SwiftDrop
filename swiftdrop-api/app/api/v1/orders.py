from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.user import User
from app.schemas.order import CreateOrderRequest, OrderResponse
from app.services import order_service

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderResponse)
async def create_order(
    request: CreateOrderRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.create_order(db, current_user.id, request)


@router.get("", response_model=list[OrderResponse])
async def list_orders(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.list_orders(db, customer_id=current_user.id)


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.get_order(db, order_id)


@router.patch("/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.cancel_order(db, order_id, current_user.id)
