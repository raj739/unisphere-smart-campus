from typing import Any

from pydantic import BaseModel, Field


class StudentNotificationRequest(BaseModel):
    uni_id: str = Field(min_length=1, max_length=100)
    title: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=2000)
    notification_type: str = Field(
        default="general",
        max_length=100,
    )
    data: dict[str, Any] = Field(default_factory=dict)


class AdminNotificationRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=2000)
    notification_type: str = Field(
        default="system",
        max_length=100,
    )
    data: dict[str, Any] = Field(default_factory=dict)
