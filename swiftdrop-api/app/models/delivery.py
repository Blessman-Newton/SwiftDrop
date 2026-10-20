from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class DeliveryFailure(Base):
    __tablename__ = "delivery_failures"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    order_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("orders.id", ondelete="RESTRICT"), unique=True, index=True
    )
    reported_by: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"))
    reason: Mapped[str] = mapped_column(String(100), nullable=False)
    responsible_party: Mapped[str | None] = mapped_column(String(50))
    resolution: Mapped[str | None] = mapped_column(Text)
    final_outcome: Mapped[str | None] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="reported")
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB, default=dict)
    resolved_by: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class RefundRequest(Base):
    __tablename__ = "refund_requests"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    order_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("orders.id", ondelete="RESTRICT"), unique=True, index=True
    )
    requested_by: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"))
    amount: Mapped[float] = mapped_column(nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="requested")
    provider_reference: Mapped[str | None] = mapped_column(String(255))
    provider_confirmed: Mapped[bool] = mapped_column(default=False, nullable=False)
    reviewed_by: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"))
    failure_reason: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )
