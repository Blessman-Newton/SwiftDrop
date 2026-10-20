from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.models.delivery import DeliveryFailure, RefundRequest
from app.models.order import Order
from app.models.user import User
from app.schemas.delivery import (
    DeliveryFailureAdminUpdate,
    DeliveryFailureRequest,
    RefundAdminUpdate,
    RefundRequestCreate,
)
from app.services.order_service import transition_order


async def report_failure(
    db: AsyncSession, order_id: UUID, actor: User, request: DeliveryFailureRequest
) -> DeliveryFailure:
    result = await db.execute(select(Order).where(Order.id == order_id).with_for_update())
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if actor.role not in {"admin", "rider"} or (
        actor.role == "rider" and order.rider_id != actor.id
    ):
        raise ForbiddenException("Only the assigned rider or an admin can report delivery failure")
    existing = await db.scalar(select(DeliveryFailure).where(DeliveryFailure.order_id == order_id))
    if existing:
        return existing
    failure = DeliveryFailure(
        order_id=order_id,
        reported_by=actor.id,
        reason=request.reason,
        responsible_party=request.responsible_party,
        resolution=request.resolution,
    )
    db.add(failure)
    await db.flush()
    await transition_order(
        db, order_id, "DELIVERY_FAILED", actor=actor, reason=request.reason
    )
    return failure


async def request_refund(
    db: AsyncSession, order_id: UUID, actor: User, request: RefundRequestCreate
) -> RefundRequest:
    order = await db.scalar(select(Order).where(Order.id == order_id).with_for_update())
    if not order:
        raise NotFoundException("Order not found")
    if actor.role != "customer" or order.customer_id != actor.id:
        raise ForbiddenException("Only the order customer can request a refund")
    if order.status not in {"DELIVERED", "CANCELLED", "DELIVERY_FAILED"}:
        raise BadRequestException("Refunds are only available after fulfilment outcome")
    existing = await db.scalar(select(RefundRequest).where(RefundRequest.order_id == order_id))
    if existing:
        raise ConflictException("A refund request already exists for this order")
    refund = RefundRequest(
        order_id=order_id, requested_by=actor.id, amount=float(order.total), reason=request.reason
    )
    db.add(refund)
    await db.flush()
    return refund


async def resolve_failure(
    db: AsyncSession,
    failure_id: UUID,
    actor: User,
    request: DeliveryFailureAdminUpdate,
) -> DeliveryFailure:
    failure = await db.scalar(
        select(DeliveryFailure).where(DeliveryFailure.id == failure_id).with_for_update()
    )
    if not failure:
        raise NotFoundException("Delivery failure not found")
    if actor.role != "admin":
        raise ForbiddenException("Admin access required")
    if failure.status == "resolved":
        if request.status == "resolved" and request.final_outcome == failure.final_outcome:
            return failure
        raise ConflictException("Delivery failure is already resolved")
    if request.status == "resolved" and not request.final_outcome:
        raise BadRequestException("Resolved delivery failures require a final outcome")
    failure.status = request.status
    if request.resolution is not None:
        failure.resolution = request.resolution
    if request.final_outcome is not None:
        failure.final_outcome = request.final_outcome
    failure.resolved_by = actor.id
    if request.status == "resolved":
        failure.resolved_at = datetime.now(timezone.utc)
    await db.flush()
    return failure


async def update_refund(
    db: AsyncSession, refund_id: UUID, actor: User, request: RefundAdminUpdate
) -> RefundRequest:
    refund = await db.scalar(select(RefundRequest).where(RefundRequest.id == refund_id).with_for_update())
    if not refund:
        raise NotFoundException("Refund request not found")
    if actor.role != "admin":
        raise ForbiddenException("Admin access required")
    transitions = {
        "requested": {"under_review", "rejected"},
        "under_review": {"approved", "rejected"},
        "approved": {"processing", "rejected"},
        "processing": {"completed", "failed"},
        "failed": {"processing"},
    }
    if request.status not in transitions.get(refund.status, set()):
        raise ConflictException(
            f"Refund cannot transition from {refund.status} to {request.status}"
        )
    if request.status == "completed" and not request.provider_confirmed:
        raise BadRequestException("Completed refunds require provider confirmation")
    if request.status == "processing" and not request.provider_reference:
        raise BadRequestException("Processing refunds require a provider reference")
    refund.status = request.status
    refund.provider_reference = request.provider_reference or refund.provider_reference
    if request.provider_confirmed is not None:
        refund.provider_confirmed = request.provider_confirmed
    refund.failure_reason = request.failure_reason
    refund.reviewed_by = actor.id
    refund.updated_at = datetime.now(timezone.utc)
    await db.flush()
    return refund
