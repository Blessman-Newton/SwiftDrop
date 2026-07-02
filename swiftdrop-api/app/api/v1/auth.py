from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.config import get_settings
from app.core.database import get_db
from app.models.user import User
from app.schemas.auth import (
    SendOTPRequest,
    SendOTPResponse,
    TokenResponse,
    UserResponse,
    VerifyOTPRequest,
)
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/send-otp", response_model=SendOTPResponse)
async def send_otp(request: SendOTPRequest, db: AsyncSession = Depends(get_db)):
    result = await auth_service.send_otp(db, request.phone)
    settings = get_settings()
    if settings.APP_ENV == "development":
        result["dev_code"] = result.pop("code", None)
    else:
        result.pop("code", None)
    return SendOTPResponse(**result)


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(request: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    return await auth_service.verify_otp(
        db, request.phone, request.code, request.name, request.role
    )


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user_dep),
):
    return UserResponse(
        id=str(current_user.id),
        phone=current_user.phone,
        name=current_user.name,
        email=current_user.email,
        role=current_user.role,
        avatar_url=current_user.avatar_url,
        is_verified=current_user.is_verified,
    )
