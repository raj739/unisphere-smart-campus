from pydantic import BaseModel


class InterventionCreateRequest(BaseModel):
    uni_id: str
    intervention_type: str
    assigned_to: str | None = None
    priority: str = "Medium"
    reason: str | None = None
    due_date: str | None = None


class InterventionStatusUpdate(BaseModel):
    status: str


class InterventionResponse(BaseModel):
    id: int
    uni_id: str
    student_name: str
    intervention_type: str
    assigned_to: str | None
    priority: str
    reason: str | None
    due_date: str | None
    status: str
    created_date: str
