from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role

from app.models.user import User
from app.models.notification_template_v2 import NotificationTemplateV2
from app.models.notification_v2 import NotificationV2
from app.models.notification_preference_v2 import NotificationPreferenceV2
from app.models.notification_delivery_v2 import NotificationDeliveryV2

from app.schemas.notification_v2 import (
    NotificationTemplateCreateRequest,
    NotificationTemplateResponse,
    NotificationCreateRequest,
    NotificationResponse,
    NotificationPreferenceUpdateRequest,
    NotificationPreferenceResponse,
    NotificationBroadcastRequest,
    NotificationDeliveryResponse,
)

from app.services.notification_service import (
    get_or_create_preferences,
    create_notification,
)

router = APIRouter(
    prefix="/notifications-v2",
    tags=["Notifications V2"],
)

ALLOWED_PRIORITIES = {
    "low",
    "normal",
    "high",
    "urgent",
}


@router.post(
    "/templates",
    response_model=NotificationTemplateResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_template(
    request: NotificationTemplateCreateRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(NotificationTemplateV2)
        .filter(
            NotificationTemplateV2.code == request.code
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Notification template code already exists",
        )

    if request.default_priority not in ALLOWED_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid notification priority",
        )

    template = NotificationTemplateV2(
        **request.model_dump()
    )

    db.add(template)
    db.commit()
    db.refresh(template)

    return template


@router.get(
    "/templates",
    response_model=list[NotificationTemplateResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_templates(
    db: Session = Depends(get_db),
):
    return (
        db.query(NotificationTemplateV2)
        .filter(NotificationTemplateV2.is_active == True)
        .order_by(NotificationTemplateV2.code)
        .all()
    )


@router.post(
    "/send",
    response_model=NotificationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def send_notification(
    request: NotificationCreateRequest,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(
            User.id == request.recipient_user_id,
            User.is_active == True,
        )
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient user not found",
        )

    if request.priority not in ALLOWED_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid notification priority",
        )

    notification = create_notification(
        db=db,
        recipient_user_id=request.recipient_user_id,
        category=request.category,
        title=request.title,
        message=request.message,
        priority=request.priority,
        entity_type=request.entity_type,
        entity_id=request.entity_id,
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Notification disabled by recipient preferences",
        )

    db.commit()
    db.refresh(notification)

    return notification


@router.post(
    "/broadcast",
    response_model=list[NotificationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def broadcast_notification(
    request: NotificationBroadcastRequest,
    db: Session = Depends(get_db),
):
    if request.priority not in ALLOWED_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid notification priority",
        )

    users = (
        db.query(User)
        .filter(
            User.id.in_(request.recipient_user_ids),
            User.is_active == True,
        )
        .all()
    )

    notifications = []

    for user in users:
        notification = create_notification(
            db=db,
            recipient_user_id=user.id,
            category=request.category,
            title=request.title,
            message=request.message,
            priority=request.priority,
        )

        if notification is not None:
            notifications.append(notification)

    db.commit()

    for notification in notifications:
        db.refresh(notification)

    return notifications


@router.get(
    "/me",
    response_model=list[NotificationResponse],
)
def my_notifications(
    unread_only: bool = False,
    category: str | None = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = (
        db.query(NotificationV2)
        .filter(
            NotificationV2.recipient_user_id == current_user.id
        )
    )

    if unread_only:
        query = query.filter(
            NotificationV2.is_read == False
        )

    if category:
        query = query.filter(
            NotificationV2.category == category
        )

    return query.order_by(
        NotificationV2.created_at.desc()
    ).all()


@router.get(
    "/me/unread-count",
)
def unread_count(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    count = (
        db.query(NotificationV2)
        .filter(
            NotificationV2.recipient_user_id == current_user.id,
            NotificationV2.is_read == False,
        )
        .count()
    )

    return {
        "unread_count": count
    }


@router.patch(
    "/{notification_id}/read",
    response_model=NotificationResponse,
)
def mark_read(
    notification_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = (
        db.query(NotificationV2)
        .filter(
            NotificationV2.id == notification_id,
            NotificationV2.recipient_user_id == current_user.id,
        )
        .first()
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    notification.is_read = True
    notification.read_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(notification)

    return notification


@router.patch(
    "/me/read-all",
)
def mark_all_read(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notifications = (
        db.query(NotificationV2)
        .filter(
            NotificationV2.recipient_user_id == current_user.id,
            NotificationV2.is_read == False,
        )
        .all()
    )

    now = datetime.now(timezone.utc)

    for notification in notifications:
        notification.is_read = True
        notification.read_at = now

    db.commit()

    return {
        "marked_read": len(notifications)
    }


@router.get(
    "/preferences",
    response_model=NotificationPreferenceResponse,
)
def get_preferences(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_or_create_preferences(
        db,
        current_user.id,
    )


@router.patch(
    "/preferences",
    response_model=NotificationPreferenceResponse,
)
def update_preferences(
    request: NotificationPreferenceUpdateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    preferences = get_or_create_preferences(
        db,
        current_user.id,
    )

    values = request.model_dump(exclude_none=True)

    for key, value in values.items():
        setattr(preferences, key, value)

    db.commit()
    db.refresh(preferences)

    return preferences


@router.get(
    "/{notification_id}/deliveries",
    response_model=list[NotificationDeliveryResponse],
)
def notification_deliveries(
    notification_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = (
        db.query(NotificationV2)
        .filter(
            NotificationV2.id == notification_id,
            NotificationV2.recipient_user_id == current_user.id,
        )
        .first()
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    return (
        db.query(NotificationDeliveryV2)
        .filter(
            NotificationDeliveryV2.notification_id == notification_id
        )
        .order_by(NotificationDeliveryV2.created_at.desc())
        .all()
    )


@router.get(
    "/admin/deliveries",
    response_model=list[NotificationDeliveryResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_deliveries(
    delivery_status: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(NotificationDeliveryV2)

    if delivery_status:
        query = query.filter(
            NotificationDeliveryV2.status == delivery_status
        )

    return query.order_by(
        NotificationDeliveryV2.created_at.desc()
    ).all()
