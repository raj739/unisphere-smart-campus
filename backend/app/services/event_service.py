from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from app.services.realtime_manager import realtime_manager


class EventService:

    @staticmethod
    def student_channel(uni_id: str) -> str:
        return f"student:{uni_id}"

    @staticmethod
    def parent_channel(uni_id: str) -> str:
        return f"parent:{uni_id}"

    @staticmethod
    def admin_channel() -> str:
        return "admin"

    @staticmethod
    async def publish(
        *,
        channel: str,
        event: str,
        data: dict[str, Any] | None = None,
    ) -> None:
        await realtime_manager.send_to_channel(
            channel,
            {
                "event": event,
                "channel": channel,
                "data": data or {},
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

    @staticmethod
    async def student_notification(
        *,
        uni_id: str,
        title: str,
        message: str,
        notification_type: str = "general",
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="notification.created",
            data={
                "title": title,
                "message": message,
                "type": notification_type,
                "data": data or {},
            },
        )

    @staticmethod
    async def parent_notification(
        *,
        uni_id: str,
        title: str,
        message: str,
        notification_type: str = "general",
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.parent_channel(uni_id),
            event="notification.created",
            data={
                "title": title,
                "message": message,
                "type": notification_type,
                "data": data or {},
            },
        )

    @staticmethod
    async def admin_notification(
        *,
        title: str,
        message: str,
        notification_type: str = "system",
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.admin_channel(),
            event="notification.created",
            data={
                "title": title,
                "message": message,
                "type": notification_type,
                "data": data or {},
            },
        )

    @staticmethod
    async def academic_update(
        *,
        uni_id: str,
        message: str,
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="academic.updated",
            data={
                "message": message,
                **(data or {}),
            },
        )

    @staticmethod
    async def attendance_update(
        *,
        uni_id: str,
        attendance_percentage: float,
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="attendance.updated",
            data={
                "attendance_percentage": attendance_percentage,
                **(data or {}),
            },
        )

    @staticmethod
    async def fee_update(
        *,
        uni_id: str,
        outstanding_amount: float,
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="fees.updated",
            data={
                "outstanding_amount": outstanding_amount,
                **(data or {}),
            },
        )

    @staticmethod
    async def intervention_update(
        *,
        uni_id: str,
        intervention_id: int,
        status: str,
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="intervention.updated",
            data={
                "intervention_id": intervention_id,
                "status": status,
                **(data or {}),
            },
        )

    @staticmethod
    async def risk_update(
        *,
        uni_id: str,
        risk_level: str,
        risk_score: float,
        data: dict[str, Any] | None = None,
    ) -> None:
        await EventService.publish(
            channel=EventService.student_channel(uni_id),
            event="risk.updated",
            data={
                "risk_level": risk_level,
                "risk_score": risk_score,
                **(data or {}),
            },
        )
