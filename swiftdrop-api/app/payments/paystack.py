import hashlib
import hmac
import httpx

from app.config import get_settings
from app.payments.base import PaymentProvider

settings = get_settings()


class PaystackProvider(PaymentProvider):
    def __init__(self):
        self.secret_key = settings.PAYSTACK_SECRET_KEY
        self.base_url = settings.PAYSTACK_BASE_URL
        self.headers = {
            "Authorization": f"Bearer {self.secret_key}",
            "Content-Type": "application/json",
        }

    async def initialize_transaction(
        self, email: str, amount: float, currency: str = "GHS", metadata: dict | None = None, reference: str | None = None
    ) -> dict:
        payload = {
            "email": email,
            "amount": int(amount * 100),
            "currency": currency,
            "metadata": metadata or {},
        }
        if reference:
            payload["reference"] = reference

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/transaction/initialize",
                json=payload,
                headers=self.headers,
                timeout=30.0,
            )
            result = response.json()
            if not result.get("status"):
                raise Exception(result.get("message", "Paystack initialization failed"))
            return result["data"]

    async def verify_transaction(self, reference: str) -> dict:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/transaction/verify/{reference}",
                headers=self.headers,
                timeout=30.0,
            )
            result = response.json()
            if not result.get("status"):
                raise Exception(result.get("message", "Payment verification failed"))
            return result["data"]

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        expected = hmac.new(
            self.secret_key.encode("utf-8"), payload, hashlib.sha512
        ).hexdigest()
        return hmac.compare_digest(expected, signature)


paystack_provider = PaystackProvider()
