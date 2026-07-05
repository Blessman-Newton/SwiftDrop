#!/usr/bin/env python3
"""
Database initialization script for Render deployment
Run this once after deploying to create tables and seed data
"""
import asyncio
import sys
from datetime import datetime, timezone
from uuid import uuid4

# Add parent directory to path
sys.path.insert(0, '/app')

from sqlalchemy import text
from app.core.database import engine, async_session, Base
from app.models import (
    User, Restaurant, MenuItem, Category, Order, OrderItem,
    RiderProfile, Notification, Review, Address
)
from app.core.security import hash_password


async def create_tables():
    """Create all database tables"""
    print("📦 Creating database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✅ Tables created successfully")


async def seed_categories():
    """Seed food categories"""
    print("🍕 Seeding categories...")
    async with async_session() as session:
        # Check if categories already exist
        result = await session.execute(text("SELECT COUNT(*) FROM categories"))
        count = result.scalar()
        
        if count > 0:
            print(f"⚠️  Categories already exist ({count} found), skipping...")
            return
        
        categories = [
            # Main categories
            {"name": "Pizza", "slug": "pizza", "icon": "pizza", "sort_order": 1},
            {"name": "Burgers", "slug": "burgers", "icon": "restaurant", "sort_order": 2},
            {"name": "Sushi", "slug": "sushi", "icon": "set_meal", "sort_order": 3},
            {"name": "Desserts", "slug": "desserts", "icon": "cake", "sort_order": 4},
            {"name": "Drinks", "slug": "drinks", "icon": "local_bar", "sort_order": 5},
            {"name": "African", "slug": "african", "icon": "soup_kitchen", "sort_order": 6},
            {"name": "Asian", "slug": "asian", "icon": "takeout_dining", "sort_order": 7},
            {"name": "Italian", "slug": "italian", "icon": "restaurant", "sort_order": 8},
            {"name": "Mexican", "slug": "mexican", "icon": "restaurant", "sort_order": 9},
            {"name": "Indian", "slug": "indian", "icon": "restaurant", "sort_order": 10},
            {"name": "Chinese", "slug": "chinese", "icon": "restaurant", "sort_order": 11},
            {"name": "Thai", "slug": "thai", "icon": "restaurant", "sort_order": 12},
            {"name": "Japanese", "slug": "japanese", "icon": "restaurant", "sort_order": 13},
            {"name": "Korean", "slug": "korean", "icon": "restaurant", "sort_order": 14},
            {"name": "Mediterranean", "slug": "mediterranean", "icon": "restaurant", "sort_order": 15},
            {"name": "American", "slug": "american", "icon": "restaurant", "sort_order": 16},
            {"name": "French", "slug": "french", "icon": "restaurant", "sort_order": 17},
            {"name": "Spanish", "slug": "spanish", "icon": "restaurant", "sort_order": 18},
            {"name": "Greek", "slug": "greek", "icon": "restaurant", "sort_order": 19},
            {"name": "Turkish", "slug": "turkish", "icon": "restaurant", "sort_order": 20},
        ]
        
        for cat in categories:
            category = Category(
                id=uuid4(),
                name=cat["name"],
                slug=cat["slug"],
                icon=cat["icon"],
                sort_order=cat["sort_order"],
                is_active=True,
                created_at=datetime.now(timezone.utc)
            )
            session.add(category)
        
        await session.commit()
        print(f"✅ Seeded {len(categories)} categories")


