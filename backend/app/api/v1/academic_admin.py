from datetime import date, datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.models.academic_session import AcademicSession
from app.models.course_offering import CourseOffering
from app.models.curriculum import Curriculum
from app.models.curriculum_course import CurriculumCourse
from app.models.fee_structure_v2 import FeeStructure
from app.models.examination_registration_paper_v2 import ExaminationRegistrationPaperV2
from app.models.examination_registration_v2 import ExaminationRegistrationV2
from app.models.examination_schedule_v2 import ExaminationScheduleV2
from app.models.examination_v2 import ExaminationV2
from app.models.programme import Programme
from app.models.programme_specialization import ProgrammeSpecialization
from app.models.result import Result
from app.models.semester import Semester
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_item_v2 import StudentFeeInvoiceItemV2
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.timetable_entry_v2 import TimetableEntryV2
from app.models.user import User
from app.schemas.academic_plan import (
    AcademicPlanAssignRequest,
    AcademicPlanResponse,
    ResultPublishRequest,
    ResultPublishResponse,
)


router = APIRouter(prefix="/academic-admin", tags=["Academic Administration"])


def _student_or_404(student_id: int, db: Session) -> Student:
    student = db.query(Student).filter(Student.id == student_id).first()
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


def _assigned_context(student: Student, db: Session):
    if not all(
        [
            student.programme_id,
            student.curriculum_id,
            student.academic_session_id,
        ]
    ):
        raise HTTPException(status_code=404, detail="Academic plan is not assigned")

    programme = db.query(Programme).filter(Programme.id == student.programme_id).first()
    curriculum = db.query(Curriculum).filter(Curriculum.id == student.curriculum_id).first()
    academic_session = (
        db.query(AcademicSession)
        .filter(AcademicSession.id == student.academic_session_id)
        .first()
    )
    semester = db.query(Semester).filter(Semester.number == student.current_semester).first()
    specialization = None
    if student.specialization_id:
        specialization = (
            db.query(ProgrammeSpecialization)
            .filter(ProgrammeSpecialization.id == student.specialization_id)
            .first()
        )
    if not programme or not curriculum or not academic_session or not semester:
        raise HTTPException(status_code=409, detail="Academic plan references are incomplete")
    return programme, specialization, curriculum, academic_session, semester


