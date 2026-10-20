from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin_dep, get_current_user_dep
from app.core.database import get_db
from app.models.order import Order
from app.models.support import SupportTicket
from app.models.user import User
from app.schemas.support import (
    CreateSupportTicketRequest,
    SupportTicketResponse,
    UpdateSupportTicketRequest,
)

router = APIRouter(prefix="/support", tags=["support"])


def _response(ticket: SupportTicket) -> SupportTicketResponse:
    return SupportTicketResponse(
        id=ticket.id,
        order_id=ticket.order_id,
        subject=ticket.subject,
        description=ticket.description,
        status=ticket.status,
        priority=ticket.priority,
        messages=ticket.messages or [],
        created_at=ticket.created_at,
        updated_at=ticket.updated_at,
    )


@router.post("/tickets", response_model=SupportTicketResponse)
async def create_ticket(
    request: CreateSupportTicketRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if request.priority not in {"low", "medium", "high", "urgent"}:
        raise HTTPException(status_code=400, detail="Invalid ticket priority")
    if request.order_id:
        order = (await db.execute(
            select(Order).where(Order.id == request.order_id, Order.customer_id == current_user.id)
        )).scalar_one_or_none()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
    ticket = SupportTicket(
        user_id=current_user.id,
        order_id=request.order_id,
        subject=request.subject.strip(),
        description=request.description.strip(),
        priority=request.priority,
        messages=[],
    )
    db.add(ticket)
    await db.flush()
    return _response(ticket)


@router.get("/tickets", response_model=list[SupportTicketResponse])
async def list_tickets(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    result = await db.execute(
        select(SupportTicket)
        .where(SupportTicket.user_id == current_user.id)
        .order_by(SupportTicket.created_at.desc())
    )
    return [_response(ticket) for ticket in result.scalars().all()]


@router.get("/admin/tickets", response_model=list[SupportTicketResponse])
async def list_admin_tickets(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    result = await db.execute(select(SupportTicket).order_by(SupportTicket.created_at.desc()))
    return [_response(ticket) for ticket in result.scalars().all()]


@router.patch("/admin/tickets/{ticket_id}", response_model=SupportTicketResponse)
async def update_ticket(
    ticket_id: UUID,
    request: UpdateSupportTicketRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin_dep),
):
    ticket = (await db.execute(
        select(SupportTicket).where(SupportTicket.id == ticket_id).with_for_update()
    )).scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Support ticket not found")
    if request.status is not None and request.status not in {"open", "in_progress", "resolved", "closed"}:
        raise HTTPException(status_code=400, detail="Invalid ticket status")
    if request.priority is not None and request.priority not in {"low", "medium", "high", "urgent"}:
        raise HTTPException(status_code=400, detail="Invalid ticket priority")
    if request.status is not None:
        ticket.status = request.status
    if request.priority is not None:
        ticket.priority = request.priority
    if request.message:
        messages = list(ticket.messages or [])
        messages.append({
            "author_id": str(admin.id),
            "author_role": "admin",
            "message": request.message.strip(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        ticket.messages = messages
    await db.flush()
    return _response(ticket)
