import uuid
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(Text)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    latitude: Mapped[float | None] = mapped_column()
    longitude: Mapped[float | None] = mapped_column()
    rating: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    delivery_time: Mapped[str | None] = mapped_column(String(50))
    delivery_fee: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    minimum_order: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    tags: Mapped[list | None] = mapped_column(JSONB, default=list)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    owner_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    # Onboarding fields
    logo_url: Mapped[str | None] = mapped_column(Text)
    phone: Mapped[str | None] = mapped_column(String(20))
    email: Mapped[str | None] = mapped_column(String(255))
    opening_hours: Mapped[dict | None] = mapped_column(JSONB)
    restaurant_type: Mapped[str | None] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    menu_items: Mapped[list["MenuItem"]] = relationship(
        "MenuItem", back_populates="restaurant", cascade="all, delete-orphan"
    )


class MenuItem(Base):
    __tablename__ = "menu_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    restaurant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("restaurants.id", ondelete="CASCADE"), index=True
    )
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("categories.id", ondelete="SET NULL"), index=True
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    is_vegetarian: Mapped[bool] = mapped_column(Boolean, default=False)
    is_spicy: Mapped[bool] = mapped_column(Boolean, default=False)
    rating: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    tags: Mapped[list | None] = mapped_column(JSONB, default=list)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    restaurant: Mapped["Restaurant"] = relationship("Restaurant", back_populates="menu_items")
    category: Mapped["Category | None"] = relationship("Category", back_populates="menu_items")


class PromoCode(Base):
    __tablename__ = "promo_codes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text)
    discount_type: Mapped[str] = mapped_column(
        Enum("percentage", "flat", name="discount_type_enum"), nullable=False
    )
    discount_value: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    minimum_order: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    max_uses: Mapped[int | None] = mapped_column(Integer)
    used_count: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )