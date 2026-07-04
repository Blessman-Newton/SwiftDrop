from datetime import datetime
from pydantic import BaseModel, Field


class MenuItemResponse(BaseModel):
    id: str
    restaurant_id: str
    name: str
    description: str | None = None
    price: float
    image_url: str | None = None
    category_id: str | None = None
    category_name: str | None = None
    is_available: bool
    is_vegetarian: bool
    is_spicy: bool
    rating: float
    tags: list[str] = []

    model_config = {"from_attributes": True}


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
    tags: list[str] = []
    is_active: bool
    phone: str | None = None
    email: str | None = None
    opening_hours: dict | None = None
    restaurant_type: str | None = None
    owner_id: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    menu_items: list[MenuItemResponse] = []

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    id: str
    name: str
    slug: str
    description: str | None = None
    image_url: str | None = None
    address: str
    rating: float
    delivery_time: str | None = None
    delivery_fee: float
    minimum_order: float
    tags: list[str] = []
    is_active: bool
    menu_item_count: int = 0

    model_config = {"from_attributes": True}


class PromoCodeResponse(BaseModel):
    id: str
    code: str
    description: str | None = None
    discount_type: str
    discount_value: float
    minimum_order: float
    is_active: bool

    model_config = {"from_attributes": True}


class ValidatePromoRequest(BaseModel):
    code: str = Field(..., min_length=1, max_length=30)
    order_total: float = Field(..., gt=0)


class ValidatePromoResponse(BaseModel):
    valid: bool
    code: str | None = None
    discount_type: str | None = None
    discount_value: float | None = None
    discount_amount: float | None = None
    message: str
