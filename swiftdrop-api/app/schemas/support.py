from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CreateSupportTicketRequest(BaseModel):
    subject: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=3, max_length=5000)
    order_id: UUID | None = None
    priority: str = "medium"


class SupportTicketResponse(BaseModel):
    id: UUID
    order_id: UUID | None
    subject: str
    description: str
    status: str
    priority: str
    messages: list[dict] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class UpdateSupportTicketRequest(BaseModel):
    status: str | None = None
    priority: str | None = None
    message: str | None = Field(default=None, min_length=1, max_length=5000)
