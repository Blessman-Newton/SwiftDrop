import asyncio
from sqlalchemy import text
from app.core.database import async_session

async def seed_settings():
    async with async_session() as session:
        result = await session.execute(text("SELECT COUNT(*) FROM platform_settings WHERE key = 'gas_refill_prices'"))
        count = result.scalar()
        if count > 0:
            print("Gas refill prices setting already exists in database.")
            return

        print("Seeding default gas refill prices into platform_settings...")
        await session.execute(text("""
            INSERT INTO platform_settings (id, key, value, description, created_at, updated_at) VALUES
            ('e0000000-0000-0000-0000-000000000001', 
             'gas_refill_prices', 
             '{"6 kg": 75.0, "12.5 kg": 150.0, "14 kg": 180.0, "22 kg": 280.0, "50 kg": 600.0}',
             'Cylinder size to GHS price mapping for scheduled LPG refill delivery services.',
             NOW(), NOW())
        """))
        await session.commit()
        print("Gas refill prices seeded successfully!")

if __name__ == "__main__":
    asyncio.run(seed_settings())
