from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest

from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException
from app.services.order_service import _actor_can_transition, _validate_transition
from app.services.payment_service import handle_webhook, verify_payment
from app.services.pricing_service import price_gas, price_parcel
from app.schemas.delivery import DeliveryFailureAdminUpdate, RefundAdminUpdate
from app.services.delivery_service import resolve_failure
from app.services.delivery_service import update_refund


def test_invalid_order_status_transition_is_rejected():
    with pytest.raises(BadRequestException):
        _validate_transition("DELIVERED", "CANCELLED")


def test_customer_can_only_cancel_owned_orders():
    customer_id = uuid4()
    order = SimpleNamespace(customer_id=customer_id, rider_id=None)
    customer = SimpleNamespace(id=customer_id, role="customer")
    _actor_can_transition(order, "CANCELLED", customer)

    with pytest.raises(ForbiddenException):
        _actor_can_transition(order, "CONFIRMED", customer)
    with pytest.raises(ForbiddenException):
        _actor_can_transition(order, "CANCELLED", SimpleNamespace(id=uuid4(), role="customer"))


def test_rider_can_only_update_assigned_delivery_states():
    rider_id = uuid4()
    order = SimpleNamespace(customer_id=uuid4(), rider_id=rider_id)
    rider = SimpleNamespace(id=rider_id, role="rider")
    _actor_can_transition(order, "EN_ROUTE", rider)

    with pytest.raises(ForbiddenException):
        _actor_can_transition(order, "PREPARING", rider)
    with pytest.raises(ForbiddenException):
        _actor_can_transition(order, "DELIVERED", SimpleNamespace(id=uuid4(), role="rider"))


@pytest.mark.asyncio
async def test_verification_rejects_superseded_payment_reference():
    customer_id = uuid4()
    order = SimpleNamespace(
        customer_id=customer_id,
        payment_ref="SWD-ACTIVE",
        payment_status="pending",
    )
    result = SimpleNamespace(scalar_one_or_none=lambda: order)
    db = AsyncMock()
    db.execute.return_value = result

    with patch(
        "app.services.payment_service.paystack_provider.verify_transaction",
        new_callable=AsyncMock,
    ) as verify_transaction:
        with pytest.raises(BadRequestException):
            await verify_payment(db, "SWD-OLD", customer_id)

    verify_transaction.assert_not_awaited()


@pytest.mark.asyncio
async def test_webhook_cannot_settle_superseded_payment_reference():
    order = SimpleNamespace(
        id=uuid4(),
        payment_ref="SWD-ACTIVE",
        payment_status="pending",
    )
    result = SimpleNamespace(scalar_one_or_none=lambda: order)
    db = AsyncMock()
    db.execute.return_value = result

    response = await handle_webhook(
        db,
        "charge.success",
        {"reference": "SWD-OLD", "amount": 1000, "currency": "GHS"},
    )

    assert response == {
        "status": "ignored",
        "message": "Payment reference is no longer active",
    }
    db.commit.assert_not_awaited()


@pytest.mark.asyncio
async def test_gas_pricing_ignores_client_price_and_rejects_invalid_options():
    setting = SimpleNamespace(value={"6 kg": 80.0})
    result = SimpleNamespace(scalar_one_or_none=lambda: setting)
    db = AsyncMock()
    db.execute.return_value = result

    subtotal, fee = await price_gas(
        db,
        {"cylinder_size": "6 kg", "quantity": 1, "delivery_speed": "Standard",
         "client_total": 0},
    )

    assert (subtotal, fee) == (80.0, 15.0)
    with pytest.raises(BadRequestException):
        await price_gas(
            db,
            {"cylinder_size": "6 kg", "quantity": 2, "delivery_speed": "Standard"},
        )


@pytest.mark.asyncio
async def test_parcel_pricing_rejects_client_distance_and_calculates_fee():
    with pytest.raises(BadRequestException):
        await price_parcel(
            {"weight_kg": 2, "distance_km": 1, "delivery_speed": "Standard"},
            7.34, -2.33, 7.35, -2.32,
        )

    subtotal, fee = await price_parcel(
        {"weight_kg": 2, "delivery_speed": "Express"},
        7.34, -2.33, 7.35, -2.32,
    )
    assert subtotal == 12.0
    assert fee > 21.0


@pytest.mark.asyncio
async def test_refund_cannot_be_completed_without_provider_confirmation():
    refund = SimpleNamespace(
        status="processing",
        provider_reference="REF-1",
        provider_confirmed=False,
        failure_reason=None,
        reviewed_by=None,
        updated_at=None,
    )
    db = AsyncMock()
    db.scalar.return_value = refund
    admin = SimpleNamespace(id=uuid4(), role="admin")

    with pytest.raises(BadRequestException):
        await update_refund(
            db,
            uuid4(),
            admin,
            RefundAdminUpdate(status="completed", provider_confirmed=False),
        )


@pytest.mark.asyncio
async def test_refund_processing_requires_provider_reference():
    refund = SimpleNamespace(
        status="approved",
        provider_reference=None,
        provider_confirmed=False,
        failure_reason=None,
        reviewed_by=None,
        updated_at=None,
    )
    db = AsyncMock()
    db.scalar.return_value = refund
    admin = SimpleNamespace(id=uuid4(), role="admin")

    with pytest.raises(BadRequestException):
        await update_refund(
            db,
            uuid4(),
            admin,
            RefundAdminUpdate(status="processing"),
        )


@pytest.mark.asyncio
async def test_refund_transition_map_rejects_skipping_review():
    refund = SimpleNamespace(
        status="requested",
        provider_reference=None,
        provider_confirmed=False,
        failure_reason=None,
        reviewed_by=None,
        updated_at=None,
    )
    db = AsyncMock()
    db.scalar.return_value = refund
    admin = SimpleNamespace(id=uuid4(), role="admin")

    with pytest.raises(ConflictException):
        await update_refund(
            db,
            uuid4(),
            admin,
            RefundAdminUpdate(status="completed", provider_confirmed=True),
        )


@pytest.mark.asyncio
async def test_delivery_failure_resolution_requires_final_outcome():
    failure = SimpleNamespace(status="reported", final_outcome=None, resolution=None)
    db = AsyncMock()
    db.scalar.return_value = failure
    admin = SimpleNamespace(id=uuid4(), role="admin")

    with pytest.raises(BadRequestException):
        await resolve_failure(
            db,
            uuid4(),
            admin,
            DeliveryFailureAdminUpdate(status="resolved"),
        )
