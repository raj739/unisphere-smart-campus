from uuid import uuid4
import secrets
import string

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.core.security import hash_password
from app.models.department import Department
from app.models.academic_session import AcademicSession
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.course import Course
from app.models.course_offering import CourseOffering
from app.models.curriculum import Curriculum
from app.models.digital_document import DigitalDocument
from app.models.examination_v2 import ExaminationV2
from app.models.fee_structure_v2 import FeeStructure
from app.models.payment_transaction_v2 import PaymentTransactionV2
from app.models.programme import Programme
from app.models.programme_specialization import ProgrammeSpecialization
from app.models.semester import Semester
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.student_identifier import StudentIdentifier
from app.models.timetable_entry_v2 import TimetableEntryV2
from app.models.user import User
from app.schemas.registration import (
    StudentRegistrationRequest,
    StudentRegistrationResponse,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


@router.get("/dashboard")
def admin_dashboard(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    invoice_totals = db.query(
        func.coalesce(func.sum(StudentFeeInvoiceV2.total_amount), 0.0),
        func.coalesce(func.sum(StudentFeeInvoiceV2.paid_amount), 0.0),
        func.coalesce(func.sum(StudentFeeInvoiceV2.outstanding_amount), 0.0),
    ).one()

    department_distribution = (
        db.query(
            Department.id,
            Department.name,
            Department.code,
            func.count(Student.id).label("student_count"),
        )
        .outerjoin(Student, Student.department_id == Department.id)
        .group_by(Department.id, Department.name, Department.code)
        .order_by(func.count(Student.id).desc(), Department.name.asc())
        .all()
    )

    recent_students = (
        db.query(Student)
        .order_by(Student.id.desc())
        .limit(6)
        .all()
    )

    return {
        "total_students": db.query(Student).count(),
        "total_departments": db.query(Department).count(),
        "total_programmes": db.query(Programme).count(),
        "total_programme_options": db.query(ProgrammeSpecialization).count(),
        "active_academic_sessions": db.query(AcademicSession)
        .filter(AcademicSession.is_active.is_(True))
        .count(),
        "total_semesters": db.query(Semester).count(),
        "total_courses": db.query(Course).count(),
        "total_curricula": db.query(Curriculum).count(),
        "active_offerings": db.query(CourseOffering)
        .filter(CourseOffering.is_active.is_(True))
        .count(),
        "active_enrollments": db.query(StudentEnrollment)
        .filter(StudentEnrollment.status == "enrolled")
        .count(),
        "timetable_entries": db.query(TimetableEntryV2)
        .filter(TimetableEntryV2.is_active.is_(True))
        .count(),
        "attendance_sessions": db.query(AttendanceSessionV2).count(),
        "examinations": db.query(ExaminationV2).count(),
        "fee_structures": db.query(FeeStructure)
        .filter(FeeStructure.is_active.is_(True))
        .count(),
        "documents_issued": db.query(DigitalDocument).count(),
        "payment_transactions": db.query(PaymentTransactionV2).count(),
        "finance": {
            "invoiced": float(invoice_totals[0] or 0),
            "collected": float(invoice_totals[1] or 0),
            "outstanding": float(invoice_totals[2] or 0),
        },
        "department_distribution": [
            {
                "id": row.id,
                "name": row.name,
                "code": row.code,
                "student_count": row.student_count,
            }
            for row in department_distribution
        ],
        "recent_students": [
            {
                "id": student.id,
                "full_name": student.full_name,
                "uni_id": student.uni_id,
                "programme": student.programme,
                "current_semester": student.current_semester,
                "department_id": student.department_id,
            }
            for student in recent_students
        ],
    }


@router.post(
    "/students",
    response_model=StudentRegistrationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_student(
    registration: StudentRegistrationRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    # ---------------------------------------------------------
    # 1. Normalize identity values
    # ---------------------------------------------------------
    email = str(registration.email).strip().lower()

    university_id = (
        registration.university_id.strip()
        if registration.university_id
        else None
    )

    enrollment_number = (
        registration.enrollment_number.strip()
        if registration.enrollment_number
        else None
    )

    # ---------------------------------------------------------
    # 2. Check duplicate email
    # ---------------------------------------------------------
    existing_user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with this email already exists",
        )

    # ---------------------------------------------------------
    # 3. Check department
    # ---------------------------------------------------------
    department = (
        db.query(Department)
        .filter(Department.id == registration.department_id)
        .first()
    )

    if department is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Department not found",
        )

    university = department.university

    # ---------------------------------------------------------
    # 4. Check duplicate enrollment number
    # ---------------------------------------------------------
    if enrollment_number:
        existing_enrollment = (
            db.query(Student)
            .filter(
                Student.enrollment_number == enrollment_number
            )
            .first()
        )

        if existing_enrollment is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Enrollment number already exists",
            )

    # ---------------------------------------------------------
    # 5. Check duplicate university ID
    # ---------------------------------------------------------
    if university_id:
        existing_university_id = (
            db.query(Student)
            .filter(
                Student.university_id == university_id
            )
            .first()
        )

        if existing_university_id is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="University ID already exists",
            )

    try:
        # -----------------------------------------------------
        # 6. Create User account
        # -----------------------------------------------------
        # -----------------------------------------------------
        # 6. Generate secure temporary login password
        #
        # The plain password is returned once to the admin.
        # Only the bcrypt hash is stored in the database.
        # -----------------------------------------------------
        alphabet = string.ascii_letters + string.digits + "!@#$%&*"
        temporary_password = (
            "Uni@"
            + secrets.token_urlsafe(6)
            + secrets.choice(string.ascii_uppercase)
            + secrets.choice(string.digits)
        )

        user = User(
            email=email,
            password_hash=hash_password(temporary_password),
            role="student",
            is_active=True,
        )

        db.add(user)
        db.flush()

        # -----------------------------------------------------
        # 7. Create Student
        #
        # Temporary Uni-ID is unique so that the database
        # uniqueness constraint is never violated.
        # -----------------------------------------------------
        temporary_uni_id = f"TEMP-{uuid4()}"

        student = Student(
            user_id=user.id,
            department_id=registration.department_id,
            uni_id=temporary_uni_id,
            university_id=university_id,
            enrollment_number=enrollment_number,
            full_name=registration.full_name.strip(),
            programme=registration.programme.strip(),
            current_semester=registration.current_semester,
            academic_session=(
                registration.academic_session.strip()
                if registration.academic_session
                else None
            ),
        )

        db.add(student)
        db.flush()

        # -----------------------------------------------------
        # 8. Generate permanent Uni-ID
        #
        # Example:
        # UNI-VU-BCA-2026-000124
        # -----------------------------------------------------
        university_code = (
            university.code.strip().upper()
            if university and university.code
            else "UNI"
        )

        department_code = (
            department.code.strip().upper()
            if department.code
            else "GEN"
        )

        academic_year = "2026"

        if (
            registration.academic_session
            and len(registration.academic_session.strip()) >= 4
        ):
            academic_year = registration.academic_session.strip()[:4]

        uni_id = (
            f"UNI-{university_code}-"
            f"{department_code}-"
            f"{academic_year}-"
            f"{student.id:06d}"
        )

        # Extra safety check
        existing_uni_id = (
            db.query(Student)
            .filter(Student.uni_id == uni_id)
            .first()
        )

        if existing_uni_id is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Generated Uni-ID already exists",
            )

        student.uni_id = uni_id

        # -----------------------------------------------------
        # 9. Create University ID identifier
        # -----------------------------------------------------
        if university_id:
            db.add(
                StudentIdentifier(
                    student_id=student.id,
                    identifier_type="university_id",
                    identifier_value=university_id,
                    issuing_authority=(
                        university.name
                        if university
                        else None
                    ),
                    is_verified=True,
                )
            )

        # -----------------------------------------------------
        # 10. Create Enrollment identifier
        # -----------------------------------------------------
        if enrollment_number:
            db.add(
                StudentIdentifier(
                    student_id=student.id,
                    identifier_type="enrollment",
                    identifier_value=enrollment_number,
                    issuing_authority=(
                        university.name
                        if university
                        else None
                    ),
                    is_verified=True,
                )
            )

        # -----------------------------------------------------
        # 11. Create Uni-ID identifier
        # -----------------------------------------------------
        db.add(
            StudentIdentifier(
                student_id=student.id,
                identifier_type="uni_id",
                identifier_value=uni_id,
                issuing_authority="UniSphere",
                is_verified=True,
            )
        )

        # -----------------------------------------------------
        # 12. Commit
        # -----------------------------------------------------
        db.commit()
        db.refresh(student)

        return StudentRegistrationResponse(
            message="Student registered successfully",
            user_id=user.id,
            student_id=student.id,
            uni_id=student.uni_id,
            university_id=student.university_id,
            enrollment_number=student.enrollment_number,
            full_name=student.full_name,
            email=user.email,
            programme=student.programme,
            current_semester=student.current_semester,
            department_id=student.department_id,
            academic_session=student.academic_session,
            role=user.role,
            temporary_password=temporary_password,
        )

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        raise


