from typing import Any

from pydantic import BaseModel, Field


class RealtimePublishRequest(BaseModel):
    channel: str = Field(min_length=1, max_length=150)
    event: str = Field(min_length=1, max_length=100)
    data: dict[str, Any] = Field(default_factory=dict)


class RealtimeMessage(BaseModel):
    event: str
    channel: str
    data: dict[str, Any] = Field(default_factory=dict)
