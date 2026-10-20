from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin_dep, get_current_rider_dep
from app.core.database import get_db
from app.models.user import User
from app.services import dispatch_service

router = APIRouter(prefix="/dispatch", tags=["dispatch"])


@router.post("/{order_id}/accept")
async def accept_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    return await dispatch_service.accept_order(db, order_id, current_user.id)


@router.post("/{order_id}/reject")
async def reject_order(
    order_id: UUID,
    reason: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_rider_dep),
):
    return await dispatch_service.reject_order(db, order_id, current_user.id, reason)


@router.post("/{order_id}/auto-match")
async def auto_match(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_dep),
):
    return await dispatch_service.auto_match_rider(db, order_id)


@router.post("/{order_id}/reassign")
async def reassign(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_dep),
):
    return await dispatch_service.reassign_order(db, order_id)


@router.post("/operations/expire-offers")
async def expire_offers(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_dep),
):
    return await dispatch_service.expire_dispatch_offers(db, limit=limit)
