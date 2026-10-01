from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.models.attendance import Attendance
from app.models.fee import FeeRecord
from app.models.intervention import AcademicIntervention
from app.models.parent_student import ParentStudentLink
from app.models.result import Result
from app.models.student import Student
from app.models.user import User
from app.schemas.parent import (
    ParentAcademicResponse,
    ParentAlertResponse,
    ParentFeeResponse,
    ParentOverviewResponse,
    ParentStudentResponse,
)


router = APIRouter(
    prefix="/parent",
    tags=["Parent"],
)


def get_linked_student(
    current_user: User,
    db: Session,
) -> Student:

    link = (
        db.query(ParentStudentLink)
        .filter(
            ParentStudentLink.parent_user_id
            == current_user.id
        )
        .first()
    )

    if link is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No student linked to this parent account",
        )

    student = (
        db.query(Student)
        .filter(Student.id == link.student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Linked student not found",
        )

    return student


def get_academic_data(
    student: Student,
    db: Session,
):
    attendance_records = (
        db.query(Attendance)
        .filter(
            Attendance.student_id == student.id
        )
        .all()
    )

    result_records = (
        db.query(Result)
        .filter(
            Result.student_id == student.id
        )
        .all()
    )

    if attendance_records:
        average_attendance = (
            sum(
                record.percentage
                for record in attendance_records
            )
            / len(attendance_records)
        )
    else:
        average_attendance = 0.0

    if result_records:
        cgpa = (
            sum(
                record.grade_point
                for record in result_records
            )
            / len(result_records)
        )
    else:
        cgpa = 0.0

    if cgpa >= 8:
        academic_status = "Good"
    elif cgpa >= 6:
        academic_status = "Needs Attention"
    else:
        academic_status = "At Risk"

    return (
        round(cgpa, 2),
        round(average_attendance, 2),
        len(result_records),
        academic_status,
    )


def get_fee_data(
    student: Student,
    db: Session,
):
    fee = (
        db.query(FeeRecord)
        .filter(
            FeeRecord.student_id == student.id
        )
        .order_by(FeeRecord.id.desc())
        .first()
    )

    if fee is None:
        return ParentFeeResponse(
            total_amount=0,
            paid_amount=0,
            outstanding_amount=0,
            due_date=None,
            status="No Fee Record",
        )

    return ParentFeeResponse(
        total_amount=fee.total_amount,
        paid_amount=fee.paid_amount,
        outstanding_amount=fee.outstanding_amount,
        due_date=fee.due_date,
        status=fee.status,
    )


def get_alerts(
    student: Student,
    db: Session,
):
    alerts = []

    attendance_records = (
        db.query(Attendance)
        .filter(
            Attendance.student_id == student.id
        )
        .all()
    )

    for record in attendance_records:
        if record.percentage < 75:
            alerts.append(
                ParentAlertResponse(
                    type="attendance",
                    title="Attendance Alert",
                    message=(
                        f"Attendance is {record.percentage}% "
                        "and requires attention."
                    ),
                    priority="High",
                )
            )
            break

    fee = (
        db.query(FeeRecord)
        .filter(
            FeeRecord.student_id == student.id,
            FeeRecord.outstanding_amount > 0,
        )
        .order_by(FeeRecord.id.desc())
        .first()
    )

    if fee:
        alerts.append(
            ParentAlertResponse(
                type="fee",
                title="Fee Due",
                message=(
                    f"Outstanding fee amount is "
                    f"₹{fee.outstanding_amount:.0f}."
                ),
                priority="Medium",
            )
        )

    interventions = (
        db.query(AcademicIntervention)
        .filter(
            AcademicIntervention.student_id == student.id,
            AcademicIntervention.status != "Resolved",
        )
        .all()
    )

    if interventions:
        alerts.append(
            ParentAlertResponse(
                type="academic",
                title="Academic Attention",
                message=(
                    f"{len(interventions)} academic "
                    "intervention(s) require attention."
                ),
                priority="High",
            )
        )

    return alerts


@router.get(
    "/student",
    response_model=ParentStudentResponse,
)
def get_parent_student(
    current_user: User = Depends(
        require_role("parent")
    ),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        current_user,
        db,
    )

    return ParentStudentResponse(
        uni_id=student.uni_id,
        full_name=student.full_name,
        programme=student.programme,
        current_semester=student.current_semester,
        academic_session=student.academic_session,
    )


@router.get(
    "/academic",
    response_model=ParentAcademicResponse,
)
def get_parent_academic(
    current_user: User = Depends(
        require_role("parent")
    ),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        current_user,
        db,
    )

    (
        cgpa,
        average_attendance,
        total_courses,
        academic_status,
    ) = get_academic_data(
        student,
        db,
    )

    return ParentAcademicResponse(
        cgpa=cgpa,
        average_attendance=average_attendance,
        total_courses=total_courses,
        academic_status=academic_status,
    )


@router.get(
    "/fees",
    response_model=ParentFeeResponse,
)
def get_parent_fees(
    current_user: User = Depends(
        require_role("parent")
    ),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        current_user,
        db,
    )

    return get_fee_data(
        student,
        db,
    )


@router.get(
    "/alerts",
    response_model=list[ParentAlertResponse],
)
def get_parent_alerts(
    current_user: User = Depends(
        require_role("parent")
    ),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        current_user,
        db,
    )

    return get_alerts(
        student,
        db,
    )


@router.get(
    "/overview",
    response_model=ParentOverviewResponse,
)
def get_parent_overview(
    current_user: User = Depends(
        require_role("parent")
    ),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        current_user,
        db,
    )

    (
        cgpa,
        average_attendance,
        total_courses,
        academic_status,
    ) = get_academic_data(
        student,
        db,
    )

    return ParentOverviewResponse(
        student=ParentStudentResponse(
            uni_id=student.uni_id,
            full_name=student.full_name,
            programme=student.programme,
            current_semester=student.current_semester,
            academic_session=student.academic_session,
        ),
        academic=ParentAcademicResponse(
            cgpa=cgpa,
            average_attendance=average_attendance,
            total_courses=total_courses,
            academic_status=academic_status,
        ),
        fees=get_fee_data(
            student,
            db,
        ),
        alerts=get_alerts(
            student,
            db,
        ),
    )
