from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.hostel import HostelAllocation
from app.models.hostel_complaint import HostelComplaint
from app.models.student import Student
from app.models.user import User


router = APIRouter(
    prefix="/hostel",
    tags=["Hostel"],
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
def get_my_hostel(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    allocation = (
        db.query(HostelAllocation)
        .filter(
            HostelAllocation.student_id == student.id
        )
        .order_by(HostelAllocation.id.desc())
        .first()
    )

    if allocation is None:
        return {
            "allocated": False,
            "message": "No hostel allocation found",
        }

    return {
        "allocated": True,
        "id": allocation.id,
        "hostel_name": allocation.hostel_name,
        "block": allocation.block,
        "room_number": allocation.room_number,
        "bed_number": allocation.bed_number,
        "sharing_type": allocation.sharing_type,
        "academic_year": allocation.academic_year,
        "fee_amount": allocation.fee_amount,
        "warden_name": allocation.warden_name,
        "status": allocation.status,
    }


@router.get("/complaints")
def get_my_hostel_complaints(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    complaints = (
        db.query(HostelComplaint)
        .filter(
            HostelComplaint.student_id == student.id
        )
        .order_by(HostelComplaint.id.desc())
        .all()
    )

    return [
        {
            "id": complaint.id,
            "complaint_number": complaint.complaint_number,
            "subject": complaint.subject,
            "description": complaint.description,
            "status": complaint.status,
            "priority": complaint.priority,
            "created_date": complaint.created_date,
        }
        for complaint in complaints
    ]
