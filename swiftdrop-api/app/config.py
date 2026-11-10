import logging
from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Doorush"
    APP_ENV: str = "development"
    APP_BASE_URL: str = "http://localhost:8000"

    # Comma-separated origins. In production, "*" is refused and credentials are
    # enabled only for explicit origins (required for HttpOnly cookie auth).
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:3001,http://localhost:5173"

    @property
    def cors_origin_list(self) -> list[str]:
        origins = [origin.strip().rstrip("/") for origin in self.CORS_ORIGINS.split(",") if origin.strip()]
        if not origins:
            return []
        if "*" in origins and self.APP_ENV == "production":
            logger.error("CORS_ORIGINS cannot include '*' in production")
            return []
        return origins

    @property
    def cors_allow_credentials(self) -> bool:
        origins = self.cors_origin_list
        return bool(origins) and "*" not in origins

    # Database
    # Local PostgreSQL is the development default. Production must provide its
    # own DATABASE_URL through the deployment environment.
    DATABASE_URL: str = "postgresql+asyncpg://swiftdrop:swiftdrop@localhost:5432/swiftdrop"

    # Redis (optional; reserved for future cache/queue use)
    REDIS_URL: str = ""

    # Commissions
    COMMISSION_RATE_FOOD: float = 0.15
    COMMISSION_RATE_GAS: float = 0.05
    COMMISSION_RATE_PARCEL: float = 0.10
    COMMISSION_RATE_COSMETICS: float = 0.12
    VENDOR_RESPONSE_WINDOW_MINUTES: int = 15
    RIDER_ACCEPTANCE_WINDOW_MINUTES: int = 2

    # JWT / sessions
    JWT_SECRET: str = "change-me-in-development-only"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRY_MINUTES: int = 43200  # 30 days (mobile bearer compatibility)
    SESSION_COOKIE_NAME: str = "swiftdrop_session"
    SESSION_COOKIE_SECURE: bool | None = None
    SESSION_COOKIE_SAMESITE: str = "lax"  # lax|strict|none
    SESSION_COOKIE_DOMAIN: str = ""
    # Admin/ops endpoints. Keep unset in production unless explicitly needed.
    SETUP_SECRET: str = ""
    ALLOW_SETUP_ENDPOINTS: bool = False
    # Public self-registration role. "admin" is never allowed from public signup.
    ALLOW_PUBLIC_MERCHANT_SIGNUP: bool = True

    # Paystack
    PAYSTACK_SECRET_KEY: str = ""
    PAYSTACK_PUBLIC_KEY: str = ""
    # Empty locally so payment code cannot make an outbound request by default.
    PAYSTACK_BASE_URL: str = ""

    # Twilio SMS
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_NUMBER: str = ""

    # Firebase Admin SDK
    FIREBASE_CREDENTIALS_PATH: str = ""
    FIREBASE_CREDENTIALS_JSON: str = ""

    # Maps (used by backend proxy endpoints; keeps third-party keys off clients)
    TOMTOM_API_KEY: str = ""

    @property
    def session_cookie_secure_value(self) -> bool:
        if self.SESSION_COOKIE_SECURE is not None:
            return self.SESSION_COOKIE_SECURE
        return self.APP_ENV == "production"

    @model_validator(mode="after")
    def validate_production_config(self) -> "Settings":
        if self.APP_ENV == "production":
            if not self.DATABASE_URL:
                raise ValueError("DATABASE_URL must be set in production")
            if not self.JWT_SECRET or self.JWT_SECRET == "change-me-in-development-only":
                raise ValueError("JWT_SECRET must be set to a strong value in production")
            if len(self.JWT_SECRET) < 32:
                raise ValueError("JWT_SECRET must be at least 32 characters in production")
            if "*" in self.cors_origin_list:
                raise ValueError("CORS_ORIGINS cannot include '*' in production")
        return self

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
