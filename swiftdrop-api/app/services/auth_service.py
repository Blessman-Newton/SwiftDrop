import asyncio
import logging
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
    UnauthorizedException,
)
from app.core.security import (
    create_access_token,
    decode_access_token,
    generate_otp,
    generate_session_id,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.restaurant import Restaurant
from app.models.session import UserSession
from app.models.user import OTPCode, RiderProfile, User
from app.schemas.auth import TokenResponse, UserResponse
from app.services.firebase_service import create_custom_token, verify_firebase_id_token
from app.services.sms_service import send_otp_sms

logger = logging.getLogger(__name__)
settings = get_settings()
PUBLIC_SELF_SIGNUP_ROLES = {"customer", "rider"} | (
    {"merchant"} if settings.ALLOW_PUBLIC_MERCHANT_SIGNUP else set()
)


def _normalize_phone(phone: str) -> str:
    phone = phone.strip().replace(" ", "").replace("-", "")
    if phone.startswith("0"):
        phone = "+233" + phone[1:]
    elif phone.startswith("233") and not phone.startswith("+"):
        phone = "+" + phone
    elif not phone.startswith("+"):
        phone = "+" + phone
    return phone


def _user_to_response(user: User) -> UserResponse:
    return UserResponse(
        id=str(user.id),
        phone=user.phone,
        name=user.name,
        email=user.email,
        role=user.role,
        avatar_url=user.avatar_url,
        is_verified=user.is_verified,
        onboarding_completed=user.onboarding_completed,
        wallet_balance=float(user.wallet_balance or 0.0),
        loyalty_points=int(user.loyalty_points or 0),
        membership_tier=user.membership_tier or "Bronze",
    )


async def _create_session(
    db: AsyncSession,
    user: User,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> tuple[str, datetime]:
    session_id = generate_session_id()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_EXPIRY_MINUTES)
    token = create_access_token(
        {"sub": str(user.id), "role": user.role, "sid": session_id},
        expires_delta=timedelta(minutes=settings.JWT_EXPIRY_MINUTES),
    )
    db.add(
        UserSession(
            id=UUID(session_id) if len(session_id) == 36 else None,
            user_id=user.id,
            token_hash=hash_token(token),
            expires_at=expires_at,
            ip_address=(ip_address or "")[:64] or None,
            user_agent=(user_agent or "")[:1024] or None,
        )
    )
    await db.flush()
    return token, expires_at


async def _issue_auth(
    db: AsyncSession,
    user: User,
    *,
    custom_token: str | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    token, expires_at = await _create_session(
        db, user, ip_address=ip_address, user_agent=user_agent
    )
    return TokenResponse(
        access_token=token,
        user=_user_to_response(user),
        custom_token=custom_token,
        expires_in_minutes=settings.JWT_EXPIRY_MINUTES,
    )


def _assert_signup_role(role: str) -> None:
    if role == "admin":
        raise ForbiddenException("Admin accounts cannot be self-registered")
    if role not in PUBLIC_SELF_SIGNUP_ROLES:
        raise ForbiddenException("Account type is not available for self-registration")


async def sign_up(
    db: AsyncSession,
    email: str,
    password: str,
    phone: str,
    name: str | None = None,
    role: str = "customer",
    firebase_uid: str | None = None,
    id_token: str | None = None,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    _assert_signup_role(role)
    phone = _normalize_phone(phone)
    email = email.strip().lower()

    if id_token:
        decoded = verify_firebase_id_token(id_token)
        if not decoded:
            raise UnauthorizedException("Invalid authentication token")
        firebase_uid = decoded.get("uid", firebase_uid)

    existing_phone = await db.execute(select(User.id).where(User.phone == phone))
    if existing_phone.scalar_one_or_none():
        raise ConflictException("Phone number already registered")

    existing_email = await db.execute(select(User.id).where(User.email == email))
    if existing_email.scalar_one_or_none():
        raise ConflictException("Email already registered")

    user = User(
        phone=phone,
        email=email,
        password_hash=hash_password(password),
        name=(name or "").strip()[:100] or None,
        role=role,
        is_verified=bool(id_token),
    )
    db.add(user)
    await db.flush()

    if role == "rider":
        db.add(RiderProfile(user_id=user.id))
    elif role == "merchant":
        slug = f"restaurant-{str(user.id)[:8]}"
        db.add(
            Restaurant(
                name=f"Restaurant {phone[-4:]}",
                slug=slug,
                address="Pending setup",
                owner_id=user.id,
                is_active=True,
            )
        )

    await db.flush()
    return await _issue_auth(db, user, ip_address=ip_address, user_agent=user_agent)


async def login_with_email(
    db: AsyncSession,
    email: str,
    password: str,
    firebase_uid: str | None = None,
    id_token: str | None = None,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    email = email.strip().lower()
    if id_token:
        decoded = verify_firebase_id_token(id_token)
        if not decoded:
            raise UnauthorizedException("Invalid authentication token")
        firebase_uid = decoded.get("uid", firebase_uid)

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        raise UnauthorizedException("Invalid email or password")
    if not user.is_active:
        raise ForbiddenException("Account has been deactivated")
    return await _issue_auth(db, user, ip_address=ip_address, user_agent=user_agent)


async def login_with_phone_password(
    db: AsyncSession,
    phone: str,
    password: str,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    phone = _normalize_phone(phone)
    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        raise UnauthorizedException("Invalid phone number or password")
    if not user.is_active:
        raise ForbiddenException("Account has been deactivated")
    custom_token = create_custom_token(str(user.id))
    return await _issue_auth(
        db, user, custom_token=custom_token, ip_address=ip_address, user_agent=user_agent
    )


async def social_login(
    db: AsyncSession,
    provider: str,
    id_token: str,
    firebase_uid: str | None = None,
    email: str | None = None,
    name: str | None = None,
    photo_url: str | None = None,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    decoded = verify_firebase_id_token(id_token)
    if not decoded:
        raise UnauthorizedException("Invalid authentication token")
    firebase_uid = decoded.get("uid", firebase_uid)
    email = (email or decoded.get("email") or "").strip().lower()
    if not email:
        raise BadRequestException("Email required for social login")
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if user:
        if not user.is_active:
            raise ForbiddenException("Account has been deactivated")
        return await _issue_auth(db, user, ip_address=ip_address, user_agent=user_agent)

    phone = decoded.get("phone_number") or f"+u{str(UUID(int=abs(hash(firebase_uid or email)) % (10**12))).zfill(12)}"
    existing_phone = await db.execute(select(User.id).where(User.phone == phone))
    if existing_phone.scalar_one_or_none():
        phone = f"+m{str(UUID(int=abs(hash(email)) % (10**12))).zfill(12)}"
    user = User(
        phone=phone,
        email=email,
        password_hash=hash_password(f"social:{provider}:{firebase_uid}:{generate_session_id()}"),
        name=(name or decoded.get("name") or "").strip()[:100] or None,
        role="customer",
        avatar_url=(photo_url or decoded.get("picture") or "")[:2048] or None,
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    return await _issue_auth(db, user, ip_address=ip_address, user_agent=user_agent)


async def send_otp(db: AsyncSession, phone: str) -> dict:
    phone = _normalize_phone(phone)
    result = await db.execute(select(User.id).where(User.phone == phone))
    if not result.scalar_one_or_none():
        raise NotFoundException("Account not found")

    otp_count = await db.execute(
        select(func.count()).select_from(OTPCode).where(
            OTPCode.phone == phone,
            OTPCode.used == False,  # noqa: E712
            OTPCode.created_at > datetime.now(timezone.utc) - timedelta(days=1),
        )
    )
    if (otp_count.scalar() or 0) >= 5:
        raise BadRequestException("OTP limit reached. Please try again later")

    code = generate_otp()
    db.add(
        OTPCode(
            phone=phone,
            code=code,  # Existing schema stores code; consider hashing in follow-up migration.
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
        )
    )
    await db.flush()
    sent, error_msg = await asyncio.to_thread(send_otp_sms, phone, code)
    if not sent:
        logger.warning("SMS send failed for OTP request: %s", error_msg)
        raise BadRequestException("Failed to send verification code")
    return {"message": "OTP sent successfully", "phone": phone, "code": code}


async def verify_otp(
    db: AsyncSession,
    phone: str,
    code: str,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> TokenResponse:
    phone = _normalize_phone(phone)
    result = await db.execute(
        select(OTPCode)
        .where(
            OTPCode.phone == phone,
            OTPCode.code == code,
            OTPCode.used == False,  # noqa: E712
            OTPCode.expires_at > datetime.now(timezone.utc),
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    otp = result.scalar_one_or_none()
    if not otp:
        raise BadRequestException("Invalid or expired verification code")
    otp.used = True
    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundException("Account not found")
    user.is_verified = True
    return await _issue_auth(db, user, ip_address=ip_address, user_agent=user_agent)


async def _get_active_session(db: AsyncSession, token: str) -> UserSession | None:
    token_hash = hash_token(token)
    result = await db.execute(
        select(UserSession).where(
            UserSession.token_hash == token_hash,
            UserSession.revoked_at.is_(None),
            UserSession.expires_at > datetime.now(timezone.utc),
        )
    )
    return result.scalar_one_or_none()


async def get_current_user(
    db: AsyncSession,
    token: str,
    *,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> User:
    payload = decode_access_token(token)
    if not payload:
        raise UnauthorizedException("Invalid or expired session")
    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Invalid session")

    # New tokens carry sid and require a DB session. Legacy tokens are accepted
    # for compatibility; revocation is immediate for new sessions.
    if payload.get("sid"):
        session = await _get_active_session(db, token)
        if not session or str(session.user_id) != str(user_id):
            raise UnauthorizedException("Session has expired or been revoked")
        session.last_seen_at = datetime.now(timezone.utc)

    result = await db.execute(select(User).where(User.id == UUID(str(user_id))))
    user = result.scalar_one_or_none()
    if not user:
        raise UnauthorizedException("Account not found")
    if not user.is_active:
        raise ForbiddenException("Account has been deactivated")
    return user


async def get_current_user_from_session_id(
    db: AsyncSession,
    token: str,
    **kwargs,
) -> User:
    return await get_current_user(db, token, **kwargs)


async def revoke_token(db: AsyncSession, token: str | None) -> None:
    if not token:
        return
    payload = decode_access_token(token) or {}
    await db.execute(
        update(UserSession)
        .where(UserSession.token_hash == hash_token(token), UserSession.revoked_at.is_(None))
        .values(revoked_at=datetime.now(timezone.utc))
    )
    # Legacy fallback: if token had no DB session, nothing to revoke server-side.
    logger.info("Session revoke requested", extra={"has_sid": bool(payload.get("sid"))})


async def revoke_all_user_sessions(db: AsyncSession, user_id: UUID) -> None:
    await db.execute(
        update(UserSession)
        .where(UserSession.user_id == user_id, UserSession.revoked_at.is_(None))
        .values(revoked_at=datetime.now(timezone.utc))
    )
