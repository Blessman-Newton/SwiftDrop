"""
One-time setup endpoint for database initialization
Access: POST /setup/initialize?secret=YOUR_SECRET_KEY
Access: POST /setup/reset?secret=YOUR_SECRET_KEY
Access: POST /setup/migrate?secret=YOUR_SECRET_KEY
"""
from fastapi import APIRouter, HTTPException, Query
import subprocess
import sys

from sqlalchemy import text
from app.core.database import engine, Base
from app.models import (
    User, RiderProfile, OTPCode,
    Restaurant, MenuItem, PromoCode,
    Category, Order, OrderItem, DispatchLog,
    Payment, SupportTicket, Payout,
    Notification, Review, Address
)

router = APIRouter(prefix="/setup", tags=["setup"])


@router.post("/initialize")
async def initialize_database(secret: str = Query(..., description="Setup secret key")):
    """
    Initialize database with tables and seed data.
    This is a one-time setup endpoint - disable after use!
    """
    # Simple security check
    if secret != "SWIFTDROP_SETUP_2026":
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    try:
        # Run the initialization script
        result = subprocess.run(
            [sys.executable, "init_db.py"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd="/app"
        )
        
        if result.returncode == 0:
            return {
                "status": "success",
                "message": "Database initialized successfully",
                "output": result.stdout
            }
        else:
            raise HTTPException(
                status_code=500,
                detail={
                    "error": "Initialization failed",
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                }
            )
    
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Initialization timed out")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/migrate")
async def migrate_database(secret: str = Query(..., description="Setup secret key")):
    """
    Add missing columns to existing tables and promote admin user
    """
    if secret != "SWIFTDROP_SETUP_2026":
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    try:
        migrations_done = []
        
        async with engine.begin() as conn:
            # Check if password_hash column exists
            result = await conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'users' AND column_name = 'password_hash'
            """))
            
            if not result.fetchone():
                # Add password_hash column
                await conn.execute(text("""
                    ALTER TABLE users 
                    ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT ''
                """))
                migrations_done.append("password_hash")
            
            # Check if onboarding_completed column exists
            result = await conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'users' AND column_name = 'onboarding_completed'
            """))
            
            if not result.fetchone():
                # Add onboarding_completed column
                await conn.execute(text("""
                    ALTER TABLE users 
                    ADD COLUMN onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE
                """))
                migrations_done.append("onboarding_completed")

            # Check if last_lat column exists on rider_profiles
            result = await conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'rider_profiles' AND column_name = 'last_lat'
            """))
            
            if not result.fetchone():
                await conn.execute(text("""
                    ALTER TABLE rider_profiles 
                    ADD COLUMN last_lat DOUBLE PRECISION
                """))
                await conn.execute(text("""
                    ALTER TABLE rider_profiles 
                    ADD COLUMN last_lng DOUBLE PRECISION
                """))
                migrations_done.append("rider_location_columns")
            
            # Check if cosmetics table exists
            result = await conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'cosmetics'
                )
            """))
            if not result.scalar():
                await conn.execute(text("""
                    CREATE TABLE cosmetics (
                        id UUID PRIMARY KEY,
                        name VARCHAR(200) NOT NULL,
                        description TEXT,
                        price NUMERIC(10, 2) NOT NULL,
                        image_url TEXT,
                        is_available BOOLEAN DEFAULT TRUE,
                        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
                    )
                """))
                await conn.execute(text("""
                    INSERT INTO cosmetics (id, name, description, price, image_url, is_available) VALUES
                    ('a0000000-0000-0000-0000-000000000001', 'Cocoa Butter Lotion', 'Rich nourishing body cream for smooth skin.', 45.00, 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400', true),
                    ('a0000000-0000-0000-0000-000000000002', 'Shea Moisture Hair Oil', 'Pure Ghanaian raw shea butter infusion.', 60.00, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=400', true),
                    ('a0000000-0000-0000-0000-000000000003', 'Matte Lipstick (Ruby)', 'Long-lasting vibrant matte lip color.', 35.00, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400', true),
                    ('a0000000-0000-0000-0000-000000000004', 'Aloe Vera Facial Gel', 'Soothes and hydrates skin naturally.', 25.00, 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400', true),
                    ('a0000000-0000-0000-0000-000000000005', 'Coconut Oil Lip Balm', 'Protects lips against dryness and wind.', 12.00, 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400', true)
                """))
                migrations_done.append("created_cosmetics_table_and_seeded_data")

            # Promote admin user if exists
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE email = :email"),
                {"email": "admin@swiftdrop.com"}
            )
            admin_user = result.fetchone()
            
            if admin_user:
                admin_id = str(admin_user[0])
                admin_email = admin_user[1]
                admin_role = admin_user[2]
                
                if admin_role != 'admin':
                    await conn.execute(
                        text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                        {"user_id": admin_id}
                    )
                    migrations_done.append(f"promoted {admin_email} from '{admin_role}' to 'admin'")
                else:
                    migrations_done.append(f"admin user already exists: {admin_email}")
            else:
                # Try to find any user with admin in the name or email
                result = await conn.execute(
                    text("SELECT id, email, role FROM users WHERE email LIKE '%admin%' OR name LIKE '%admin%' LIMIT 1")
                )
                potential_admin = result.fetchone()
                if potential_admin:
                    await conn.execute(
                        text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                        {"user_id": str(potential_admin[0])}
                    )
                    migrations_done.append(f"promoted {potential_admin[1]} to admin")
        
        if migrations_done:
            return {
                "status": "success",
                "message": f"Migration completed: {', '.join(migrations_done)}",
                "changes": migrations_done
            }
        else:
            return {
                "status": "success",
                "message": "No migration needed: all columns already exist"
            }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Migration error: {str(e)}")


