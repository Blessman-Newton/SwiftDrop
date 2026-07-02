from datetime import datetime
from pydantic import BaseModel, Field


class NotificationResponse(BaseModel):
    id: str
    title: str
    body: str
    type: str
    is_read: bool
    metadata: dict | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int


class MarkReadRequest(BaseModel):
    notification_ids: list[str] = []


class SendNotificationRequest(BaseModel):
    user_id: str
    title: str = Field(..., min_length=1, max_length=200)
    body: str = Field(..., min_length=1)
    type: str = Field("system", pattern=r"^(order|promo|system|payment|rider)$")
