import logging
from pydantic_settings import BaseSettings
from pydantic import model_validator
from functools import lru_cache

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Doorush"
    APP_ENV: str = "development"
    APP_BASE_URL: str = "http://localhost:8000"

    CORS_ORIGINS: str = "*"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost/swiftdrop"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # Commissions
    COMMISSION_RATE_FOOD: float = 0.15
    COMMISSION_RATE_GAS: float = 0.05
    COMMISSION_RATE_PARCEL: float = 0.10
    COMMISSION_RATE_COSMETICS: float = 0.12
    VENDOR_RESPONSE_WINDOW_MINUTES: int = 15
    RIDER_ACCEPTANCE_WINDOW_MINUTES: int = 2

    # JWT
    JWT_SECRET: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    # Sessions last ~30 days so users stay signed in across app restarts.
    JWT_EXPIRY_MINUTES: int = 43200  # 30 days
    SETUP_SECRET: str = ""

    @model_validator(mode='after')
    def validate_jwt_secret(self) -> 'Settings':
        if self.APP_ENV == 'production' and self.JWT_SECRET == "change-me-in-production":
            logger.warning("WARNING: JWT_SECRET is not set in production!")
        return self

    # Paystack
    PAYSTACK_SECRET_KEY: str = ""
    PAYSTACK_PUBLIC_KEY: str = ""
    PAYSTACK_BASE_URL: str = "https://api.paystack.co"

    # Twilio SMS
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_NUMBER: str = ""

    # Firebase Admin SDK
    FIREBASE_CREDENTIALS_PATH: str = ""
    FIREBASE_CREDENTIALS_JSON: str = ""

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
