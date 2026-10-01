from datetime import datetime

from pydantic import BaseModel, ConfigDict


class EarlyWarningResponse(BaseModel):
    id: int
    student_id: int
    uni_id: str | None = None
    student_name: str | None = None
    programme: str | None = None
    intervention_id: int | None = None
    risk_assessment_id: int | None
    warning_type: str
    severity: str
    title: str
    message: str
    trigger_value: str | None
    threshold_value: str | None
    recommended_action: str
    status: str
    is_active: bool
    created_at: datetime
    resolved_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class EarlyWarningGenerateRequest(BaseModel):
    attendance: float = 0.0
    academic_percentage: float = 0.0
    fee_due: float = 0.0
    engagement: float = 100.0
