from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class DeliveryFailureRequest(BaseModel):
    reason: str = Field(min_length=2, max_length=100)
    responsible_party: str | None = Field(default=None, max_length=50)
    resolution: str | None = Field(default=None, max_length=2000)


class DeliveryFailureResponse(DeliveryFailureRequest):
    id: UUID
    order_id: UUID
    status: str
    final_outcome: str | None
    created_at: datetime


class DeliveryFailureAdminUpdate(BaseModel):
    status: str = Field(pattern=r"^(under_review|resolved)$")
    final_outcome: str | None = Field(default=None, max_length=50)
    resolution: str | None = Field(default=None, max_length=2000)


class RefundRequestCreate(BaseModel):
    reason: str = Field(min_length=2, max_length=2000)


class RefundResponse(BaseModel):
    id: UUID
    order_id: UUID
    amount: float
    reason: str
    status: str
    provider_reference: str | None
    provider_confirmed: bool
    failure_reason: str | None
    created_at: datetime
    updated_at: datetime


class RefundAdminUpdate(BaseModel):
    status: str = Field(
        pattern=r"^(under_review|approved|rejected|processing|completed|failed)$"
    )
    provider_reference: str | None = Field(default=None, max_length=255)
    provider_confirmed: bool | None = None
    failure_reason: str | None = Field(default=None, max_length=2000)
