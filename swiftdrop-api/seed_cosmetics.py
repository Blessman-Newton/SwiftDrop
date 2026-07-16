import asyncio
from sqlalchemy import text
from app.core.database import async_session

async def seed_cosmetics():
    async with async_session() as session:
        result = await session.execute(text("SELECT COUNT(*) FROM cosmetics"))
        count = result.scalar()
        if count > 0:
            print(f"Cosmetics already seeded: {count} items found.")
            return

        print("Seeding default cosmetics into database...")
        await session.execute(text("""
            INSERT INTO cosmetics (id, name, description, price, image_url, is_available, created_at) VALUES
            ('a0000000-0000-0000-0000-000000000001', 'Cocoa Butter Lotion', 'Rich nourishing body cream for smooth skin.', 45.00, 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400', true, NOW()),
            ('a0000000-0000-0000-0000-000000000002', 'Shea Moisture Hair Oil', 'Pure Ghanaian raw shea butter infusion.', 60.00, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=400', true, NOW()),
            ('a0000000-0000-0000-0000-000000000003', 'Matte Lipstick (Ruby)', 'Long-lasting vibrant matte lip color.', 35.00, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400', true, NOW()),
            ('a0000000-0000-0000-0000-000000000004', 'Aloe Vera Facial Gel', 'Soothes and hydrates skin naturally.', 25.00, 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400', true, NOW()),
            ('a0000000-0000-0000-0000-000000000005', 'Coconut Oil Lip Balm', 'Protects lips against dryness and wind.', 12.00, 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400', true, NOW())
        """))
        await session.commit()
        print("Cosmetics seeded successfully!")

if __name__ == "__main__":
    asyncio.run(seed_cosmetics())