@router.get("/students")
def get_all_students(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    students = (
        db.query(Student)
        .order_by(Student.id.asc())
        .all()
    )

    return [
        {
            "id": student.id,
            "uni_id": student.uni_id,
            "university_id": student.university_id,
            "enrollment_number": student.enrollment_number,
            "full_name": student.full_name,
            "programme": student.programme,
            "programme_id": student.programme_id,
            "specialization_id": student.specialization_id,
            "curriculum_id": student.curriculum_id,
            "academic_session_id": student.academic_session_id,
            "current_semester": student.current_semester,
            "academic_session": student.academic_session,
            "department_id": student.department_id,
            "user_id": student.user_id,
        }
        for student in students
    ]


@router.get("/students/{uni_id}")
def get_student_details(
    uni_id: str,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.uni_id == uni_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    return {
        "id": student.id,
        "uni_id": student.uni_id,
        "university_id": student.university_id,
        "enrollment_number": student.enrollment_number,
        "full_name": student.full_name,
        "programme": student.programme,
        "programme_id": student.programme_id,
        "specialization_id": student.specialization_id,
        "curriculum_id": student.curriculum_id,
        "academic_session_id": student.academic_session_id,
        "current_semester": student.current_semester,
        "academic_session": student.academic_session,
        "department_id": student.department_id,
        "user_id": student.user_id,
    }
