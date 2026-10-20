import uuid
from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class Banner(Base):
    __tablename__ = "banners"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    subtitle: Mapped[str | None] = mapped_column(Text)
    tag: Mapped[str | None] = mapped_column(String(100))
    button_text: Mapped[str | None] = mapped_column(String(100), default="Claim Offer")
    route: Mapped[str | None] = mapped_column(String(255), default="/food-delivery")
    image_url: Mapped[str | None] = mapped_column(Text)
    colors: Mapped[list | None] = mapped_column(JSONB, default=list)
    
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    creator_name: Mapped[str] = mapped_column(String(200), default="Admin")
    is_approved: Mapped[bool] = mapped_column(Boolean, default=False)
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
