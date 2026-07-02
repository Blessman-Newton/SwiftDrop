from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.models.user import User
from app.services.auth_service import get_current_user
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security = HTTPBearer(auto_error=False)


async def get_current_user_dep(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None:
        raise UnauthorizedException("Missing Authorization header")
    return await get_current_user(db, credentials.credentials)


async def get_current_admin_dep(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None:
        raise UnauthorizedException("Missing Authorization header")
    user = await get_current_user(db, credentials.credentials)
    if user.role != "admin":
        raise ForbiddenException("Admin access required")
    return user


async def get_current_rider_dep(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None:
        raise UnauthorizedException("Missing Authorization header")
    user = await get_current_user(db, credentials.credentials)
    if user.role != "rider":
        raise ForbiddenException("Rider access required")
    return user
