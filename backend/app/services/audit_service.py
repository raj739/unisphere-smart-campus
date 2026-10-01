from typing import Any

from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog


class AuditService:

    @staticmethod
    def log(
        db: Session,
        *,
        user_id: int | None,
        action: str,
        module: str,
        entity_type: str | None = None,
        entity_id: str | None = None,
        description: str | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
        metadata: dict[str, Any] | None = None,
        success: bool = True,
    ) -> AuditLog:

        event = AuditLog(
            user_id=user_id,
            action=action,
            module=module,
            entity_type=entity_type,
            entity_id=entity_id,
            description=description,
            ip_address=ip_address,
            user_agent=user_agent,
            metadata_json=metadata,
            success=success,
        )

        db.add(event)
        db.commit()
        db.refresh(event)

        return event
