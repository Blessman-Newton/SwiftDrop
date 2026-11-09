from pydantic import BaseModel, EmailStr, Field


class SendOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$", examples=["+233241234567"])


class VerifyOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$")
    code: str = Field(..., min_length=4, max_length=8, examples=["123456"])


class SignUpRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$", examples=["+233241234567"])
    name: str | None = Field(None, max_length=100)
    # Public self-registration is restricted server-side; "admin" is never accepted.
    role: str = Field("customer", pattern=r"^(customer|rider|merchant)$")


class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=128)
    firebase_uid: str | None = None
    id_token: str | None = None


class PhoneLoginRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$")
    password: str = Field(..., min_length=1, max_length=128)


class SocialLoginRequest(BaseModel):
    provider: str = Field(..., pattern=r"^(google|apple)$")
    id_token: str = Field(..., min_length=20)
    firebase_uid: str | None = None
    email: EmailStr | None = None
    name: str | None = Field(None, max_length=100)
    photo_url: str | None = Field(None, max_length=2048)


class UserResponse(BaseModel):
    id: str
    phone: str
    name: str | None = None
    email: str
    role: str
    avatar_url: str | None = None
    is_verified: bool = False
    onboarding_completed: bool = False
    wallet_balance: float = 0.0
    loyalty_points: int = 0
    membership_tier: str = "Bronze"

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    # Kept for mobile/bearer clients. Web admin/merchant use HttpOnly session cookies.
    access_token: str | None = None
    token_type: str = "bearer"
    user: UserResponse
    custom_token: str | None = None
    expires_in_minutes: int | None = None


class SendOTPResponse(BaseModel):
    message: str
    phone: str
    dev_code: str | None = None


class LogoutResponse(BaseModel):
    message: str = "Logged out"
