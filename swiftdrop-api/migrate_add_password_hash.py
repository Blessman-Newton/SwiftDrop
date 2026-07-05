#!/usr/bin/env python3
"""
Add password_hash column to users table
"""
import asyncio
import sys

sys.path.insert(0, '/app')

from sqlalchemy import text
from app.core.database import engine


async def add_password_hash_column():
    """Add password_hash column to users table"""
    print("Adding password_hash column to users table...")
    
    async with engine.begin() as conn:
        # Check if column already exists
        result = await conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'password_hash'
        """))
        
        if result.fetchone():
            print("✅ password_hash column already exists")
            return
        
        # Add the column
        await conn.execute(text("""
            ALTER TABLE users 
            ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT ''
        """))
        
        print("✅ password_hash column added successfully")


if __name__ == "__main__":
    asyncio.run(add_password_hash_column())