def _plan_response(
    student: Student,
    db: Session,
    *,
    section: str = "A",
    changes: dict[str, int] | None = None,
) -> dict:
    programme, specialization, curriculum, academic_session, semester = _assigned_context(
        student, db
    )
    curriculum_courses = (
        db.query(CurriculumCourse)
        .filter(
            CurriculumCourse.curriculum_id == curriculum.id,
            CurriculumCourse.semester_number == student.current_semester,
        )
        .order_by(CurriculumCourse.display_order.asc())
        .all()
    )
    course_ids = [item.course_id for item in curriculum_courses]
    offerings = []
    if course_ids:
        offerings = (
            db.query(CourseOffering)
            .filter(
                CourseOffering.course_id.in_(course_ids),
                CourseOffering.semester_id == semester.id,
                CourseOffering.academic_session == academic_session.name,
                CourseOffering.is_active.is_(True),
            )
            .all()
        )
    offering_ids = [item.id for item in offerings]
    enrollment_by_offering = {}
    if offering_ids:
        enrollment_by_offering = {
            item.course_offering_id: item
            for item in db.query(StudentEnrollment)
            .filter(
                StudentEnrollment.student_id == student.id,
                StudentEnrollment.course_offering_id.in_(offering_ids),
            )
            .all()
        }
    timetable_counts = {}
    if offering_ids:
        for entry in (
            db.query(TimetableEntryV2)
            .filter(
                TimetableEntryV2.course_offering_id.in_(offering_ids),
                TimetableEntryV2.is_active.is_(True),
            )
            .all()
        ):
            timetable_counts[entry.course_offering_id] = (
                timetable_counts.get(entry.course_offering_id, 0) + 1
            )
    offering_by_course = {item.course_id: item for item in offerings}
    results_by_course = {
        item.course_id: item
        for item in db.query(Result)
        .filter(
            Result.student_id == student.id,
            Result.semester_id == semester.id,
            Result.course_id.in_(course_ids) if course_ids else False,
        )
        .all()
    }
    courses = []
    for item in curriculum_courses:
        offering = offering_by_course.get(item.course_id)
        enrollment = enrollment_by_offering.get(offering.id) if offering else None
        result = results_by_course.get(item.course_id)
        courses.append(
            {
                "course_id": item.course_id,
                "course_code": item.course.code,
                "course_name": item.course.name,
                "paper_code": item.source_paper_code,
                "paper_type": item.paper_type,
                "credits": item.total_credits,
                "offering_id": offering.id if offering else None,
                "enrollment_status": enrollment.status if enrollment else "not_enrolled",
                "timetable_slots": timetable_counts.get(offering.id, 0) if offering else 0,
                "marks": result.marks if result else None,
                "grade": result.grade if result else None,
                "grade_point": result.grade_point if result else None,
            }
        )

    active_enrollment_count = sum(
        1 for item in enrollment_by_offering.values() if item.status == "enrolled"
    )
    invoice_count = (
        db.query(StudentFeeInvoiceV2)
        .filter(
            StudentFeeInvoiceV2.student_id == student.id,
            StudentFeeInvoiceV2.academic_session == academic_session.name,
            StudentFeeInvoiceV2.semester == student.current_semester,
        )
        .count()
    )
    exam_registration_count = (
        db.query(ExaminationRegistrationV2)
        .join(ExaminationV2, ExaminationV2.id == ExaminationRegistrationV2.examination_id)
        .filter(
            ExaminationRegistrationV2.student_id == student.id,
            ExaminationV2.academic_session == academic_session.name,
            ExaminationV2.semester_id == semester.id,
        )
        .count()
    )
    payload = {
        "student_id": student.id,
        "student_name": student.full_name,
        "uni_id": student.uni_id,
        "programme_id": programme.id,
        "programme_name": programme.name,
        "specialization_id": specialization.id if specialization else None,
        "specialization_name": specialization.name if specialization else "Plain",
        "curriculum_id": curriculum.id,
        "curriculum_name": curriculum.name,
        "curriculum_status": curriculum.status,
        "is_demo_curriculum": curriculum.is_demo,
        "academic_session_id": academic_session.id,
        "academic_session": academic_session.name,
        "current_semester": student.current_semester,
        "semester_id": semester.id,
        "section": section,
        "curriculum_course_count": len(curriculum_courses),
        "active_enrollment_count": active_enrollment_count,
        "timetable_entry_count": sum(timetable_counts.values()),
        "invoice_count": invoice_count,
        "exam_registration_count": exam_registration_count,
        "result_count": len(results_by_course),
        "courses": courses,
    }
    payload.update(
        changes
        or {
            "offerings_created": 0,
            "enrollments_created": 0,
            "enrollments_reactivated": 0,
            "enrollments_archived": 0,
            "timetable_entries_created": 0,
            "invoices_created": 0,
            "exam_schedules_created": 0,
            "exam_registrations_created": 0,
        }
    )
    return payload


@router.get(
    "/students/{student_id}/plan",
    response_model=AcademicPlanResponse,
    dependencies=[Depends(require_role("admin"))],
)
def get_academic_plan(student_id: int, db: Session = Depends(get_db)):
    return _plan_response(_student_or_404(student_id, db), db)


