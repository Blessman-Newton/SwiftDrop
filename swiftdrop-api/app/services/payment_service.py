import uuid
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.order import Order
from app.models.payment import Payment
from app.payments.paystack import paystack_provider
from app.schemas.payment import (
    InitializePaymentRequest,
    InitializePaymentResponse,
    PaymentVerifyResponse,
)
from app.services.order_service import update_order_status


async def initialize_payment(
    db: AsyncSession, request: InitializePaymentRequest, base_url: str
) -> InitializePaymentResponse:
    result = await db.execute(
        select(Order).where(Order.id == UUID(request.order_id))
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.payment_status == "paid":
        raise BadRequestException("Order already paid")

    reference = f"SWD-{uuid.uuid4().hex[:12].upper()}"

    metadata = {
        "order_id": str(order.id),
        "customer_id": str(order.customer_id),
        "order_type": order.order_type,
        "cancel_action": f"{base_url}/api/v1/payments/webhook",
    }

    paystack_data = await paystack_provider.initialize_transaction(
        email=request.email,
        amount=request.amount,
        currency=request.currency,
        metadata=metadata,
    )

    payment = Payment(
        order_id=order.id,
        user_id=order.customer_id,
        reference=reference,
        amount=request.amount,
        currency=request.currency,
        status="pending",
        provider="paystack",
    )
    db.add(payment)

    order.payment_ref = reference
    await db.flush()

    return InitializePaymentResponse(
        authorization_url=paystack_data["authorization_url"],
        access_code=paystack_data["access_code"],
        reference=paystack_data["reference"],
    )


async def handle_webhook(
    db: AsyncSession, event: str, data: dict
) -> dict:
    if event == "charge.success":
        reference = data.get("reference")
        if not reference:
            return {"status": "ignored", "message": "No reference"}

        result = await db.execute(
            select(Order)
            .options(selectinload(Order.items))
            .where(Order.payment_ref == reference)
        )
        order = result.scalar_one_or_none()
        if not order:
            return {"status": "error", "message": "Order not found"}

        if order.payment_status == "paid":
            return {"status": "already_processed"}

        order.payment_status = "paid"

        payment_result = await db.execute(
            select(Payment).where(Payment.reference == reference)
        )
        payment = payment_result.scalar_one_or_none()
        if payment:
            payment.status = "success"
            payment.verified_at = datetime.now(timezone.utc)
            payment.provider_response = data

        await update_order_status(db, order.id, "CONFIRMED")
        from app.services.dispatch_service import auto_match_rider
        try:
            await auto_match_rider(db, order.id)
        except Exception:
            pass

        return {"status": "success", "order_id": str(order.id)}

    return {"status": "ignored", "event": event}


async def verify_payment(db: AsyncSession, reference: str) -> PaymentVerifyResponse:
    result = await db.execute(
        select(Order).where(Order.payment_ref == reference)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Payment not found")

    verification = await paystack_provider.verify_transaction(reference)

    pay_status = verification.get("status", "unknown")
    if pay_status == "success" and order.payment_status != "paid":
        order.payment_status = "paid"

        payment_result = await db.execute(
            select(Payment).where(Payment.reference == reference)
        )
        payment = payment_result.scalar_one_or_none()
        if payment:
            payment.status = "success"
            payment.verified_at = datetime.now(timezone.utc)
            payment.provider_response = verification

        await update_order_status(db, order.id, "CONFIRMED")
        from app.services.dispatch_service import auto_match_rider
        try:
            await auto_match_rider(db, order.id)
        except Exception:
            pass

    return PaymentVerifyResponse(
        reference=reference,
        status=verification.get("status", "unknown"),
        amount=float(verification.get("amount", 0)) / 100,
        currency=verification.get("currency", "GHS"),
        gateway_response=verification.get("gateway_response"),
    )
