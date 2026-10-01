from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.student import Student
from app.models.transport import TransportAllocation
from app.models.transport_issue import TransportIssue
from app.models.user import User


router = APIRouter(
    prefix="/transport",
    tags=["Transport"],
)


def get_current_student(
    current_user: User,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


@router.get("")
def get_my_transport(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    allocation = (
        db.query(TransportAllocation)
        .filter(
            TransportAllocation.student_id == student.id
        )
        .order_by(TransportAllocation.id.desc())
        .first()
    )

    if allocation is None:
        return {
            "active": False,
            "message": "No transport allocation found",
        }

    return {
        "active": True,
        "id": allocation.id,
        "route_number": allocation.route_number,
        "bus_number": allocation.bus_number,
        "pass_status": allocation.pass_status,
        "driver_name": allocation.driver_name,
        "departure_time": allocation.departure_time,
        "university_arrival": allocation.university_arrival,
        "status": allocation.status,
    }


@router.get("/issues")
def get_my_transport_issues(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    issues = (
        db.query(TransportIssue)
        .filter(
            TransportIssue.student_id == student.id
        )
        .order_by(TransportIssue.id.desc())
        .all()
    )

    return [
        {
            "id": issue.id,
            "issue_number": issue.issue_number,
            "subject": issue.subject,
            "description": issue.description,
            "status": issue.status,
            "created_date": issue.created_date,
        }
        for issue in issues
    ]
