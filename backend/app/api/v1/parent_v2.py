from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.core.security import hash_password
from app.models.user import User
from app.models.student import Student
from app.models.parent_profile_v2 import ParentProfileV2
from app.models.parent_student_link_v2 import ParentStudentLinkV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.examination_registration_v2 import ExaminationRegistrationV2

from app.schemas.parent_v2 import (
    ParentProfileCreateRequest,
    ParentProfileResponse,
    ParentStudentLinkCreateRequest,
    ParentStudentLinkResponse,
    ParentStudentSummary,
    ParentAttendanceSummary,
    ParentFeeSummary,
    ParentExamSummary,
    ParentDashboardResponse,
    ParentAccountCreateRequest,
)

router = APIRouter(
    prefix="/parent-v2",
    tags=["Parent Portal V2"],
)


def serialize_parent_account(db: Session, user: User):
    profile = (
        db.query(ParentProfileV2)
        .filter(ParentProfileV2.user_id == user.id)
        .first()
    )
    links = (
        db.query(ParentStudentLinkV2)
        .filter(ParentStudentLinkV2.parent_user_id == user.id)
        .order_by(
            ParentStudentLinkV2.is_primary.desc(),
            ParentStudentLinkV2.id.asc(),
        )
        .all()
    )
    return {
        "user_id": user.id,
        "email": user.email,
        "is_active": user.is_active,
        "full_name": profile.full_name if profile else user.email,
        "phone": profile.phone if profile else None,
        "relationship_type": (
            profile.relationship_type if profile else None
        ),
        "links": [
            {
                "link_id": link.id,
                "student_id": link.student_id,
                "student_name": link.student.full_name,
                "uni_id": link.student.uni_id,
                "programme": link.student.programme,
                "relationship_type": link.relationship_type,
                "is_primary": link.is_primary,
                "is_active": link.is_active,
            }
            for link in links
        ],
    }


@router.get(
    "/admin/accounts",
    dependencies=[Depends(require_role("admin"))],
)
def list_parent_accounts(db: Session = Depends(get_db)):
    users = (
        db.query(User)
        .filter(User.role == "parent")
        .order_by(User.id.asc())
        .all()
    )
    return [serialize_parent_account(db, user) for user in users]


@router.post(
    "/admin/accounts",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_role("admin"))],
)
def create_parent_account(
    request: ParentAccountCreateRequest,
    db: Session = Depends(get_db),
):
    email = request.email.strip().lower()
    if "@" not in email:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Enter a valid parent email address",
        )

    if db.query(User).filter(User.email == email).first() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    student = (
        db.query(Student)
        .filter(Student.id == request.student_id)
        .first()
    )
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    try:
        user = User(
            email=email,
            password_hash=hash_password(request.password),
            role="parent",
            is_active=True,
        )
        db.add(user)
        db.flush()

        profile = ParentProfileV2(
            user_id=user.id,
            full_name=request.full_name.strip(),
            phone=request.phone.strip() if request.phone else None,
            relationship_type=request.relationship_type.strip(),
            is_active=True,
        )
        db.add(profile)
        db.add(
            ParentStudentLinkV2(
                parent_user_id=user.id,
                student_id=student.id,
                relationship_type=request.relationship_type.strip(),
                is_primary=request.is_primary,
                is_active=True,
            )
        )
        db.commit()
        db.refresh(user)
        return serialize_parent_account(db, user)
    except Exception:
        db.rollback()
        raise


def get_parent_profile(db: Session, user_id: int):
    profile = (
        db.query(ParentProfileV2)
        .filter(
            ParentProfileV2.user_id == user_id,
            ParentProfileV2.is_active == True,
        )
        .first()
    )

    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parent profile not found",
        )

    return profile


def get_linked_student(
    db: Session,
    parent_user_id: int,
    student_id: int,
):
    link = (
        db.query(ParentStudentLinkV2)
        .filter(
            ParentStudentLinkV2.parent_user_id == parent_user_id,
            ParentStudentLinkV2.student_id == student_id,
            ParentStudentLinkV2.is_active == True,
        )
        .first()
    )

    if link is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student is not linked to this parent account",
        )

    return (
        db.query(Student)
        .filter(Student.id == student_id)
        .first()
    )


