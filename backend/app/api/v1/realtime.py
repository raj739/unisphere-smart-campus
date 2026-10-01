from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token, get_current_user
from app.models.student import Student
from app.models.user import User
from app.schemas.realtime import RealtimePublishRequest
from app.services.realtime_manager import realtime_manager

router = APIRouter(prefix="/realtime", tags=["Realtime"])


def _is_admin(user) -> bool:
    role = str(getattr(user, "role", "") or "").lower()

    return role in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }


def get_websocket_user(websocket: WebSocket, db: Session) -> User | None:
    token = websocket.query_params.get("token")
    if not token:
        auth_header = websocket.headers.get("authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
    if not token:
        sec_protocol = websocket.headers.get("sec-websocket-protocol", "")
        if sec_protocol:
            token = sec_protocol.split(",")[0].strip()

    if not token:
        return None

    payload = decode_access_token(token)
    if not payload:
        return None

    user_id = payload.get("sub")
    if not user_id:
        return None

    try:
        user_id_int = int(user_id)
    except (ValueError, TypeError):
        return None

    user = db.query(User).filter(User.id == user_id_int).first()
    if not user or not user.is_active:
        return None

    return user


def is_channel_authorized(user: User, channel: str, db: Session) -> bool:
    channel_clean = channel.lower().strip()
    if channel_clean in {"global", "public", "announcements", "general"}:
        return True

    if _is_admin(user):
        return True

    if channel_clean.startswith("admin") or channel_clean.startswith("system"):
        return _is_admin(user)

    if channel_clean.startswith("student:") or channel_clean.startswith("student_"):
        raw_id = channel_clean.replace("student:", "").replace("student_", "")
        student = db.query(Student).filter(Student.uni_id == raw_id).first()
        if not student:
            try:
                target_student_id = int(raw_id)
                student = db.query(Student).filter(Student.id == target_student_id).first()
            except ValueError:
                return False

        if not student:
            return False

        if user.role == "student" and student.user_id == user.id:
            return True

        if user.role == "parent":
            from app.models.parent_student import ParentStudentLink
            from app.models.parent_student_link_v2 import ParentStudentLinkV2

            link_v2 = (
                db.query(ParentStudentLinkV2)
                .filter(
                    ParentStudentLinkV2.parent_user_id == user.id,
                    ParentStudentLinkV2.student_id == student.id,
                    ParentStudentLinkV2.is_active.is_(True),
                )
                .first()
            )
            if link_v2:
                return True

            link_v1 = (
                db.query(ParentStudentLink)
                .filter(
                    ParentStudentLink.parent_user_id == user.id,
                    ParentStudentLink.student_id == student.id,
                )
                .first()
            )
            if link_v1:
                return True

        return False

    if channel_clean.startswith("user:") or channel_clean.startswith("user_"):
        raw_id = channel_clean.replace("user:", "").replace("user_", "")
        try:
            return user.id == int(raw_id)
        except ValueError:
            return False

    if channel_clean == f"{user.role}s" or channel_clean == user.role:
        return True

    return False


@router.websocket("/ws/{channel}")
async def realtime_websocket(
    websocket: WebSocket,
    channel: str,
    db: Session = Depends(get_db),
):
    normalized_channel = channel.strip()

    if not normalized_channel:
        await websocket.close(code=1008, reason="Invalid channel name")
        return

    user = get_websocket_user(websocket, db)
    if not user:
        await websocket.close(code=1008, reason="Unauthorized")
        return

    if not is_channel_authorized(user, normalized_channel, db):
        await websocket.close(code=1008, reason="Forbidden channel access")
        return

    await realtime_manager.connect(
        websocket,
        normalized_channel,
    )

    try:
        await websocket.send_json(
            {
                "event": "connection.established",
                "channel": normalized_channel,
                "data": {
                    "connected": True,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            }
        )

        while True:
            message = await websocket.receive_json()

            event = str(message.get("event", "")).strip()

            if event == "ping":
                await websocket.send_json(
                    {
                        "event": "pong",
                        "channel": normalized_channel,
                        "data": {
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                        },
                    }
                )
                continue

            if event == "subscribe":
                await websocket.send_json(
                    {
                        "event": "subscription.confirmed",
                        "channel": normalized_channel,
                        "data": {
                            "subscribed": True,
                        },
                    }
                )
                continue

            await websocket.send_json(
                {
                    "event": "message.received",
                    "channel": normalized_channel,
                    "data": {
                        "accepted": True,
                        "original_event": event,
                    },
                }
            )

    except WebSocketDisconnect:
        realtime_manager.disconnect(
            websocket,
            normalized_channel,
        )

    except Exception:
        realtime_manager.disconnect(
            websocket,
            normalized_channel,
        )


@router.post("/publish")
async def publish_realtime_event(
    request: RealtimePublishRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    message = {
        "event": request.event,
        "channel": request.channel,
        "data": request.data,
        "published_by": current_user.id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    await realtime_manager.send_to_channel(
        request.channel,
        message,
    )

    return {
        "success": True,
        "channel": request.channel,
        "event": request.event,
        "connections": realtime_manager.connection_count(
            request.channel,
        ),
    }


@router.get("/status")
def realtime_status(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    return {
        "status": "online",
        "connections": realtime_manager.connection_count(),
    }
