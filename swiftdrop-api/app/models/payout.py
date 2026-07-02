import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Payout(Base):
    __tablename__ = "payouts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[str] = mapped_column(
        Enum("pending", "processing", "completed", "failed", name="payout_status_enum"),
        nullable=False,
        default="pending",
    )
    payment_method: Mapped[str | None] = mapped_column(String(50))
    reference: Mapped[str | None] = mapped_column(String(100), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
