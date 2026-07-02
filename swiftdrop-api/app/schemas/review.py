from datetime import datetime
from pydantic import BaseModel, Field


class CreateReviewRequest(BaseModel):
    order_id: str
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = None
    review_type: str = Field("delivery", pattern=r"^(rider|restaurant|delivery)$")


class ReviewResponse(BaseModel):
    id: str
    order_id: str
    customer_name: str
    rider_name: str | None = None
    restaurant_name: str | None = None
    rating: int
    comment: str | None = None
    review_type: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewListResponse(BaseModel):
    reviews: list[ReviewResponse]
    average_rating: float
    total_reviews: int


class RiderRatingSummary(BaseModel):
    rider_id: str
    average_rating: float
    total_reviews: int
    rating_distribution: dict[str, int]


class RestaurantRatingSummary(BaseModel):
    restaurant_id: str
    average_rating: float
    total_reviews: int
    rating_distribution: dict[str, int]
