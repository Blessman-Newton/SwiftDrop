import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException, UnauthorizedException
from app.core.security import create_access_token, decode_access_token, generate_otp
from app.models.restaurant import Restaurant
from app.models.user import OTPCode, RiderProfile, User
from app.schemas.auth import TokenResponse, UserResponse
from app.services.sms_service import send_otp_sms


async def send_otp(db: AsyncSession, phone: str) -> dict:
    # Normalize phone number to international format
    original_phone = phone
    phone = phone.strip().replace(" ", "").replace("-", "")
    if phone.startswith("0"):
        phone = "+233" + phone[1:]  # Ghana country code
    elif phone.startswith("233") and not phone.startswith("+"):
        phone = "+" + phone
    elif not phone.startswith("+"):
        phone = "+" + phone
    
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
    db: AsyncSession, phone: str, code: str, name: str | None = None, role: str = "customer"
) -> TokenResponse:
    # Normalize phone number to international format
    phone = phone.strip().replace(" ", "").replace("-", "")
    if phone.startswith("0"):
        phone = "+233" + phone[1:]  # Ghana country code
    elif phone.startswith("233") and not phone.startswith("+"):
        phone = "+" + phone
    elif not phone.startswith("+"):
        phone = "+" + phone
    
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
        user = User(
            phone=phone,
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
    else:
        user.is_verified = True
        if name and not user.name:
            user.name = name

    token = create_access_token(data={"sub": str(user.id), "role": user.role})

    return TokenResponse(
        access_token=token,
        user=UserResponse(
            id=str(user.id),
            phone=user.phone,
            name=user.name,
            email=user.email,
            role=user.role,
            avatar_url=user.avatar_url,
            is_verified=user.is_verified,
        ),
    )


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
