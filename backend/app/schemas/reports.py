from __future__ import annotations

from pydantic import BaseModel, Field


class ReportRequest(BaseModel):
    title: str = Field(
        default="UniSphere Report",
        min_length=1,
        max_length=200,
    )

    rows: list[dict[str, object]] = Field(
        default_factory=list,
        max_length=5000,
    )

    metadata: dict[str, object] = Field(
        default_factory=dict,
    )