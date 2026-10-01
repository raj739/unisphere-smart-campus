from datetime import datetime
from pydantic import BaseModel, Field


class NotificationTemplateCreateRequest(BaseModel):
    code: str = Field(min_length=2, max_length=100)
    title_template: str = Field(min_length=2, max_length=250)
    message_template: str = Field(min_length=2, max_length=10000)
    category: str = Field(min_length=2, max_length=100)
    default_priority: str = Field(default="normal", max_length=30)


class NotificationTemplateResponse(BaseModel):
    id: int
    code: str
    title_template: str
    message_template: str
    category: str
    default_priority: str
    is_active: bool


class NotificationCreateRequest(BaseModel):
    recipient_user_id: int
    category: str = Field(min_length=2, max_length=100)
    title: str = Field(min_length=2, max_length=250)
    message: str = Field(min_length=1, max_length=10000)
    priority: str = Field(default="normal", max_length=30)
    entity_type: str | None = Field(default=None, max_length=100)
    entity_id: int | None = None


class NotificationResponse(BaseModel):
    id: int
    recipient_user_id: int
    category: str
    title: str
    message: str
    priority: str
    entity_type: str | None
    entity_id: int | None
    is_read: bool
    read_at: datetime | None
    created_at: datetime
    expires_at: datetime | None


class NotificationPreferenceUpdateRequest(BaseModel):
    in_app_enabled: bool | None = None
    email_enabled: bool | None = None
    sms_enabled: bool | None = None
    push_enabled: bool | None = None
    academic_enabled: bool | None = None
    fee_enabled: bool | None = None
    examination_enabled: bool | None = None
    service_enabled: bool | None = None
    system_enabled: bool | None = None


class NotificationPreferenceResponse(BaseModel):
    id: int
    user_id: int
    in_app_enabled: bool
    email_enabled: bool
    sms_enabled: bool
    push_enabled: bool
    academic_enabled: bool
    fee_enabled: bool
    examination_enabled: bool
    service_enabled: bool
    system_enabled: bool


class NotificationBroadcastRequest(BaseModel):
    recipient_user_ids: list[int] = Field(min_length=1)
    category: str = Field(min_length=2, max_length=100)
    title: str = Field(min_length=2, max_length=250)
    message: str = Field(min_length=1, max_length=10000)
    priority: str = Field(default="normal", max_length=30)


class NotificationDeliveryResponse(BaseModel):
    id: int
    notification_id: int
    channel: str
    status: str
    provider: str | None
    provider_message_id: str | None
    error_message: str | None
    attempted_at: datetime | None
    created_at: datetime
