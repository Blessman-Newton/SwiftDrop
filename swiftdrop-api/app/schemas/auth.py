from pydantic import BaseModel, Field


class SendOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$", examples=["+233241234567"])


class VerifyOTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$")
    code: str = Field(..., min_length=6, max_length=6, examples=["123456"])
    name: str | None = Field(None, max_length=100)
    role: str = Field("customer", pattern=r"^(customer|rider|admin|merchant)$")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: str
    phone: str
    name: str | None = None
    email: str | None = None
    role: str
    avatar_url: str | None = None
    is_verified: bool = False

    model_config = {"from_attributes": True}


class SendOTPResponse(BaseModel):
    message: str
    phone: str
    dev_code: str | None = None
