from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings

settings = get_settings()

from urllib.parse import urlparse

def normalize_database_url(url: str) -> str:
    if not url:
        return ""
    # Strip whitespace and quotes
    cleaned = url.strip().strip("'\"")
    # Convert postgres:// or postgresql:// to postgresql+asyncpg://
    if cleaned.startswith("postgres://"):
        cleaned = cleaned.replace("postgres://", "postgresql+asyncpg://", 1)
    elif cleaned.startswith("postgresql://") and not cleaned.startswith("postgresql+asyncpg://"):
        cleaned = cleaned.replace("postgresql://", "postgresql+asyncpg://", 1)
    # asyncpg expects ssl=require rather than sslmode=require
    if "sslmode=require" in cleaned:
        cleaned = cleaned.replace("sslmode=require", "ssl=require")
    return cleaned

def get_masked_db_target(url: str) -> str:
    try:
        parsed = urlparse(url)
        host = parsed.hostname or "unknown-host"
        port = parsed.port or 5432
        db = parsed.path.lstrip("/") or "unknown-db"
        return f"{host}:{port}/{db}"
    except Exception:
        return "invalid-url"

database_url = normalize_database_url(settings.DATABASE_URL)

engine = create_async_engine(
    database_url,
    echo=settings.APP_ENV == "development",
    pool_size=20,
    max_overflow=10,
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
