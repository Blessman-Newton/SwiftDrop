from fastapi import APIRouter, Depends, HTTPException, Query
import hmac
import subprocess
import sys

from sqlalchemy import text
from app.core.database import engine, Base
from app.config import get_settings
from app.models import (
    User, RiderProfile, OTPCode,
    Restaurant, MenuItem, PromoCode,
    Category, Order, OrderItem, DispatchLog,
    Payment, SupportTicket, Payout,
    Notification, Review, Address
    , DeliveryFailure, RefundRequest
)

async def run_migrations() -> list[str]:
    """Apply pending column/table migrations safely (idempotent)."""
    migrations_done: list[str] = []
    async with engine.begin() as conn:
        r = await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS user_sessions (
                id UUID PRIMARY KEY,
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                token_hash VARCHAR(64) NOT NULL UNIQUE,
                expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                revoked_at TIMESTAMP WITH TIME ZONE,
                last_seen_at TIMESTAMP WITH TIME ZONE,
                ip_address VARCHAR(64),
                user_agent TEXT,
                created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
            )
        """))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_sessions_user_id ON user_sessions(user_id)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_sessions_expires_at ON user_sessions(expires_at)"))
        migrations_done.append("user_sessions_checked")
    return migrations_done

router = APIRouter(prefix="/setup", tags=["setup"])


def _require_setup_access(secret: str) -> None:
    settings = get_settings()
    if not settings.ALLOW_SETUP_ENDPOINTS:
        raise HTTPException(status_code=404, detail="Not found")
    configured_secret = settings.SETUP_SECRET
    if not configured_secret or not hmac.compare_digest(secret, configured_secret):
        raise HTTPException(status_code=403, detail="Invalid setup secret")


@router.post("/migrate")
async def migrate_database(secret: str = Query(..., description="Setup secret key")):
    _require_setup_access(secret)
    migrations_done = await run_migrations()
    return {"status": "success", "message": "Migration check complete", "changes": migrations_done}


@router.get("/health")
async def health_check():
    return {"status": "healthy", "app": "Doorush API"}
