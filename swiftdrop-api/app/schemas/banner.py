import uuid
from datetime import datetime
from pydantic import BaseModel

class BannerBase(BaseModel):
    title: str
    subtitle: str | None = None
    tag: str | None = None
    button_text: str | None = "Claim Offer"
    route: str | None = "/food-delivery"
    image_url: str | None = None
    colors: list[str] = []

class BannerCreate(BannerBase):
    pass

class BannerResponse(BannerBase):
    id: uuid.UUID
    created_by: uuid.UUID
    creator_name: str
    is_approved: bool
    created_at: datetime

    class Config:
        from_attributes = True
