from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin_dep, get_current_user_dep
from app.core.database import get_db
from app.models.user import User
from app.schemas.delivery import (
    DeliveryFailureAdminUpdate,
    DeliveryFailureRequest,
    DeliveryFailureResponse,
    RefundAdminUpdate,
    RefundRequestCreate,
    RefundResponse,
)
from app.services import delivery_service

router = APIRouter(tags=["delivery"])


@router.post("/orders/{order_id}/delivery-failure", response_model=DeliveryFailureResponse)
async def report_delivery_failure(
    order_id: UUID,
    request: DeliveryFailureRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await delivery_service.report_failure(db, order_id, current_user, request)


@router.post("/orders/{order_id}/refund", response_model=RefundResponse)
async def create_refund_request(
    order_id: UUID,
    request: RefundRequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await delivery_service.request_refund(db, order_id, current_user, request)


@router.patch("/admin/delivery-failures/{failure_id}", response_model=DeliveryFailureResponse)
async def resolve_delivery_failure(
    failure_id: UUID,
    request: DeliveryFailureAdminUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_dep),
):
    return await delivery_service.resolve_failure(db, failure_id, current_user, request)


@router.patch("/admin/refunds/{refund_id}", response_model=RefundResponse)
async def update_refund(
    refund_id: UUID,
    request: RefundAdminUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_dep),
):
    return await delivery_service.update_refund(db, refund_id, current_user, request)
