from fastapi import Cookie, Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.database import get_db
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.models.user import User
from app.services.auth_service import get_current_user, get_current_user_from_session_id

settings = get_settings()
security = HTTPBearer(auto_error=False)


async def resolve_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    session_cookie: str | None = Cookie(default=None, alias=settings.SESSION_COOKIE_NAME),
    db: AsyncSession = Depends(get_db),
) -> User | None:
    if session_cookie:
        return await get_current_user_from_session_id(
            db,
            session_cookie,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    if credentials and credentials.credentials:
        return await get_current_user(
            db,
            credentials.credentials,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    return None


async def get_current_user_dep(
    user: User | None = Depends(resolve_current_user),
) -> User:
    if user is None:
        raise UnauthorizedException("Authentication required")
    return user


async def get_optional_current_user_dep(
    user: User | None = Depends(resolve_current_user),
) -> User | None:
    return user


async def get_current_admin_dep(
    user: User = Depends(get_current_user_dep),
) -> User:
    if user.role != "admin":
        raise ForbiddenException("Admin access required")
    return user


async def get_current_rider_dep(
    user: User = Depends(get_current_user_dep),
) -> User:
    if user.role != "rider":
        raise ForbiddenException("Rider access required")
    return user


async def get_current_merchant_dep(
    user: User = Depends(get_current_user_dep),
) -> User:
    if user.role != "merchant":
        raise ForbiddenException("Merchant access required")
    return user
