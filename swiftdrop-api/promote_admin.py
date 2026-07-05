#!/usr/bin/env python3
"""
Promote user to admin role
"""
import asyncio
import sys
from uuid import UUID

sys.path.insert(0, '/app')

from sqlalchemy import text
from app.core.database import engine


async def promote_to_admin(user_id: str):
    """Promote user to admin role"""
    print(f"Promoting user {user_id} to admin...")
    
    async with engine.begin() as conn:
        # Check if user exists
        result = await conn.execute(
            text("SELECT id, email, role FROM users WHERE id = :user_id"),
            {"user_id": user_id}
        )
        user = result.fetchone()
        
        if not user:
            print(f"❌ User not found: {user_id}")
            return
        
        print(f"Current role: {user[2]}")
        
        # Update role to admin
        await conn.execute(
            text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
            {"user_id": user_id}
        )
        
        print(f"✅ User {user[1]} promoted to admin!")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python promote_admin.py <user_id>")
        sys.exit(1)
    
    user_id = sys.argv[1]
    asyncio.run(promote_to_admin(user_id))
