from datetime import datetime
from pydantic import BaseModel, Field


class RiderDashboardResponse(BaseModel):
    today_earnings: float
    today_trips: int
    today_distance: float
    today_active_time: int
    rating: float
    total_deliveries: int
    is_online: bool
    daily_goal: float
    goal_progress: float
    pending_order_count: int
    completed_today: int


class RiderEarningsResponse(BaseModel):
    available_balance: float
    weekly_earnings: list[dict]
    total_base_fare: float
    total_tips: float
    total_bonuses: float
    total_fees: float
    average_daily: float
    total_trips: int


class RiderTransactionResponse(BaseModel):
    id: str
    title: str
    amount: float
    is_bonus: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class RiderStatsResponse(BaseModel):
    rating: float
    acceptance_rate: float
    cancellation_rate: float
    total_deliveries: int
    on_time_rate: float


class RiderActiveDeliveryResponse(BaseModel):
    order_id: str
    order_no: str
    status: str
    restaurant_name: str | None = None
    pickup_address: str
    delivery_address: str
    items: list[dict]
    total: float
    customer_name: str | None = None
    customer_phone: str | None = None
    delivery_notes: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class UpdateDeliveryStatusRequest(BaseModel):
    status: str = Field(..., pattern=r"^(en_route|arrived|picked_up|delivered)$")
    latitude: float | None = None
    longitude: float | None = None


class RiderOnlineRequest(BaseModel):
    latitude: float | None = None
    longitude: float | None = None


class AvailableOrderResponse(BaseModel):
    id: str
    order_no: str
    restaurant_name: str | None = None
    pickup_address: str
    delivery_address: str
    total: float
    delivery_fee: float
    estimated_time: int
    distance: float
    created_at: datetime

    model_config = {"from_attributes": True}
