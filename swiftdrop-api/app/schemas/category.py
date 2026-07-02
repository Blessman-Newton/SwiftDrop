from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CategoryResponse(BaseModel):
    id: str
    name: str
    slug: str
    description: str | None = None
    image_url: str | None = None
    display_order: int
    is_active: bool
    parent_id: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class CategoryCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
    image_url: str | None = None
    display_order: int = 0
    parent_id: str | None = None


class CategoryUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = None
    image_url: str | None = None
    display_order: int | None = None
    is_active: bool | None = None
    parent_id: str | None = None