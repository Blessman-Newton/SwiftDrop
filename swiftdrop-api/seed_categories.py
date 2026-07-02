"""
Seed script to populate the categories table with initial data.
Run this after the database tables are created.
"""
import asyncio
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import async_session
from app.models.category import Category


async def seed_categories(db: AsyncSession):
    """Seed the database with initial categories."""
    
    # Check if categories already exist
    result = await db.execute(select(Category))
    existing = result.scalars().first()
    if existing:
        print("Categories already exist, skipping seed.")
        return
    
    # Parent categories (International / Commercial)
    international = Category(
        id=uuid.uuid4(),
        name="International Foods",
        slug="international-foods",
        description="International and commercial food categories",
        display_order=1,
        is_active=True,
    )
    ghana_local = Category(
        id=uuid.uuid4(),
        name="Ghana Local Foods",
        slug="ghana-local-foods",
        description="Traditional Ghanaian food categories",
        display_order=2,
        is_active=True,
    )
    
    db.add(international)
    db.add(ghana_local)
    await db.flush()
    
    # International subcategories
    intl_categories = [
        ("Burgers", "burgers", "Classic and gourmet burgers", 1),
        ("Pizza", "pizza", "Various pizza styles", 2),
        ("Fried Chicken", "fried-chicken", "Crispy fried chicken dishes", 3),
        ("Pasta", "pasta", "Italian pasta dishes", 4),
        ("Sandwiches", "sandwiches", "Sandwiches and subs", 5),
        ("Sushi", "sushi", "Japanese sushi and sashimi", 6),
        ("Healthy", "healthy", "Healthy and nutritious options", 7),
        ("Steakhouse", "steakhouse", "Premium steak dishes", 8),
        ("Desserts", "desserts", "Sweet treats and desserts", 9),
        ("Beverages", "beverages", "Drinks and beverages", 10),
        ("Combos", "combos", "Combo meals and deals", 11),
        ("Sides", "sides", "Side dishes", 12),
    ]
    
    for name, slug, desc, order in intl_categories:
        cat = Category(
            id=uuid.uuid4(),
            name=name,
            slug=slug,
            description=desc,
            display_order=order,
            is_active=True,
            parent_id=international.id,
        )
        db.add(cat)
    
    # Ghana Local subcategories
    ghana_categories = [
        ("Jollof Rice", "jollof-rice", "Ghana's famous jollof rice variations", 1),
        ("Waakye", "waakye", "Traditional waakye with sides", 2),
        ("Banku", "banku", "Banku with soups and stews", 3),
        ("Fufu", "fufu", "Fufu with light soup, groundnut soup, palm nut soup", 4),
        ("Kenkey", "kenkey", "Kenkey with fried fish and pepper", 5),
        ("Red Red", "red-red", "Bean stew with fried plantain", 6),
        ("Tuo Zaafi", "tuo-zaafi", "Northern Ghana specialty TZ with ayoyo soup", 7),
        ("Kelewele", "kelewele", "Spicy fried plantain", 8),
        ("Gob3 (Beans & Gari)", "gob3", "Beans with gari and fried plantain", 9),
        ("Chichinga (Kebabs)", "chichinga", "Ghanaian meat kebabs", 10),
        ("Light Soup", "light-soup", "Traditional light soup with fufu/rice balls", 11),
        ("Groundnut Soup", "groundnut-soup", "Peanut-based soup with fufu/rice balls", 12),
        ("Palm Nut Soup", "palm-nut-soup", "Palm fruit soup with fufu/rice balls", 13),
        ("Kontomire Stew", "kontomire-stew", "Cocoyam leaf stew", 14),
        ("Nkate Nkwan", "nkate-nkwan", "Groundnut soup variation", 15),
    ]
    
    for name, slug, desc, order in ghana_categories:
        cat = Category(
            id=uuid.uuid4(),
            name=name,
            slug=slug,
            description=desc,
            display_order=order,
            is_active=True,
            parent_id=ghana_local.id,
        )
        db.add(cat)
    
    await db.commit()
    print(f"Seeded categories: 2 parents + {len(intl_categories)} international + {len(ghana_categories)} Ghana local")


async def main():
    async with async_session() as db:
        await seed_categories(db)


if __name__ == "__main__":
    asyncio.run(main())