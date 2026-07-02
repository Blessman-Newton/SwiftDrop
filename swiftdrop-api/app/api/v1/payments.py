from fastapi import APIRouter, Depends, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.config import get_settings
from app.core.database import get_db
from app.models.user import User
from app.payments.paystack import paystack_provider
from app.schemas.payment import (
    InitializePaymentRequest,
    InitializePaymentResponse,
    PaymentVerifyResponse,
)
from app.services import payment_service

router = APIRouter(prefix="/payments", tags=["payments"])
settings = get_settings()


@router.post("/initialize", response_model=InitializePaymentResponse)
async def initialize_payment(
    request: InitializePaymentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await payment_service.initialize_payment(db, request, settings.APP_BASE_URL)


@router.post("/webhook")
async def payment_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    body = await request.body()
    payload = await request.json()

    event = payload.get("event", "")
    data = payload.get("data", {})

    return await payment_service.handle_webhook(db, event, data)


@router.get("/{reference}/verify", response_model=PaymentVerifyResponse)
async def verify_payment(
    reference: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await payment_service.verify_payment(db, reference)
