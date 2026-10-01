from sqlalchemy.orm import Session

from app.models.notification_v2 import NotificationV2
from app.models.notification_preference_v2 import NotificationPreferenceV2
from app.models.notification_delivery_v2 import NotificationDeliveryV2


CATEGORY_PREFERENCE_MAP = {
    "academic": "academic_enabled",
    "fee": "fee_enabled",
    "examination": "examination_enabled",
    "service": "service_enabled",
    "system": "system_enabled",
}


def get_or_create_preferences(
    db: Session,
    user_id: int,
):
    preferences = (
        db.query(NotificationPreferenceV2)
        .filter(NotificationPreferenceV2.user_id == user_id)
        .first()
    )

    if preferences is None:
        preferences = NotificationPreferenceV2(
            user_id=user_id
        )
        db.add(preferences)
        db.flush()

    return preferences


def create_notification(
    db: Session,
    recipient_user_id: int,
    category: str,
    title: str,
    message: str,
    priority: str = "normal",
    entity_type: str | None = None,
    entity_id: int | None = None,
):
    preferences = get_or_create_preferences(
        db,
        recipient_user_id,
    )

    category_setting = CATEGORY_PREFERENCE_MAP.get(
        category,
        "system_enabled",
    )

    if not preferences.in_app_enabled:
        return None

    if not getattr(preferences, category_setting):
        return None

    notification = NotificationV2(
        recipient_user_id=recipient_user_id,
        category=category,
        title=title,
        message=message,
        priority=priority,
        entity_type=entity_type,
        entity_id=entity_id,
    )

    db.add(notification)
    db.flush()

    delivery = NotificationDeliveryV2(
        notification_id=notification.id,
        channel="in_app",
        status="delivered",
        provider="unisphere",
    )

    db.add(delivery)

    return notification
