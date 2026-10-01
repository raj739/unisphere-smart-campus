from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class InterventionCreateV2(BaseModel):
    uni_id: str = Field(min_length=1, max_length=100)
    intervention_type: str = Field(min_length=1, max_length=100)
    assigned_to: str | None = Field(default=None, max_length=150)
    priority: str = Field(default="Medium", max_length=30)
    reason: str | None = Field(default=None, max_length=2000)
    due_date: date | None = None
    warning_id: int | None = None


class InterventionStatusUpdateV2(BaseModel):
    status: str = Field(min_length=1, max_length=50)
    assigned_to: str | None = Field(default=None, max_length=150)
    due_date: date | None = None
    notes: str | None = Field(default=None, max_length=4000)
    outcome: str | None = Field(default=None, max_length=4000)


class InterventionResponseV2(BaseModel):
    id: int
    warning_id: int | None
    uni_id: str
    student_name: str
    programme: str
    warning_title: str | None
    intervention_type: str
    assigned_to: str | None
    priority: str
    reason: str | None
    notes: str | None
    outcome: str | None
    due_date: date | None
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
