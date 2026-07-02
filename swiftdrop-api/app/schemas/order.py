from datetime import datetime
from pydantic import BaseModel, Field


class OrderItemCreate(BaseModel):
    name: str = Field(..., max_length=200)
    quantity: int = Field(1, ge=1)
    price: float = Field(..., gt=0)
    notes: str | None = None


class OrderItemResponse(BaseModel):
    id: str
    name: str
    quantity: int
    price: float
    notes: str | None = None

    model_config = {"from_attributes": True}


class CreateOrderRequest(BaseModel):
    order_type: str = Field(..., pattern=r"^(food|parcel)$")
    restaurant_name: str | None = None
    pickup_address: str = Field(..., min_length=1)
    pickup_lat: float | None = None
    pickup_lng: float | None = None
    delivery_address: str = Field(..., min_length=1)
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    subtotal: float = Field(..., gt=0)
    delivery_fee: float = Field(..., ge=0)
    tax: float = Field(..., ge=0)
    discount: float = Field(0, ge=0)
    total: float = Field(..., gt=0)
    promo_code: str | None = None
    items: list[OrderItemCreate] = []


class OrderResponse(BaseModel):
    id: str
    customer_id: str
    rider_id: str | None = None
    order_type: str
    status: str
    restaurant_name: str | None = None
    pickup_address: str
    pickup_lat: float | None = None
    pickup_lng: float | None = None
    delivery_address: str
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    subtotal: float
    delivery_fee: float
    tax: float
    discount: float
    total: float
    promo_code: str | None = None
    payment_ref: str | None = None
    payment_status: str
    created_at: datetime
    confirmed_at: datetime | None = None
    preparing_at: datetime | None = None
    picked_up_at: datetime | None = None
    delivered_at: datetime | None = None
    cancelled_at: datetime | None = None
    items: list[OrderItemResponse] = []

    model_config = {"from_attributes": True}


class CancelOrderRequest(BaseModel):
    reason: str | None = None
