import json
import logging
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials, messaging

from app.config import get_settings

logger = logging.getLogger(__name__)

_firebase_app = None


def initialize_firebase():
    global _firebase_app
    if _firebase_app:
        return _firebase_app

    settings = get_settings()

    if settings.FIREBASE_CREDENTIALS_PATH and Path(settings.FIREBASE_CREDENTIALS_PATH).exists():
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    elif settings.FIREBASE_CREDENTIALS_JSON:
        cred = credentials.Certificate(json.loads(settings.FIREBASE_CREDENTIALS_JSON))
    else:
        logger.warning("Firebase credentials not configured. FCM and Firebase Auth verification disabled.")
        return None

    _firebase_app = firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialized successfully")
    return _firebase_app


def verify_firebase_id_token(id_token: str) -> dict | None:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return None
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except auth.InvalidIdTokenError:
        return None
    except auth.ExpiredIdTokenError:
        return None
    except Exception as e:
        logger.error(f"Firebase token verification error: {e}")
        return None


def create_custom_token(uid: str, additional_claims: dict | None = None) -> str | None:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return None
    try:
        return auth.create_custom_token(uid, additional_claims)
    except Exception as e:
        logger.error(f"Failed to create custom token: {e}")
        return None


def get_firebase_user(uid: str) -> dict | None:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return None
    try:
        user = auth.get_user(uid)
        return {
            "uid": user.uid,
            "email": user.email,
            "display_name": user.display_name,
            "photo_url": user.photo_url,
            "phone_number": user.phone_number,
            "email_verified": user.email_verified,
        }
    except auth.UserNotFoundError:
        return None
    except Exception as e:
        logger.error(f"Failed to get Firebase user: {e}")
        return None


def send_fcm_notification(
    token: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> bool:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="doorush_default",
                    sound="default",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default", badge=1),
                ),
            ),
        )
        response = messaging.send(message)
        logger.info(f"FCM sent successfully: {response}")
        return True
    except messaging.UnregisteredError:
        logger.warning(f"FCM token unregistered: {token[:20]}...")
        return False
    except messaging.SenderIdMismatchError:
        logger.warning(f"FCM sender ID mismatch for token: {token[:20]}...")
        return False
    except Exception as e:
        logger.error(f"FCM send failed: {e}")
        return False


def send_fcm_to_topic(
    topic: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> bool:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            topic=topic,
        )
        response = messaging.send(message)
        logger.info(f"FCM topic message sent: {response}")
        return True
    except Exception as e:
        logger.error(f"FCM topic send failed: {e}")
        return False


def subscribe_to_topic(tokens: list[str], topic: str) -> bool:
    if not _firebase_app:
        initialize_firebase()
    if not _firebase_app:
        return False
    try:
        response = messaging.subscribe_to_topic(tokens, topic)
        logger.info(f"Subscribed {response.success_count} tokens to {topic}")
        return response.success_count > 0
    except Exception as e:
        logger.error(f"Topic subscription failed: {e}")
        return False
