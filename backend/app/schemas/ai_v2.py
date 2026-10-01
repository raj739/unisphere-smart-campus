from pydantic import BaseModel, Field


class AIChatRequestV2(BaseModel):
    message: str = Field(min_length=1, max_length=5000)
    session_id: str | None = Field(default=None, max_length=150)
    language: str = Field(default="auto", pattern="^(auto|en|hi)$")


class AIContextResponse(BaseModel):
    uni_id: str | None
    student_name: str | None
    programme: str | None
    semester: int | None
    attendance_percentage: float | None
    outstanding_fee: float | None
    academic_status: str | None


class AIChatResponseV2(BaseModel):
    answer: str
    session_id: str
    context: AIContextResponse
    model: str | None
    interaction_id: int
    source: str = "external_provider"
    detected_language: str = "en"
    suggestions: list[str] = Field(default_factory=list)
