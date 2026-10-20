from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest

from app.core.exceptions import BadRequestException
from app.services.order_service import _validate_transition
from app.services.payment_service import handle_webhook, verify_payment


def test_invalid_order_status_transition_is_rejected():
    with pytest.raises(BadRequestException):
        _validate_transition("DELIVERED", "CANCELLED")


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
