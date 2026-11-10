import logging

from twilio.rest import Client as TwilioClient

from app.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


def _get_client() -> TwilioClient | None:
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        logger.warning("SMS provider credentials are not configured")
        return None
    return TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)


def send_sms(phone: str, message: str) -> tuple[bool, str]:
    if settings.APP_ENV == "development":
        logger.info("[SMS DEV] message queued for %s", phone[-4:].rjust(len(phone), "*"))
        return True, "Development mode"

    client = _get_client()
    if not client:
        return False, "SMS provider unavailable"
    try:
        if not phone.startswith("+"):
            phone = f"+{phone}"
        client.messages.create(body=message, from_=settings.TWILIO_FROM_NUMBER, to=phone)
        return True, "Message sent"
    except Exception:
        logger.exception("SMS send failed")
        return False, "SMS provider error"


def send_otp_sms(phone: str, code: str) -> tuple[bool, str]:
    message = f"Your Doorush verification code is {code}. Valid for 5 minutes. Do not share this code."
    return send_sms(phone, message)
