import logging
import uuid
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.models.order import Order
from app.models.payment import Payment
from app.payments.paystack import paystack_provider
from app.schemas.payment import (
    InitializePaymentRequest,
    InitializePaymentResponse,
    PaymentVerifyResponse,
)
from app.services.order_service import update_order_status

logger = logging.getLogger(__name__)


async def initialize_payment(
    db: AsyncSession, request: InitializePaymentRequest, base_url: str, customer_id: UUID
) -> InitializePaymentResponse:
    result = await db.execute(
        select(Order).where(Order.id == UUID(request.order_id))
    )
    order = result.scalar_one_or_none()
    if not order:
        raise NotFoundException("Order not found")
    if order.customer_id != customer_id:
        raise ForbiddenException("Not your order")
    if order.payment_status == "paid":
        raise BadRequestException("Order already paid")
    if round(request.amount, 2) != round(float(order.total), 2):
        raise BadRequestException("Payment amount does not match the order total")
    if request.currency != "GHS":
        raise BadRequestException("Only GHS payments are supported")

    reference = f"SWD-{uuid.uuid4().hex[:12].upper()}"

    metadata = {
        "order_id": str(order.id),
        "customer_id": str(order.customer_id),
        "order_type": order.order_type,
        "cancel_action": f"{base_url}/api/v1/payments/webhook",
    }

    paystack_data = await paystack_provider.initialize_transaction(
        email=request.email,
        amount=float(order.total),
        currency=request.currency,
        metadata=metadata,
        reference=reference,
    )

    pending_result = await db.execute(
        select(Payment).where(
            Payment.order_id == order.id,
            Payment.status == "pending",
        )
    )
    for previous_payment in pending_result.scalars().all():
        previous_payment.status = "failed"
        previous_payment.provider_response = {
            "reason": "superseded_by_retry",
            "replacement_reference": reference,
        }

    payment = Payment(
        order_id=order.id,
        user_id=order.customer_id,
        reference=reference,
        amount=order.total,
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
            payment_q = select(Payment).where(Payment.reference == reference)
            payment_res = await db.execute(payment_q)
            payment = payment_res.scalar_one_or_none()
            if payment:
                order_q = select(Order).options(selectinload(Order.items)).where(Order.id == payment.order_id)
                order_res = await db.execute(order_q)
                order = order_res.scalar_one_or_none()

        if not order:
            return {"status": "error", "message": "Order not found"}

        if order.payment_status == "paid":
            return {"status": "already_processed"}
        if order.payment_ref != reference:
            return {"status": "ignored", "message": "Payment reference is no longer active"}

        provider_amount = round(float(data.get("amount", 0)) / 100, 2)
        provider_currency = data.get("currency", "GHS")
        if provider_currency != "GHS" or provider_amount != round(float(order.total), 2):
            payment_result = await db.execute(
                select(Payment).where(Payment.reference == reference)
            )
            payment = payment_result.scalar_one_or_none()
            if payment:
                payment.status = "failed"
                payment.provider_response = data
            return {
                "status": "error",
                "message": "Payment amount or currency does not match the order",
            }

        order.payment_status = "paid"

        payment_result = await db.execute(
            select(Payment).where(Payment.reference == reference)
        )
        payment = payment_result.scalar_one_or_none()
        if payment:
            payment.status = "success"
            payment.verified_at = datetime.now(timezone.utc)
            payment.provider_response = data

        await finalize_order_payment(db, order)

        return {"status": "success", "order_id": str(order.id)}

    return {"status": "ignored", "event": event}


async def verify_payment(
    db: AsyncSession, reference: str, customer_id: UUID
) -> PaymentVerifyResponse:
    result = await db.execute(
        select(Order).where(Order.payment_ref == reference)
    )
    order = result.scalar_one_or_none()
    if not order:
        payment_q = select(Payment).where(Payment.reference == reference)
        payment_res = await db.execute(payment_q)
        payment = payment_res.scalar_one_or_none()
        if payment:
            order_q = select(Order).where(Order.id == payment.order_id)
            order_res = await db.execute(order_q)
            order = order_res.scalar_one_or_none()

    if not order:
        raise NotFoundException("Payment not found")
    if order.customer_id != customer_id:
        raise ForbiddenException("Not your payment")
    if order.payment_ref != reference:
        raise BadRequestException("Payment reference is no longer active")

    try:
        verification = await paystack_provider.verify_transaction(reference)
        pay_status = verification.get("status", "unknown")
    except Exception as e:
        logger.error(f"Paystack verification exception: {e}")
        pay_status = "failed"
        verification = {
            "status": "failed",
            "amount": 0,
            "currency": "GHS",
            "gateway_response": f"Verification error: {str(e)}"
        }

    provider_amount = round(float(verification.get("amount", 0)) / 100, 2)
    provider_currency = verification.get("currency", "GHS")
    if pay_status == "success" and (
        provider_currency != "GHS"
        or provider_amount != round(float(order.total), 2)
    ):
        raise BadRequestException(
            "Verified payment amount or currency does not match the order"
        )

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

        await finalize_order_payment(db, order)

    return PaymentVerifyResponse(
        reference=reference,
        status=pay_status,
        amount=float(verification.get("amount", 0)) / 100,
        currency=provider_currency,
        gateway_response=verification.get("gateway_response"),
    )


async def finalize_order_payment(db: AsyncSession, order: Order) -> None:
    from app.models.notification import Notification

    # Check if this is a Gas Refill order
    is_gas_refill = order.restaurant_name == "LPG Gas Depot (Tarkwa)"
    delivery_mode = order.metadata_.get("delivery_mode") if order.metadata_ else None

    if is_gas_refill and delivery_mode == "Scheduled":
        # Keep status as CREATED, just notify customer
        scheduled_date = order.metadata_.get("scheduled_date", "") if order.metadata_ else ""
        scheduled_time = order.metadata_.get("scheduled_time", "") if order.metadata_ else ""
        notification = Notification(
            user_id=order.customer_id,
            title="Gas Refill Scheduled",
            body=f"Gas refill scheduled successfully! Your refill is scheduled for {scheduled_date} at {scheduled_time} and will be delivered to {order.delivery_address}.",
            type="order",
            metadata_={
                "order_id": str(order.id),
                "status": "scheduled",
            },
        )
        db.add(notification)
    else:
        # Standard or Instant Gas Refill
        await update_order_status(db, order.id, "CONFIRMED")
        if is_gas_refill:
            notification = Notification(
                user_id=order.customer_id,
                title="Booking Confirmed",
                body=f"Gas refill booking confirmed! Your refill request has been placed for instant delivery to {order.delivery_address}. We are now finding a rider for you.",
                type="order",
                metadata_={
                    "order_id": str(order.id),
                    "status": "booking_confirmed",
                },
            )
            db.add(notification)

        if order.order_type != "food":
            from app.services.dispatch_service import auto_match_rider
            try:
                await auto_match_rider(db, order.id)
            except Exception:
                pass
