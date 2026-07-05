from twilio.rest import Client as TwilioClient
from app.config import get_settings

settings = get_settings()


def _get_client() -> TwilioClient | None:
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        print(f"[SMS] Missing Twilio credentials - SID: {bool(settings.TWILIO_ACCOUNT_SID)}, Token: {bool(settings.TWILIO_AUTH_TOKEN)}")
        return None
    try:
        client = TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        # Test the connection
        client.api.accounts(settings.TWILIO_ACCOUNT_SID).fetch()
        return client
    except Exception as e:
        print(f"[SMS] Twilio auth failed: {e}")
        return None


def send_sms(phone: str, message: str) -> tuple[bool, str]:
    # Dev mode: always log to console
    if settings.APP_ENV == "development":
        print(f"\n{'='*50}")
        print(f"[SMS DEV] To: {phone}")
        print(f"[SMS DEV] Message: {message}")
        print(f"{'='*50}\n")
        return True, "Dev mode - logged to console"

    client = _get_client()
    if not client:
        error_msg = "No Twilio client available - credentials missing or invalid"
        print(f"[SMS ERROR] {error_msg}")
        return False, error_msg
    
    try:
        # Ensure phone number has country code
        if not phone.startswith("+"):
            phone = f"+{phone}"
        
        print(f"[SMS] Sending to {phone} from {settings.TWILIO_FROM_NUMBER}")
        
        msg = client.messages.create(
            body=message,
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone,
        )
        print(f"[SMS] Sent successfully - SID: {msg.sid}")
        return True, f"Message sent - SID: {msg.sid}"
    except Exception as e:
        error_msg = f"{type(e).__name__}: {str(e)}"
        print(f"[SMS ERROR] {error_msg}")
        return False, error_msg


def send_otp_sms(phone: str, code: str) -> tuple[bool, str]:
    message = f"Your SwiftDrop verification code is {code}. Valid for 5 minutes. Do not share this code."
    return send_sms(phone, message)