@router.post("/reset")
async def reset_database(secret: str = Query(..., description="Setup secret key")):
    """
    Drop all tables and recreate with seed data.
    WARNING: This will delete all data!
    """
    if secret != "SWIFTDROP_SETUP_2026":
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        
        result = subprocess.run(
            [sys.executable, "init_db.py"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd="/app"
        )
        
        if result.returncode == 0:
            return {
                "status": "success",
                "message": "Database reset and initialized successfully",
                "output": result.stdout
            }
        else:
            raise HTTPException(
                status_code=500,
                detail={
                    "error": "Reset failed",
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                }
            )
    
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Reset timed out")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/promote-admin")
async def promote_to_admin(
    secret: str = Query(..., description="Setup secret key"),
    user_id: str = Query(..., description="User ID to promote to admin")
):
    """
    Promote a user to admin role.
    One-time setup endpoint - use with caution!
    """
    if secret != "SWIFTDROP_SETUP_2026":
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    try:
        async with engine.begin() as conn:
            # Check if user exists
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE id = :user_id"),
                {"user_id": user_id}
            )
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail=f"User not found: {user_id}")
            
            old_role = user[2]
            
            # Update role to admin
            await conn.execute(
                text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                {"user_id": user_id}
            )
            
            return {
                "status": "success",
                "message": f"User {user[1]} promoted from '{old_role}' to 'admin'",
                "user_id": user_id,
                "email": user[1],
                "old_role": old_role,
                "new_role": "admin"
            }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/force-promote")
async def force_promote(
    secret: str = Query(..., description="Setup secret key"),
    user_id: str = Query(..., description="User ID to promote")
):
    """Force promote user to admin - debug endpoint"""
    if secret != "SWIFTDROP_SETUP_2026":
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    try:
        async with engine.begin() as conn:
            # Direct update without conditions
            await conn.execute(
                text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                {"user_id": user_id}
            )
            
            # Verify the update
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE id = :user_id"),
                {"user_id": user_id}
            )
            user = result.fetchone()
            
            if user:
                return {
                    "status": "success",
                    "message": f"User promoted to admin",
                    "user_id": str(user[0]),
                    "email": user[1],
                    "role": user[2]
                }
            else:
                return {"status": "error", "message": "User not found after update"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "app": "SwiftDrop API"}
