import hashlib
import hmac

from fastapi import APIRouter, Depends, Header, HTTPException, Request
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
    signature = request.headers.get("X-Paystack-Signature", "")

    expected = hmac.new(
        settings.PAYSTACK_SECRET_KEY.encode("utf-8"),
        body,
        hashlib.sha512,
    ).hexdigest()

    if not hmac.compare_digest(signature, expected):
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

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


@router.post("/mock-callback/{order_id}")
async def mock_pay_for_me_callback(
    order_id: str,
    db: AsyncSession = Depends(get_db),
):
    # Guard against mock callback abuse in production
    if settings.APP_ENV == "production":
        raise HTTPException(status_code=403, detail="Mock callbacks disabled in production")

    from app.models.order import Order
    from app.models.payment import Payment
    from app.services.order_service import update_order_status
    from app.services.dispatch_service import auto_match_rider
    from datetime import datetime, timezone
    from sqlalchemy import select

    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.payment_status = "paid"
    await update_order_status(db, order.id, "CONFIRMED")

    # update payment record if exists
    pay_res = await db.execute(select(Payment).where(Payment.order_id == order.id))
    payment = pay_res.scalar_one_or_none()
    if payment:
        payment.status = "success"
        payment.verified_at = datetime.now(timezone.utc)
    else:
        new_payment = Payment(
            order_id=order.id,
            amount=order.total,
            currency="GHS",
            status="success",
            reference=order.payment_ref or f"ref_mock_{order_id[:8]}",
            method="momo",
            provider="mtn"
        )
        db.add(new_payment)

    await db.commit()

    try:
        await auto_match_rider(db, order.id)
    except Exception:
        pass

    return {"status": "success", "message": "Payment marked as completed successfully"}
