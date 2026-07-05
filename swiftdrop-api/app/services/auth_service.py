import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException, UnauthorizedException
from app.core.security import create_access_token, decode_access_token, generate_otp, hash_password, verify_password
from app.models.restaurant import Restaurant
from app.models.user import OTPCode, RiderProfile, User
from app.schemas.auth import TokenResponse, UserResponse
from app.services.sms_service import send_otp_sms


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
    )


def _create_token(user: User) -> str:
    return create_access_token(data={"sub": str(user.id), "role": user.role})


async def sign_up(
    db: AsyncSession,
    email: str,
    password: str,
    phone: str,
    name: str | None = None,
    role: str = "customer",
) -> TokenResponse:
    phone = _normalize_phone(phone)
    email = email.strip().lower()

    existing_phone = await db.execute(select(User).where(User.phone == phone))
    if existing_phone.scalar_one_or_none():
        raise BadRequestException("Phone number already registered. Please log in.")

    existing_email = await db.execute(select(User).where(User.email == email))
    if existing_email.scalar_one_or_none():
        raise BadRequestException("Email already registered. Please log in.")

    user = User(
        phone=phone,
        email=email,
        password_hash=hash_password(password),
        name=name,
        role=role,
        is_verified=True,
    )
    db.add(user)
    await db.flush()

    if role == "rider":
        rider_profile = RiderProfile(user_id=user.id)
        db.add(rider_profile)
    elif role == "merchant":
        slug = f"restaurant-{str(user.id)[:8]}"
        restaurant = Restaurant(
            name=f"Restaurant {phone[-4:]}",
            slug=slug,
            address="Accra, Ghana",
            owner_id=user.id,
            is_active=True,
        )
        db.add(restaurant)

    await db.flush()

    token = _create_token(user)
    return TokenResponse(access_token=token, user=_user_to_response(user))


async def login_with_email(db: AsyncSession, email: str, password: str) -> TokenResponse:
    email = email.strip().lower()

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedException("Invalid email or password")

    if not verify_password(password, user.password_hash):
        raise UnauthorizedException("Invalid email or password")

    if not user.is_active:
        raise ForbiddenException("Account has been deactivated. Contact admin.")

    token = _create_token(user)
    return TokenResponse(access_token=token, user=_user_to_response(user))


async def send_otp(db: AsyncSession, phone: str) -> dict:
    phone = _normalize_phone(phone)

    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundException("Account not found. Please sign up.")

    otp_count = await db.execute(
        select(func.count()).select_from(OTPCode).where(
            OTPCode.phone == phone,
            OTPCode.used == False,
            OTPCode.created_at > datetime.now(timezone.utc) - timedelta(days=1),
        )
    )
    if otp_count.scalar() >= 5:
        raise BadRequestException("OTP limit reached. Please try again tomorrow.")

    code = generate_otp()
    otp = OTPCode(
        phone=phone,
        code=code,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
    )
    db.add(otp)
    await db.flush()

    sent, error_msg = await asyncio.to_thread(send_otp_sms, phone, code)
    if not sent:
        print(f"[AUTH] SMS failed for {phone}: {error_msg}")
        raise BadRequestException(f"Failed to send OTP: {error_msg}")

    return {"message": "OTP sent successfully", "phone": phone, "code": code}


async def verify_otp(
    db: AsyncSession, phone: str, code: str
) -> TokenResponse:
    phone = _normalize_phone(phone)

    result = await db.execute(
        select(OTPCode)
        .where(
            OTPCode.phone == phone,
            OTPCode.code == code,
            OTPCode.used == False,
            OTPCode.expires_at > datetime.now(timezone.utc),
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    otp = result.scalar_one_or_none()

    if not otp:
        raise BadRequestException("Invalid or expired OTP code")

    otp.used = True

    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()

    if not user:
        raise NotFoundException("Account not found. Please sign up.")

    user.is_verified = True

    token = _create_token(user)
    return TokenResponse(access_token=token, user=_user_to_response(user))


async def get_current_user(db: AsyncSession, token: str) -> User:
    payload = decode_access_token(token)
    if not payload:
        raise UnauthorizedException("Invalid token")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Invalid token")

    result = await db.execute(select(User).where(User.id == UUID(user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise NotFoundException("User not found")

    if not user.is_active:
        raise ForbiddenException("Account has been deactivated. Contact admin.")

    return user
