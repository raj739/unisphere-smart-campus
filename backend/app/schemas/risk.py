from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class RiskCalculateRequest(BaseModel):
    attendance: float = Field(default=0.0, ge=0.0, le=100.0)
    academic_percentage: float = Field(
        default=0.0,
        ge=0.0,
        le=100.0,
    )
    fee_due: float = Field(default=0.0, ge=0.0)
    engagement: float = Field(default=100.0, ge=0.0, le=100.0)


class RiskAssessmentResponse(BaseModel):
    id: int
    student_id: int
    risk_score: float
    risk_level: str
    attendance_score: float
    academic_score: float
    fee_score: float
    engagement_score: float
    explanation: str
    recommended_action: str
    calculated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PredictiveStudentResponse(BaseModel):
    assessment_id: int
    student_id: int
    uni_id: str
    student_name: str
    programme: str
    risk_score: float
    risk_level: str
    predicted_performance: str
    dropout_probability: float | None
    attendance_percentage: float | None
    academic_percentage: float | None
    outstanding_fees: float
    engagement_percentage: float | None
    attendance_records: int
    result_count: int
    data_confidence: str
    explanation: str
    recommended_action: str
    calculated_at: datetime


class PredictiveRunResponse(BaseModel):
    students_evaluated: int
    high_risk: int
    medium_risk: int
    low_risk: int
    insufficient_data: int
    warnings_created: int
    active_warnings: int
    assessments: list[PredictiveStudentResponse]
