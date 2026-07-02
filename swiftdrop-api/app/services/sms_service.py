from twilio.rest import Client as TwilioClient
from app.config import get_settings

settings = get_settings()


def _get_client() -> TwilioClient | None:
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        return None
    return TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)


def send_sms(phone: str, message: str) -> bool:
    # Dev mode: always log to console
    if settings.APP_ENV == "development":
        print(f"\n{'='*50}")
        print(f"[SMS DEV] To: {phone}")
        print(f"[SMS DEV] Message: {message}")
        print(f"{'='*50}\n")
        return True

    client = _get_client()
    if not client:
        print(f"[SMS MOCK] To: {phone} | Message: {message}")
        return True
    try:
        client.messages.create(
            body=message,
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone,
        )
        return True
    except Exception as e:
        print(f"[SMS ERROR] {e}")
        return False


def send_otp_sms(phone: str, code: str) -> bool:
    message = f"Your SwiftDrop verification code is {code}. Valid for 5 minutes. Do not share this code."
    return send_sms(phone, message)
