from fastapi import APIRouter, Depends, HTTPException

from app.core.security import get_current_user
from app.schemas.events import (
    AdminNotificationRequest,
    StudentNotificationRequest,
)
from app.services.event_service import EventService

router = APIRouter(prefix="/events", tags=["Events"])


def _is_admin(user) -> bool:
    role = str(getattr(user, "role", "") or "").lower()

    return role in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }


@router.post("/student-notification")
async def send_student_notification(
    request: StudentNotificationRequest,
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    await EventService.student_notification(
        uni_id=request.uni_id,
        title=request.title,
        message=request.message,
        notification_type=request.notification_type,
        data=request.data,
    )

    return {
        "success": True,
        "event": "notification.created",
        "channel": EventService.student_channel(
            request.uni_id,
        ),
    }


@router.post("/admin-notification")
async def send_admin_notification(
    request: AdminNotificationRequest,
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    await EventService.admin_notification(
        title=request.title,
        message=request.message,
        notification_type=request.notification_type,
        data=request.data,
    )

    return {
        "success": True,
        "event": "notification.created",
        "channel": EventService.admin_channel(),
    }
