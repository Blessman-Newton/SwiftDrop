"""
Create all database tables.
"""
import asyncio
from sqlalchemy import text
from app.core.database import engine, Base
from app.models import *  # noqa


async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("All tables created successfully!")


if __name__ == "__main__":
    asyncio.run(create_tables())