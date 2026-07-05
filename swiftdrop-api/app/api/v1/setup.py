"""
One-time setup endpoint for database initialization
Access: POST /setup/initialize?secret=YOUR_SECRET_KEY
Access: POST /setup/reset?secret=YOUR_SECRET_KEY
"""
from fastapi import APIRouter, HTTPException, Query
import subprocess
import sys

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


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "app": "SwiftDrop API"}
