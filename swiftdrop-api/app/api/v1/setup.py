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
            
            # Promote admin user if exists
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE email = 'admin@swiftdrop.com'")
            )
            admin_user = result.fetchone()
            
            if admin_user and admin_user[2] != 'admin':
                await conn.execute(
                    text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                    {"user_id": admin_user[0]}
                )
                migrations_done.append(f"promoted {admin_user[1]} to admin")
        
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


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "app": "SwiftDrop API"}
