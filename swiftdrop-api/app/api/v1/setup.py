"""
One-time setup endpoint for database initialization
Access: POST /setup/initialize?secret=YOUR_SECRET_KEY
"""
from fastapi import APIRouter, HTTPException, Query
import subprocess
import sys

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
            timeout=60
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
                detail=f"Initialization failed: {result.stderr}"
            )
    
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Initialization timed out")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "app": "SwiftDrop API"}
