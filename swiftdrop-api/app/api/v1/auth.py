from fastapi import APIRouter, Cookie, Depends, Request, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.config import get_settings
from app.core.database import get_db
from app.core.rate_limit import rate_limit
from app.models.user import User
from app.schemas.auth import (
    EmailLoginRequest,
    LogoutResponse,
    PhoneLoginRequest,
    SendOTPRequest,
    SendOTPResponse,
    SignUpRequest,
    SocialLoginRequest,
    TokenResponse,
    UserResponse,
    VerifyOTPRequest,
)
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()


def _cookie_options() -> dict:
    options = {
        "key": settings.SESSION_COOKIE_NAME,
        "httponly": True,
        "secure": settings.session_cookie_secure_value,
        "samesite": settings.SESSION_COOKIE_SAMESITE,
        "max_age": settings.JWT_EXPIRY_MINUTES * 60,
        "path": "/",
    }
    if settings.SESSION_COOKIE_DOMAIN:
        options["domain"] = settings.SESSION_COOKIE_DOMAIN
    return options


def _set_session_cookie(response: Response, token: str | None) -> None:
    if token:
        response.set_cookie(value=token, **_cookie_options())


def _clear_session_cookie(response: Response) -> None:
    response.delete_cookie(
        key=settings.SESSION_COOKIE_NAME,
        path="/",
        domain=settings.SESSION_COOKIE_DOMAIN or None,
    )


def _auth_payload(result: TokenResponse, *, include_token: bool) -> dict:
    data = result.model_dump()
    if not include_token:
        data["access_token"] = None
        data["custom_token"] = None
    return data


@router.post("/signup", response_model=TokenResponse, dependencies=[Depends(rate_limit(10, 3600, "auth-signup"))])
async def signup(request: SignUpRequest, req: Request, response: Response, db: AsyncSession = Depends(get_db)):
    result = await auth_service.sign_up(
        db,
        request.email,
        request.password,
        request.phone,
        request.name,
        request.role,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
    )
    _set_session_cookie(response, result.access_token)
    # Bearer token is returned for mobile clients; web clients should rely on HttpOnly cookie.
    return _auth_payload(result, include_token=True)



@router.post("/login", response_model=TokenResponse, dependencies=[Depends(rate_limit(20, 900, "auth-login"))])
async def login(request: EmailLoginRequest, req: Request, response: Response, db: AsyncSession = Depends(get_db)):
    result = await auth_service.login_with_email(
        db,
        request.email,
        request.password,
        request.firebase_uid,
        request.id_token,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
    )
    _set_session_cookie(response, result.access_token)
    return _auth_payload(result, include_token=result.user.role in {"customer", "rider"})


@router.post("/phone-login", response_model=TokenResponse, dependencies=[Depends(rate_limit(20, 900, "auth-phone-login"))])
async def phone_login(request: PhoneLoginRequest, req: Request, response: Response, db: AsyncSession = Depends(get_db)):
    result = await auth_service.login_with_phone_password(
        db,
        request.phone,
        request.password,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
    )
    _set_session_cookie(response, result.access_token)
    return _auth_payload(result, include_token=True)


@router.post("/social-login", response_model=TokenResponse, dependencies=[Depends(rate_limit(30, 900, "auth-social"))])
async def social_login(request: SocialLoginRequest, req: Request, response: Response, db: AsyncSession = Depends(get_db)):
    result = await auth_service.social_login(
        db,
        request.provider,
        request.id_token,
        request.firebase_uid,
        request.email,
        request.name,
        request.photo_url,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
    )
    _set_session_cookie(response, result.access_token)
    return _auth_payload(result, include_token=True)


@router.post("/send-otp", response_model=SendOTPResponse, dependencies=[Depends(rate_limit(10, 600, "auth-otp-send"))])
async def send_otp(request: SendOTPRequest, db: AsyncSession = Depends(get_db)):
    result = await auth_service.send_otp(db, request.phone)
    if settings.APP_ENV == "development":
        result["dev_code"] = result.pop("code", None)
    else:
        result.pop("code", None)
    return SendOTPResponse(**result)


@router.post("/verify-otp", response_model=TokenResponse, dependencies=[Depends(rate_limit(15, 600, "auth-otp-verify"))])
async def verify_otp(request: VerifyOTPRequest, req: Request, response: Response, db: AsyncSession = Depends(get_db)):
    result = await auth_service.verify_otp(
        db,
        request.phone,
        request.code,
        ip_address=req.client.host if req.client else None,
        user_agent=req.headers.get("user-agent"),
    )
    _set_session_cookie(response, result.access_token)
    return _auth_payload(result, include_token=True)


@router.post("/logout", response_model=LogoutResponse)
async def logout(
    response: Response,
    session_cookie: str | None = Cookie(default=None, alias=settings.SESSION_COOKIE_NAME),
    db: AsyncSession = Depends(get_db),
):
    await auth_service.revoke_token(db, session_cookie)
    _clear_session_cookie(response)
    return LogoutResponse()


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user_dep)):
    return auth_service._user_to_response(current_user)
