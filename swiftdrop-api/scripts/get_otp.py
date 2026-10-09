import sys, asyncio
sys.path.insert(0,'.')
from sqlalchemy import text
from app.core.database import engine

async def main():
    async with engine.begin() as conn:
        r = await conn.execute(
            text("SELECT code FROM otp_codes WHERE phone = :phone ORDER BY created_at DESC LIMIT 1"),
            {"phone": "+233000000000"},
        )
        row = r.fetchone()
        if row:
            print(f"OTP={row[0]}")
        else:
            print("No OTP found")

asyncio.run(main())
