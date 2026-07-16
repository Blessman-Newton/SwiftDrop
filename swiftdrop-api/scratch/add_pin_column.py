import asyncio
from sqlalchemy import text
from app.core.database import engine

async def add_column():
    async with engine.begin() as conn:
        await conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_pin VARCHAR(10)"))
    print("Column delivery_pin verified/added successfully!")

if __name__ == "__main__":
    asyncio.run(add_column())