async def seed_test_users():
    """Create test users for customer, merchant, and rider"""
    print("👥 Creating test users...")
    async with async_session() as session:
        # Check if test users already exist
        result = await session.execute(
            text("SELECT COUNT(*) FROM users WHERE phone IN ('+1234567890', '+0987654321', '+1122334455')")
        )
        count = result.scalar()
        
        if count > 0:
            print(f"⚠️  Test users already exist ({count} found), skipping...")
            return
        
        # Test Customer
        customer = User(
            id=uuid4(),
            phone="+1234567890",
            email="customer@test.com",
            name="Test Customer",
            password_hash=hash_password("customer123"),
            role="customer",
            is_active=True,
            is_verified=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        session.add(customer)
        
        # Test Merchant
        merchant = User(
            id=uuid4(),
            phone="+0987654321",
            email="merchant@test.com",
            name="Test Merchant",
            password_hash=hash_password("merchant123"),
            role="merchant",
            is_active=True,
            is_verified=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        session.add(merchant)
        
        # Test Rider
        rider = User(
            id=uuid4(),
            phone="+1122334455",
            email="rider@test.com",
            name="Test Rider",
            password_hash=hash_password("rider123"),
            role="rider",
            is_active=True,
            is_verified=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        session.add(rider)
        
        await session.commit()
        print("✅ Created test users:")
        print("   Customer: +1234567890 / customer123")
        print("   Merchant: +0987654321 / merchant123")
        print("   Rider: +1122334455 / rider123")


async def seed_test_restaurant(merchant_id):
    """Create a test restaurant with menu items"""
    print("🍽️  Creating test restaurant...")
    async with async_session() as session:
        # Check if restaurant already exists
        result = await session.execute(
            text("SELECT COUNT(*) FROM restaurants WHERE owner_id = :owner_id"),
            {"owner_id": str(merchant_id)}
        )
        count = result.scalar()
        
        if count > 0:
            print(f"⚠️  Restaurant already exists for this merchant, skipping...")
            return
        
        restaurant = Restaurant(
            id=uuid4(),
            owner_id=merchant_id,
            name="Test Restaurant",
            description="A test restaurant for demo purposes",
            address="123 Test Street, Test City",
            phone="+1234567890",
            email="restaurant@test.com",
            image_url="https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800",
            logo_url="https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200",
            rating=4.5,
            delivery_time="30-45 min",
            delivery_fee=2.99,
            minimum_order=10.0,
            tags=["Popular", "Fast Delivery"],
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        session.add(restaurant)
        await session.flush()
        
        # Get categories
        result = await session.execute(text("SELECT id, name FROM categories LIMIT 5"))
        categories = result.fetchall()
        
        if not categories:
            print("⚠️  No categories found, skipping menu items...")
            await session.commit()
            return
        
        # Create menu items
        menu_items = [
            {
                "name": "Classic Burger",
                "description": "Juicy beef patty with lettuce, tomato, and special sauce",
                "price": 12.99,
                "image_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
                "category_id": categories[0][0],
                "is_available": True,
                "is_vegetarian": False,
                "is_spicy": False,
            },
            {
                "name": "Margherita Pizza",
                "description": "Fresh mozzarella, tomatoes, and basil on crispy crust",
                "price": 15.99,
                "image_url": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400",
                "category_id": categories[0][0] if len(categories) > 0 else categories[0][0],
                "is_available": True,
                "is_vegetarian": True,
                "is_spicy": False,
            },
            {
                "name": "Caesar Salad",
                "description": "Crisp romaine lettuce with parmesan and croutons",
                "price": 8.99,
                "image_url": "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                "category_id": categories[0][0] if len(categories) > 2 else categories[0][0],
                "is_available": True,
                "is_vegetarian": True,
                "is_spicy": False,
            },
            {
                "name": "Spicy Chicken Wings",
                "description": "Crispy chicken wings with hot sauce",
                "price": 10.99,
                "image_url": "https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400",
                "category_id": categories[0][0] if len(categories) > 3 else categories[0][0],
                "is_available": True,
                "is_vegetarian": False,
                "is_spicy": True,
            },
            {
                "name": "Chocolate Cake",
                "description": "Rich chocolate cake with cream frosting",
                "price": 6.99,
                "image_url": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400",
                "category_id": categories[0][0] if len(categories) > 3 else categories[0][0],
                "is_available": True,
                "is_vegetarian": True,
                "is_spicy": False,
            },
        ]
        
        for item_data in menu_items:
            menu_item = MenuItem(
                id=uuid4(),
                restaurant_id=restaurant.id,
                name=item_data["name"],
                description=item_data["description"],
                price=item_data["price"],
                image_url=item_data["image_url"],
                category_id=item_data["category_id"],
                is_available=item_data["is_available"],
                is_vegetarian=item_data["is_vegetarian"],
                is_spicy=item_data["is_spicy"],
                created_at=datetime.now(timezone.utc),
                updated_at=datetime.now(timezone.utc)
            )
            session.add(menu_item)
        
        await session.commit()
        print(f"✅ Created restaurant with {len(menu_items)} menu items")


async def seed_rider_profile(rider_id):
    """Create rider profile"""
    print("🚴 Creating rider profile...")
    async with async_session() as session:
        # Check if profile exists
        result = await session.execute(
            text("SELECT COUNT(*) FROM rider_profiles WHERE user_id = :user_id"),
            {"user_id": str(rider_id)}
        )
        count = result.scalar()
        
        if count > 0:
            print("⚠️  Rider profile already exists, skipping...")
            return
        
        profile = RiderProfile(
            id=uuid4(),
            user_id=rider_id,
            vehicle_type="motorcycle",
            license_number="TEST-LIC-123",
            rating=5.0,
            total_deliveries=0,
            is_online=False,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        session.add(profile)
        await session.commit()
        print("✅ Created rider profile")


async def main():
    """Main initialization function"""
    print("=" * 60)
    print("🚀 SwiftDrop Database Initialization")
    print("=" * 60)
    print()
    
    try:
        # Step 1: Create tables
        await create_tables()
        print()
        
        # Step 2: Seed categories
        await seed_categories()
        print()
        
        # Step 3: Create test users
        await seed_test_users()
        print()
        
        # Step 4: Get merchant ID
        async with async_session() as session:
            result = await session.execute(
                text("SELECT id FROM users WHERE phone = '+0987654321'")
            )
            merchant_row = result.fetchone()
            if merchant_row:
                merchant_id = merchant_row[0]
                
                # Step 5: Create restaurant
                await seed_test_restaurant(merchant_id)
                print()
        
        # Step 6: Get rider ID
        async with async_session() as session:
            result = await session.execute(
                text("SELECT id FROM users WHERE phone = '+1122334455'")
            )
            rider_row = result.fetchone()
            if rider_row:
                rider_id = rider_row[0]
                
                # Step 7: Create rider profile
                await seed_rider_profile(rider_id)
                print()
        
        print("=" * 60)
        print("✅ Database initialization complete!")
        print("=" * 60)
        print()
        print("📱 Test Credentials:")
        print("   Customer: +1234567890 / customer123")
        print("   Merchant: +0987654321 / merchant123")
        print("   Rider: +1122334455 / rider123")
        print()
        print("🌐 API Documentation: https://YOUR-APP.onrender.com/docs")
        print()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
