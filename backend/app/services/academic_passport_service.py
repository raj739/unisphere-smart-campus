import hashlib
import secrets
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.academic_passport import AcademicPassport
from app.models.student import Student


class AcademicPassportService:

    @staticmethod
    def _passport_number(student: Student) -> str:
        raw = f"USP-{student.uni_id}-{student.id}"
        digest = hashlib.sha256(raw.encode()).hexdigest()[:10].upper()
        return f"USP-{digest}"

    @staticmethod
    def _token() -> str:
        return secrets.token_urlsafe(32)

    @classmethod
    def build_summary(
        cls,
        student: Student,
        attendance: float | None = None,
        academic_percentage: float | None = None,
    ) -> str:

        parts = [
            f"Student: {student.full_name}",
            f"University ID: {student.uni_id}",
        ]

        if student.programme:
            parts.append(f"Programme: {student.programme}")

        if student.current_semester is not None:
            parts.append(
                f"Current Semester: {student.current_semester}"
            )

        if student.academic_session:
            parts.append(
                f"Academic Session: {student.academic_session}"
            )

        if attendance is not None:
            parts.append(
                f"Attendance: {attendance:.1f}%"
            )

        if academic_percentage is not None:
            parts.append(
                f"Academic Performance: "
                f"{academic_percentage:.1f}%"
            )

        return " | ".join(parts)

    @classmethod
    def generate_or_update(
        cls,
        db: Session,
        student: Student,
        attendance: float | None = None,
        academic_percentage: float | None = None,
    ) -> AcademicPassport:

        passport = (
            db.query(AcademicPassport)
            .filter(
                AcademicPassport.student_id == student.id,
            )
            .first()
        )

        if not passport:
            passport = AcademicPassport(
                student_id=student.id,
                passport_number=cls._passport_number(student),
                verification_token=cls._token(),
                full_name=student.full_name,
                uni_id=student.uni_id,
                programme=student.programme,
                current_semester=student.current_semester,
                academic_session=student.academic_session,
                status="Active",
                is_verified=True,
            )
            db.add(passport)
        else:
            passport.full_name = student.full_name
            passport.uni_id = student.uni_id
            passport.programme = student.programme
            passport.current_semester = student.current_semester
            passport.academic_session = student.academic_session
            passport.updated_at = datetime.utcnow()

        passport.summary = cls.build_summary(
            student=student,
            attendance=attendance,
            academic_percentage=academic_percentage,
        )

        db.commit()
        db.refresh(passport)

        return passport
