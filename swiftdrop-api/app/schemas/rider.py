from pydantic import BaseModel, Field


class RiderProfileResponse(BaseModel):
    user_id: str
    is_online: bool
    rating: float
    total_deliveries: int
    earnings_balance: float
    vehicle_type: str | None = None
    license_number: str | None = None

    model_config = {"from_attributes": True}


class LocationUpdateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class GoOnlineRequest(BaseModel):
    vehicle_type: str | None = Field(None, max_length=20)
    license_number: str | None = Field(None, max_length=50)


class AvailableOrderResponse(BaseModel):
    id: str
    order_type: str
    restaurant_name: str | None = None
    pickup_address: str
    delivery_address: str
    total: float
    created_at: str

    model_config = {"from_attributes": True}
