from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.config import get_settings
from app.core.database import engine, Base
from app.api.v1.setup import run_migrations
# Import models to register them with Base.metadata
from app.models import (
    User, RiderProfile, OTPCode,
    Restaurant, MenuItem, PromoCode,
    Category, Order, OrderItem, DispatchLog,
    Payment, SupportTicket, Payout,
    Notification, Review, Address
)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"Starting {settings.APP_NAME} API...")
    # Create tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Database tables ensured")
    # Run column/table migrations automatically
    try:
        done = await run_migrations()
        if done:
            print(f"Auto-migrations applied: {', '.join(done)}")
        else:
            print("Auto-migrations: nothing new to apply")
    except Exception as exc:
        print(f"Auto-migration error (non-fatal): {exc}")
    yield
    print(f"Shutting down {settings.APP_NAME} API...")



app = FastAPI(
    title=settings.APP_NAME,
    description="Multi-role delivery platform API for Ghana",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.APP_ENV == "development" else None,
    redoc_url="/redoc" if settings.APP_ENV == "development" else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health")
async def health():
    return {"status": "healthy", "service": settings.APP_NAME}