@router.post(
    "/profiles",
    response_model=ParentProfileResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_parent_profile(
    request: ParentProfileCreateRequest,
    user_id: int,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(
            User.id == user_id,
            User.role == "parent",
        )
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parent user account not found",
        )

    existing = (
        db.query(ParentProfileV2)
        .filter(ParentProfileV2.user_id == user_id)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Parent profile already exists",
        )

    profile = ParentProfileV2(
        user_id=user_id,
        **request.model_dump(),
    )

    db.add(profile)
    db.commit()
    db.refresh(profile)

    return profile


@router.get(
    "/profile",
    response_model=ParentProfileResponse,
)
def my_profile(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_parent_profile(db, current_user.id)


@router.post(
    "/links",
    response_model=ParentStudentLinkResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_student_link(
    request: ParentStudentLinkCreateRequest,
    db: Session = Depends(get_db),
):
    parent = (
        db.query(User)
        .filter(
            User.id == request.parent_user_id,
            User.role == "parent",
        )
        .first()
    )

    if parent is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parent account not found",
        )

    student = (
        db.query(Student)
        .filter(Student.id == request.student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    existing = (
        db.query(ParentStudentLinkV2)
        .filter(
            ParentStudentLinkV2.parent_user_id == request.parent_user_id,
            ParentStudentLinkV2.student_id == request.student_id,
        )
        .first()
    )

    if existing:
        if existing.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Parent-student link already exists",
            )
        existing.is_active = True
        existing.relationship_type = request.relationship_type
        existing.is_primary = request.is_primary
        db.commit()
        db.refresh(existing)
        return existing

    link = ParentStudentLinkV2(
        **request.model_dump()
    )

    db.add(link)
    db.commit()
    db.refresh(link)

    return link


@router.get(
    "/students",
    response_model=list[ParentStudentSummary],
)
def linked_students(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != "parent":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Parent access required",
        )

    links = (
        db.query(ParentStudentLinkV2)
        .filter(
            ParentStudentLinkV2.parent_user_id == current_user.id,
            ParentStudentLinkV2.is_active == True,
        )
        .all()
    )

    result = []

    for link in links:
        student = link.student

        result.append(
            ParentStudentSummary(
                student_id=student.id,
                uni_id=student.uni_id,
                full_name=student.full_name,
                programme=student.programme,
                current_semester=student.current_semester,
                academic_session=student.academic_session,
                enrollment_number=student.enrollment_number,
                university_id=student.university_id,
            )
        )

    return result


@router.get(
    "/students/{student_id}",
    response_model=ParentStudentSummary,
)
def student_summary(
    student_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        db,
        current_user.id,
        student_id,
    )

    return ParentStudentSummary(
        student_id=student.id,
        uni_id=student.uni_id,
        full_name=student.full_name,
        programme=student.programme,
        current_semester=student.current_semester,
        academic_session=student.academic_session,
        enrollment_number=student.enrollment_number,
        university_id=student.university_id,
    )


@router.get(
    "/students/{student_id}/attendance",
    response_model=ParentAttendanceSummary,
)
def student_attendance(
    student_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        db,
        current_user.id,
        student_id,
    )

    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )

    offering_ids = [
        enrollment.course_offering_id
        for enrollment in enrollments
    ]

    if not offering_ids:
        return ParentAttendanceSummary(
            student_id=student.id,
            overall_percentage=0.0,
            total_classes=0,
            attended_classes=0,
            status="no_data",
        )

    sessions = (
        db.query(AttendanceSessionV2)
        .filter(
            AttendanceSessionV2.course_offering_id.in_(offering_ids)
        )
        .all()
    )

    if not sessions:
        return ParentAttendanceSummary(
            student_id=student.id,
            overall_percentage=0.0,
            total_classes=0,
            attended_classes=0,
            status="no_data",
        )

    session_ids = [session.id for session in sessions]

    records = (
        db.query(AttendanceRecordV2)
        .filter(
            AttendanceRecordV2.student_id == student.id,
            AttendanceRecordV2.attendance_session_id.in_(session_ids),
        )
        .all()
    )

    total = len(sessions)
    attended = sum(
        1
        for record in records
        if record.status in {"present", "late"}
    )

    percentage = round(
        attended / total * 100,
        2,
    )

    if percentage < 60:
        attendance_status = "critical"
    elif percentage < 75:
        attendance_status = "warning"
    else:
        attendance_status = "good"

    return ParentAttendanceSummary(
        student_id=student.id,
        overall_percentage=percentage,
        total_classes=total,
        attended_classes=attended,
        status=attendance_status,
    )


@router.get(
    "/students/{student_id}/fees",
    response_model=ParentFeeSummary,
)
def student_fees(
    student_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        db,
        current_user.id,
        student_id,
    )

    invoices = (
        db.query(StudentFeeInvoiceV2)
        .filter(
            StudentFeeInvoiceV2.student_id == student.id
        )
        .all()
    )

    total_amount = sum(
        invoice.total_amount
        for invoice in invoices
    )

    paid_amount = sum(
        invoice.paid_amount
        for invoice in invoices
    )

    outstanding_amount = sum(
        invoice.outstanding_amount
        for invoice in invoices
    )

    if outstanding_amount <= 0 and invoices:
        fee_status = "paid"
    elif paid_amount > 0:
        fee_status = "partially_paid"
    elif invoices:
        fee_status = "pending"
    else:
        fee_status = "no_data"

    return ParentFeeSummary(
        student_id=student.id,
        total_amount=total_amount,
        paid_amount=paid_amount,
        outstanding_amount=outstanding_amount,
        status=fee_status,
    )


@router.get(
    "/students/{student_id}/examinations",
    response_model=ParentExamSummary,
)
def student_examinations(
    student_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        db,
        current_user.id,
        student_id,
    )

    registrations = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.student_id == student.id
        )
        .all()
    )

    approved = sum(
        1
        for registration in registrations
        if registration.status == "approved"
    )

    pending = sum(
        1
        for registration in registrations
        if registration.status == "registered"
    )

    return ParentExamSummary(
        student_id=student.id,
        registrations=len(registrations),
        approved=approved,
        pending=pending,
    )


@router.get(
    "/students/{student_id}/dashboard",
    response_model=ParentDashboardResponse,
)
def student_dashboard(
    student_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_linked_student(
        db,
        current_user.id,
        student_id,
    )

    student_summary_data = ParentStudentSummary(
        student_id=student.id,
        uni_id=student.uni_id,
        full_name=student.full_name,
        programme=student.programme,
        current_semester=student.current_semester,
        academic_session=student.academic_session,
        enrollment_number=student.enrollment_number,
        university_id=student.university_id,
    )

    attendance = student_attendance(
        student_id,
        current_user,
        db,
    )

    fees = student_fees(
        student_id,
        current_user,
        db,
    )

    examinations = student_examinations(
        student_id,
        current_user,
        db,
    )

    return ParentDashboardResponse(
        student=student_summary_data,
        attendance=attendance,
        fees=fees,
        examinations=examinations,
    )
