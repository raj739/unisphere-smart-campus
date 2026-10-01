from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PassportShareConsentCreate(BaseModel):
    recipient_name: str = Field(
        min_length=1,
        max_length=200,
    )

    recipient_email: str | None = Field(
        default=None,
        max_length=255,
    )

    purpose: str = Field(
        min_length=1,
        max_length=500,
    )

    scope: str = Field(
        default="identity,academic",
        min_length=1,
        max_length=1000,
    )

    expires_at: datetime | None = None


class PassportShareConsentResponse(BaseModel):
    id: int
    passport_id: int
    share_token: str
    recipient_name: str
    recipient_email: str | None
    purpose: str
    scope: str
    status: str
    expires_at: datetime | None
    created_at: datetime
    revoked_at: datetime | None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class PassportShareVerifyResponse(BaseModel):
    valid: bool
    status: str | None = None
    recipient_name: str | None = None
    purpose: str | None = None
    scope: list[str] = []
    expires_at: datetime | None = None

    passport_number: str | None = None
    full_name: str | None = None
    uni_id: str | None = None
    programme: str | None = None
    academic_session: str | None = None
