import asyncio
from sqlalchemy import text
from app.core.database import engine

async def test_connection():
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT 1"))
            print("SUCCESS: Connected to Render PostgreSQL database!")
            return True
    except Exception as e:
        print(f"FAILED: Connection failed: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_connection())
