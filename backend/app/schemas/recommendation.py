from pydantic import BaseModel


class RecommendationItem(BaseModel):
    type: str
    priority: str
    title: str
    message: str
    action: str
    reason: str


class RecommendationResponse(BaseModel):
    uni_id: str
    student_name: str
    overall_status: str
    recommendations: list[RecommendationItem]
