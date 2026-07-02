from pydantic import BaseModel, Field


class InitializePaymentRequest(BaseModel):
    order_id: str
    email: str = Field(..., examples=["customer@example.com"])
    amount: float = Field(..., gt=0)
    currency: str = Field("GHS", pattern=r"^[A-Z]{3}$")


class InitializePaymentResponse(BaseModel):
    authorization_url: str
    access_code: str
    reference: str


class PaymentWebhookData(BaseModel):
    reference: str
    amount: int
    currency: str
    status: str
    gateway_response: str | None = None
    metadata: dict | None = None


class PaymentWebhookEvent(BaseModel):
    event: str
    data: PaymentWebhookData


class PaymentVerifyResponse(BaseModel):
    reference: str
    status: str
    amount: float
    currency: str
    gateway_response: str | None = None
