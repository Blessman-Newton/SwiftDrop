from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.user import User
from app.schemas.rider import GoOnlineRequest
from app.services import dispatch_service

router = APIRouter(prefix="/riders", tags=["riders"])


@router.post("/online")
async def go_online(
    request: GoOnlineRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await dispatch_service.go_online(
        db, current_user.id, request.vehicle_type, request.license_number
    )


@router.post("/offline")
async def go_offline(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await dispatch_service.go_offline(db, current_user.id)


@router.get("/available-orders")
async def get_available_orders(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await dispatch_service.get_available_orders(db)
