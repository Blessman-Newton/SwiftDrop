from abc import ABC, abstractmethod


class PaymentProvider(ABC):
    @abstractmethod
    async def initialize_transaction(
        self, email: str, amount: float, currency: str, metadata: dict | None = None
    ) -> dict:
        pass

    @abstractmethod
    async def verify_transaction(self, reference: str) -> dict:
        pass

    @abstractmethod
    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        pass
