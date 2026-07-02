from datetime import datetime
from pydantic import BaseModel, Field


class AddressCreateRequest(BaseModel):
    label: str = Field("Home", max_length=50)
    address_line: str = Field(..., min_length=1)
    latitude: float | None = None
    longitude: float | None = None
    is_default: bool = False


class AddressResponse(BaseModel):
    id: str
    label: str
    address_line: str
    latitude: float | None = None
    longitude: float | None = None
    is_default: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class CustomerProfileUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    email: str | None = None
    avatar_url: str | None = None


class OrderHistoryResponse(BaseModel):
    orders: list[dict]
    total_count: int


class PayoutRequest(BaseModel):
    amount: float = Field(..., gt=0)
    payment_method: str = Field(..., min_length=1)


class PayoutResponse(BaseModel):
    id: str
    amount: float
    status: str
    payment_method: str | None = None
    reference: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class EarningsSummaryResponse(BaseModel):
    available_balance: float
    total_earned: float
    total_withdrawn: float
    pending_payouts: float
    deliveries_count: int
    average_rating: float
