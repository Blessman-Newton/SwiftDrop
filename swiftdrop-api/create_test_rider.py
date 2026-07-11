import asyncio
import requests
from sqlalchemy import text
from app.core.database import engine
from app.core.security import hash_password

async def create_new_rider():
    """Create a new rider user in the database"""
    async with engine.begin() as conn:
        # Generate a new UUID for the rider
        result = await conn.execute(text("SELECT gen_random_uuid()"))
        user_id = result.scalar()
        
        # Hash the password
        password = "Rider123"
        password_hash = hash_password(password)
        
        # Insert new rider
        await conn.execute(
            text("""
                INSERT INTO users (id, email, phone, name, role, password_hash, is_active, is_verified, created_at, updated_at)
                VALUES (:id, :email, :phone, :name, :role, :password_hash, :is_active, :is_verified, NOW(), NOW())
            """),
            {
                "id": user_id,
                "email": "newrider@swiftdrop.com",
                "phone": "+233555123456",
                "name": "New Test Rider",
                "role": "rider",
                "password_hash": password_hash,
                "is_active": True,
                "is_verified": True
            }
        )
        
        print(f"New rider created:")
        print(f"  ID: {user_id}")
        print(f"  Email: newrider@swiftdrop.com")
        print(f"  Password: Rider123")
        return user_id

# Create the rider
asyncio.run(create_new_rider())

# Test login
print("\nTesting login...")
BASE_URL = 'http://localhost:8000/api/v1'

login_res = requests.post(f'{BASE_URL}/auth/login', json={
    'email': 'newrider@swiftdrop.com',
    'password': 'Rider123'
})

print(f"Login status: {login_res.status_code}")
if login_res.status_code == 200:
    data = login_res.json()
    print(f"Login successful!")
    print(f"User: {data['user']['name']}")
    print(f"Role: {data['user']['role']}")
    print(f"Token: {data['access_token'][:50]}...")
else:
    print(f"Login failed: {login_res.text}")