@router.put(
    "/students/{student_id}/plan",
    response_model=AcademicPlanResponse,
)
def assign_academic_plan(
    student_id: int,
    request: AcademicPlanAssignRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _student_or_404(student_id, db)
    programme = db.query(Programme).filter(Programme.id == request.programme_id).first()
    curriculum = db.query(Curriculum).filter(Curriculum.id == request.curriculum_id).first()
    academic_session = (
        db.query(AcademicSession)
        .filter(AcademicSession.id == request.academic_session_id)
        .first()
    )
    semester = db.query(Semester).filter(Semester.number == request.current_semester).first()
    specialization = None
    if request.specialization_id is not None:
        specialization = (
            db.query(ProgrammeSpecialization)
            .filter(ProgrammeSpecialization.id == request.specialization_id)
            .first()
        )

    if programme is None:
        raise HTTPException(status_code=404, detail="Programme not found")
    if curriculum is None:
        raise HTTPException(status_code=404, detail="Curriculum not found")
    if academic_session is None:
        raise HTTPException(status_code=404, detail="Academic session not found")
    if semester is None:
        raise HTTPException(status_code=404, detail="Semester not configured")
    if specialization and specialization.programme_id != programme.id:
        raise HTTPException(status_code=400, detail="Specialization does not belong to programme")
    if curriculum.programme_id != programme.id:
        raise HTTPException(status_code=400, detail="Curriculum does not belong to programme")
    if curriculum.specialization_id != request.specialization_id:
        raise HTTPException(status_code=400, detail="Curriculum does not match specialization")

    curriculum_courses = (
        db.query(CurriculumCourse)
        .filter(
            CurriculumCourse.curriculum_id == curriculum.id,
            CurriculumCourse.semester_number == request.current_semester,
        )
        .order_by(CurriculumCourse.display_order.asc())
        .all()
    )
    if not curriculum_courses:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The selected curriculum has no courses for this semester",
        )

    student.programme_id = programme.id
    student.specialization_id = specialization.id if specialization else None
    student.curriculum_id = curriculum.id
    student.academic_session_id = academic_session.id
    student.department_id = programme.department_id
    student.programme = (
        programme.name
        if specialization is None or specialization.name == "Plain"
        else f"{programme.name} - {specialization.name}"
    )
    student.current_semester = request.current_semester
    student.academic_session = academic_session.name

    changes = {
        "offerings_created": 0,
        "enrollments_created": 0,
        "enrollments_reactivated": 0,
        "enrollments_archived": 0,
        "timetable_entries_created": 0,
        "invoices_created": 0,
        "exam_schedules_created": 0,
        "exam_registrations_created": 0,
    }
    offerings = []
    for index, curriculum_course in enumerate(curriculum_courses):
        offering = (
            db.query(CourseOffering)
            .filter(
                CourseOffering.course_id == curriculum_course.course_id,
                CourseOffering.semester_id == semester.id,
                CourseOffering.academic_session == academic_session.name,
                CourseOffering.section == request.section,
            )
            .first()
        )
        if offering is None:
            offering = CourseOffering(
                course_id=curriculum_course.course_id,
                semester_id=semester.id,
                academic_session=academic_session.name,
                section=request.section,
                capacity=60,
                is_active=True,
            )
            db.add(offering)
            db.flush()
            changes["offerings_created"] += 1
        elif not offering.is_active:
            offering.is_active = True
        offerings.append(offering)

        if request.auto_enroll:
            enrollment = (
                db.query(StudentEnrollment)
                .filter(
                    StudentEnrollment.student_id == student.id,
                    StudentEnrollment.course_offering_id == offering.id,
                )
                .first()
            )
            if enrollment is None:
                db.add(
                    StudentEnrollment(
                        student_id=student.id,
                        course_offering_id=offering.id,
                        status="enrolled",
                    )
                )
                changes["enrollments_created"] += 1
            elif enrollment.status != "enrolled":
                enrollment.status = "enrolled"
                enrollment.dropped_at = None
                changes["enrollments_reactivated"] += 1

        if request.create_standard_timetable:
            existing_slot = (
                db.query(TimetableEntryV2)
                .filter(
                    TimetableEntryV2.course_offering_id == offering.id,
                    TimetableEntryV2.is_active.is_(True),
                )
                .first()
            )
            if existing_slot is None:
                hour = 9 + (index % 4)
                db.add(
                    TimetableEntryV2(
                        course_offering_id=offering.id,
                        day_of_week=(index % 5) + 1,
                        start_time=f"{hour:02d}:00",
                        end_time=f"{hour + 1:02d}:00",
                        room=f"S{request.current_semester}-{request.section}",
                        building="Academic Block",
                        faculty_name="Faculty allocation pending",
                        is_active=True,
                    )
                )
                changes["timetable_entries_created"] += 1

    active_offering_ids = {offering.id for offering in offerings}
    obsolete_enrollments = (
        db.query(StudentEnrollment)
        .join(
            CourseOffering,
            CourseOffering.id == StudentEnrollment.course_offering_id,
        )
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
            CourseOffering.semester_id == semester.id,
            StudentEnrollment.course_offering_id.notin_(active_offering_ids),
        )
        .all()
    )
    for enrollment in obsolete_enrollments:
        enrollment.status = "withdrawn"
        enrollment.dropped_at = datetime.now(timezone.utc)
        changes["enrollments_archived"] += 1

    if request.create_demo_exam_plan:
        examination = (
            db.query(ExaminationV2)
            .filter(
                ExaminationV2.academic_session == academic_session.name,
                ExaminationV2.semester_id == semester.id,
                ExaminationV2.exam_type == "semester",
            )
            .first()
        )
        exam_start = date.today() + timedelta(days=60)
        if examination is None:
            examination = ExaminationV2(
                name=f"Semester {request.current_semester} Examination (Demo Schedule)",
                exam_type="semester",
                academic_session=academic_session.name,
                semester_id=semester.id,
                start_date=exam_start.isoformat(),
                end_date=(exam_start + timedelta(days=len(curriculum_courses) - 1)).isoformat(),
                registration_start=date.today().isoformat(),
                registration_end=(date.today() + timedelta(days=30)).isoformat(),
                is_registration_open=True,
                is_locked=False,
            )
            db.add(examination)
            db.flush()

        schedules = []
        for index, curriculum_course in enumerate(curriculum_courses):
            schedule = (
                db.query(ExaminationScheduleV2)
                .filter(
                    ExaminationScheduleV2.examination_id == examination.id,
                    ExaminationScheduleV2.course_id == curriculum_course.course_id,
                    ExaminationScheduleV2.is_active.is_(True),
                )
                .first()
            )
            if schedule is None:
                schedule = ExaminationScheduleV2(
                    examination_id=examination.id,
                    course_id=curriculum_course.course_id,
                    exam_date=(exam_start + timedelta(days=index)).isoformat(),
                    start_time="10:00",
                    end_time="13:00",
                    room=f"EX-{request.current_semester}{request.section}",
                    building="Examination Block",
                    max_marks=100,
                    passing_marks=40,
                    is_active=True,
                )
                db.add(schedule)
                db.flush()
                changes["exam_schedules_created"] += 1
            schedules.append(schedule)

        registration = (
            db.query(ExaminationRegistrationV2)
            .filter(
                ExaminationRegistrationV2.examination_id == examination.id,
                ExaminationRegistrationV2.student_id == student.id,
            )
            .first()
        )
        if registration is None:
            registration = ExaminationRegistrationV2(
                examination_id=examination.id,
                student_id=student.id,
                registration_number=f"EX-{examination.id:04d}-{student.id:06d}",
                status="approved",
                approved_at=datetime.now(timezone.utc),
                approved_by_user_id=current_user.id,
            )
            db.add(registration)
            db.flush()
            changes["exam_registrations_created"] += 1
        existing_paper_ids = {
            item.schedule_id
            for item in db.query(ExaminationRegistrationPaperV2)
            .filter(ExaminationRegistrationPaperV2.registration_id == registration.id)
            .all()
        }
        for schedule in schedules:
            if schedule.id not in existing_paper_ids:
                db.add(
                    ExaminationRegistrationPaperV2(
                        registration_id=registration.id,
                        schedule_id=schedule.id,
                        status="registered",
                    )
                )

    if request.create_fee_invoice:
        structures = (
            db.query(FeeStructure)
            .filter(
                FeeStructure.programme_id == programme.id,
                FeeStructure.semester == request.current_semester,
                FeeStructure.academic_session == academic_session.name,
                FeeStructure.is_active.is_(True),
            )
            .all()
        )
        existing_invoice = (
            db.query(StudentFeeInvoiceV2)
            .filter(
                StudentFeeInvoiceV2.student_id == student.id,
                StudentFeeInvoiceV2.academic_session == academic_session.name,
                StudentFeeInvoiceV2.semester == request.current_semester,
            )
            .first()
        )
        if structures and existing_invoice is None:
            total = sum(item.amount for item in structures)
            invoice = StudentFeeInvoiceV2(
                student_id=student.id,
                academic_session=academic_session.name,
                semester=request.current_semester,
                invoice_number=f"INV-{date.today().year}-{uuid4().hex[:10].upper()}",
                total_amount=total,
                paid_amount=0,
                outstanding_amount=total,
                due_date=(date.today() + timedelta(days=30)).isoformat(),
                status="pending",
            )
            db.add(invoice)
            db.flush()
            for structure in structures:
                db.add(
                    StudentFeeInvoiceItemV2(
                        invoice_id=invoice.id,
                        fee_type=structure.fee_type,
                        description=f"{programme.name} - Semester {request.current_semester}",
                        amount=structure.amount,
                    )
                )
            changes["invoices_created"] += 1

    db.commit()
    db.refresh(student)
    return _plan_response(student, db, section=request.section, changes=changes)


