from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AuditLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int | None
    action: str
    module: str
    entity_type: str | None
    entity_id: str | None
    description: str | None
    ip_address: str | None
    user_agent: str | None
    metadata_json: dict | None
    success: bool
    created_at: datetime


class AuditLogListResponse(BaseModel):
    items: list[AuditLogResponse]
    total: int
    limit: int
    offset: int
