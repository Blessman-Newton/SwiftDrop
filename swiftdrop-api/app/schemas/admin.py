from datetime import datetime
from pydantic import BaseModel, Field


class AdminDashboardStatsResponse(BaseModel):
    total_users: int
    total_riders: int
    total_merchants: int
    total_orders: int
    total_revenue: float
    orders_today: int
    revenue_today: float
    active_riders: int
    pending_orders: int
    completed_orders_today: int
    cancelled_orders_today: int
    new_users_today: int


class AdminUserResponse(BaseModel):
    id: str
    phone: str
    name: str | None = None
    email: str | None = None
    role: str
    avatar_url: str | None = None
    is_active: bool
    is_verified: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class AdminRiderResponse(BaseModel):
    id: str
    phone: str
    name: str | None = None
    email: str | None = None
    avatar_url: str | None = None
    is_active: bool
    is_online: bool
    rating: float
    total_deliveries: int
    earnings_balance: float
    vehicle_type: str | None = None
    is_banned: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class AdminOrderResponse(BaseModel):
    id: str
    order_no: str
    status: str
    customer_name: str
    rider_name: str | None = None
    restaurant_name: str | None = None
    order_type: str
    total: float
    payment_status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminRestaurantResponse(BaseModel):
    id: str
    name: str
    slug: str
    address: str
    phone: str | None = None
    email: str | None = None
    logo_url: str | None = None
    restaurant_type: str | None = None
    rating: float
    is_active: bool
    menu_item_count: int
    total_orders: int
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class AdminMenuItemResponse(BaseModel):
    id: str
    name: str
    description: str | None = None
    price: float
    category_name: str | None = None
    image_url: str | None = None
    is_available: bool
    is_vegetarian: bool
    is_spicy: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class BanUserRequest(BaseModel):
    reason: str | None = None


class UpdateOrderStatusAdminRequest(BaseModel):
    status: str
    reason: str | None = None


class PlatformAnalyticsResponse(BaseModel):
    orders_by_status: dict[str, int]
    orders_by_day: list[dict]
    revenue_by_day: list[dict]
    top_restaurants: list[dict]
    top_riders: list[dict]
    user_growth: list[dict]


class AdminCosmeticResponse(BaseModel):
    id: str
    name: str
    description: str | None = None
    price: float
    image_url: str | None = None
    is_available: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateCosmeticRequest(BaseModel):
    name: str
    description: str | None = None
    price: float
    image_url: str | None = None
