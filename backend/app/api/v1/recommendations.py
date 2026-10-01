from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.student import Student
from app.models.user import User
from app.schemas.recommendation import RecommendationResponse
from app.services.recommendation_service import generate_recommendations


router = APIRouter(
    prefix="/recommendations",
    tags=["AI Recommendations"],
)


@router.get(
    "/me",
    response_model=RecommendationResponse,
)
def get_my_recommendations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        return {
            "uni_id": "",
            "student_name": current_user.email,
            "overall_status": "Unavailable",
            "recommendations": [],
        }

    return generate_recommendations(
        student=student,
        db=db,
    )
