from datetime import datetime, timezone
from uuid import UUID

from pydantic import BaseModel, Field


class MerchantLoginRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=15)


class MerchantVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=15)
    code: str = Field(..., min_length=4, max_length=6)


class MenuItemCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    price: float = Field(..., gt=0)
    category_id: str | None = Field(default=None)
    image_url: str | None = None
    is_available: bool = True
    is_vegetarian: bool = False
    is_spicy: bool = False
    tags: list[str] | None = None


class MenuItemUpdateRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    price: float | None = Field(None, gt=0)
    category_id: str | None = None
    image_url: str | None = None
    is_available: bool | None = None
    is_vegetarian: bool | None = None
    is_spicy: bool | None = None
    tags: list[str] | None = None


class MenuItemResponse(BaseModel):
    id: str
    restaurant_id: str
    category_id: str | None = None
    category_name: str | None = None
    name: str
    description: str | None = None
    price: float
    image_url: str | None = None
    is_available: bool
    is_vegetarian: bool
    is_spicy: bool
    rating: float
    tags: list[str] | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class OrderItemResponse(BaseModel):
    name: str
    quantity: int
    price: float


class OrderResponse(BaseModel):
    id: str
    order_no: str
    status: str
    customer_name: str
    items: list[OrderItemResponse]
    total: float
    created_at: datetime
    elapsed_seconds: int = 0

    model_config = {"from_attributes": True}


class UpdateOrderStatusRequest(BaseModel):
    status: str = Field(..., pattern=r"^(confirmed|preparing|ready|completed|declined)$")


class DashboardStatsResponse(BaseModel):
    total_orders_today: int
    total_earnings_today: float
    avg_preparation_time: float
    cancelled_orders: int
    active_orders: int
    completed_orders: int


class MerchantInfoResponse(BaseModel):
    restaurant_id: str
    restaurant_name: str
    merchant_name: str
    avatar_url: str | None = None
    is_online: bool
    rating: float
    total_orders: int


class RestaurantCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    address: str = Field(..., min_length=5, max_length=500)
    latitude: float | None = None
    longitude: float | None = None
    logo_url: str | None = None
    phone: str | None = Field(None, max_length=20)
    email: str | None = Field(None, max_length=255)
    opening_hours: dict | None = None
    restaurant_type: str | None = Field(None, max_length=100)
    delivery_time: str | None = Field(None, max_length=50)
    delivery_fee: float = Field(default=0, ge=0)
    minimum_order: float = Field(default=0, ge=0)


class RestaurantUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    address: str | None = Field(None, min_length=5, max_length=500)
    latitude: float | None = None
    longitude: float | None = None
    logo_url: str | None = None
    phone: str | None = Field(None, max_length=20)
    email: str | None = Field(None, max_length=255)
    opening_hours: dict | None = None
    restaurant_type: str | None = Field(None, max_length=100)
    delivery_time: str | None = Field(None, max_length=50)
    delivery_fee: float | None = Field(None, ge=0)
    minimum_order: float | None = Field(None, ge=0)
    is_active: bool | None = None


class RestaurantResponse(BaseModel):
    id: str
    name: str
    slug: str
    description: str | None = None
    image_url: str | None = None
    logo_url: str | None = None
    address: str
    latitude: float | None = None
    longitude: float | None = None
    rating: float
    delivery_time: str | None = None
    delivery_fee: float
    minimum_order: float
    tags: list | None = None
    is_active: bool
    phone: str | None = None
    email: str | None = None
    opening_hours: dict | None = None
    restaurant_type: str | None = None
    owner_id: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}