def _grade_for_marks(marks: float) -> tuple[str, float]:
    if marks >= 90:
        return "A+", 10.0
    if marks >= 80:
        return "A", 9.0
    if marks >= 70:
        return "B+", 8.0
    if marks >= 60:
        return "B", 7.0
    if marks >= 50:
        return "C", 6.0
    if marks >= 40:
        return "D", 5.0
    return "F", 0.0


@router.post(
    "/students/{student_id}/results",
    response_model=ResultPublishResponse,
)
def publish_result(
    student_id: int,
    request: ResultPublishRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _student_or_404(student_id, db)
    _assigned_context(student, db)
    curriculum_course = (
        db.query(CurriculumCourse)
        .filter(
            CurriculumCourse.curriculum_id == student.curriculum_id,
            CurriculumCourse.semester_number == student.current_semester,
            CurriculumCourse.course_id == request.course_id,
        )
        .first()
    )
    if curriculum_course is None:
        raise HTTPException(status_code=400, detail="Course is not in the student's current curriculum semester")
    semester = db.query(Semester).filter(Semester.id == request.semester_id).first()
    if semester is None or semester.number != student.current_semester:
        raise HTTPException(status_code=400, detail="Result semester does not match the academic plan")
    grade, grade_point = _grade_for_marks(request.marks)
    result = (
        db.query(Result)
        .filter(
            Result.student_id == student.id,
            Result.course_id == request.course_id,
            Result.semester_id == request.semester_id,
        )
        .first()
    )
    if result is None:
        result = Result(
            student_id=student.id,
            course_id=request.course_id,
            semester_id=request.semester_id,
            marks=request.marks,
            grade=grade,
            grade_point=grade_point,
        )
        db.add(result)
    else:
        result.marks = request.marks
        result.grade = grade
        result.grade_point = grade_point
    db.commit()
    db.refresh(result)
    return result
