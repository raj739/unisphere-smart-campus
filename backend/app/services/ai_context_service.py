from sqlalchemy.orm import Session

from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.certificate import Certificate
from app.models.certificate_request import CertificateRequest
from app.models.early_warning import EarlyWarning
from app.models.examination_registration_paper_v2 import ExaminationRegistrationPaperV2
from app.models.examination_registration_v2 import ExaminationRegistrationV2
from app.models.helpdesk_ticket_v2 import HelpdeskTicketV2
from app.models.hostel_allocation_v2 import HostelAllocationV2
from app.models.hostel_complaint_v2 import HostelComplaintV2
from app.models.intervention import Intervention
from app.models.result import Result
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.student_transport_allocation_v2 import StudentTransportAllocationV2
from app.models.timetable_entry_v2 import TimetableEntryV2
from app.models.transport_issue_v2 import TransportIssueV2
from app.models.transport_route_assignment_v2 import TransportRouteAssignmentV2
from app.services.recommendation_service import generate_recommendations


DAY_NAMES = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday",
}


def _course_context(db: Session, student: Student) -> tuple[list, dict]:
    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )
    offering_ids = [item.course_offering_id for item in enrollments]
    sessions = (
        db.query(AttendanceSessionV2)
        .filter(AttendanceSessionV2.course_offering_id.in_(offering_ids))
        .all()
        if offering_ids
        else []
    )
    session_ids = [item.id for item in sessions]
    records = (
        db.query(AttendanceRecordV2)
        .filter(
            AttendanceRecordV2.student_id == student.id,
            AttendanceRecordV2.attendance_session_id.in_(session_ids),
        )
        .all()
        if session_ids
        else []
    )
    sessions_by_offering = {}
    for session in sessions:
        sessions_by_offering.setdefault(session.course_offering_id, []).append(session)
    records_by_session = {item.attendance_session_id: item for item in records}

    courses = []
    total_counted = 0
    total_attended = 0
    for enrollment in enrollments:
        offering = enrollment.course_offering
        course = offering.course
        course_sessions = sessions_by_offering.get(offering.id, [])
        counted = 0
        attended = 0
        for session in course_sessions:
            record = records_by_session.get(session.id)
            if record is not None and record.status == "excused":
                continue
            counted += 1
            if record is not None and record.status in {"present", "late"}:
                attended += 1
        percentage = round(attended / counted * 100, 2) if counted else None
        total_counted += counted
        total_attended += attended
        courses.append(
            {
                "code": course.code,
                "name": course.name,
                "credits": course.credits,
                "faculty": offering.faculty_name,
                "section": offering.section,
                "academic_session": offering.academic_session,
                "attendance_percentage": percentage,
                "classes_counted": counted,
                "classes_attended": attended,
            }
        )
    attendance = {
        "percentage": (
            round(total_attended / total_counted * 100, 2)
            if total_counted
            else None
        ),
        "classes_counted": total_counted,
        "classes_attended": total_attended,
        "status": (
            "no_attendance_data"
            if not total_counted
            else "critical"
            if total_attended / total_counted < 0.60
            else "attention_required"
            if total_attended / total_counted < 0.75
            else "normal"
        ),
    }
    return courses, attendance


def _result_context(db: Session, student: Student) -> dict:
    results = db.query(Result).filter(Result.student_id == student.id).all()
    course_by_id = {
        enrollment.course_offering.course_id: enrollment.course_offering.course
        for enrollment in db.query(StudentEnrollment)
        .filter(StudentEnrollment.student_id == student.id)
        .all()
    }
    items = []
    for result in results:
        course = course_by_id.get(result.course_id)
        items.append(
            {
                "course_code": course.code if course else None,
                "course_name": course.name if course else None,
                "grade": result.grade,
                "grade_point": result.grade_point,
                "marks": result.marks,
            }
        )
    return {
        "average_grade_point": (
            round(sum(float(item.grade_point) for item in results) / len(results), 2)
            if results
            else None
        ),
        "published_count": len(results),
        "items": items,
    }


def _timetable_context(db: Session, offering_ids: list[int]) -> list[dict]:
    entries = (
        db.query(TimetableEntryV2)
        .filter(
            TimetableEntryV2.course_offering_id.in_(offering_ids),
            TimetableEntryV2.is_active.is_(True),
        )
        .order_by(TimetableEntryV2.day_of_week, TimetableEntryV2.start_time)
        .all()
        if offering_ids
        else []
    )
    return [
        {
            "day": DAY_NAMES.get(item.day_of_week, str(item.day_of_week)),
            "start_time": item.start_time,
            "end_time": item.end_time,
            "course_code": item.course_offering.course.code,
            "course_name": item.course_offering.course.name,
            "room": item.room,
            "building": item.building,
            "faculty": item.faculty_name or item.course_offering.faculty_name,
        }
        for item in entries
    ]


def _examination_context(db: Session, student: Student) -> list[dict]:
    registrations = (
        db.query(ExaminationRegistrationV2)
        .filter(ExaminationRegistrationV2.student_id == student.id)
        .order_by(ExaminationRegistrationV2.id.desc())
        .all()
    )
    result = []
    for registration in registrations:
        papers = (
            db.query(ExaminationRegistrationPaperV2)
            .filter(ExaminationRegistrationPaperV2.registration_id == registration.id)
            .all()
        )
        result.append(
            {
                "name": registration.examination.name,
                "type": registration.examination.exam_type,
                "registration_number": registration.registration_number,
                "registration_status": registration.status,
                "start_date": registration.examination.start_date,
                "end_date": registration.examination.end_date,
                "papers": [
                    {
                        "course_code": item.schedule.course.code,
                        "course_name": item.schedule.course.name,
                        "date": item.schedule.exam_date,
                        "start_time": item.schedule.start_time,
                        "end_time": item.schedule.end_time,
                        "room": item.schedule.room,
                        "building": item.schedule.building,
                    }
                    for item in papers
                    if item.schedule is not None and item.schedule.is_active
                ],
            }
        )
    return result


def _fee_context(db: Session, student: Student) -> dict:
    invoices = (
        db.query(StudentFeeInvoiceV2)
        .filter(StudentFeeInvoiceV2.student_id == student.id)
        .order_by(StudentFeeInvoiceV2.id.desc())
        .all()
    )
    return {
        "total_invoiced": round(sum(float(item.total_amount or 0) for item in invoices), 2),
        "total_paid": round(sum(float(item.paid_amount or 0) for item in invoices), 2),
        "outstanding": round(sum(float(item.outstanding_amount or 0) for item in invoices), 2),
        "invoices": [
            {
                "invoice_number": item.invoice_number,
                "semester": item.semester,
                "total": item.total_amount,
                "paid": item.paid_amount,
                "outstanding": item.outstanding_amount,
                "due_date": item.due_date,
                "status": item.status,
            }
            for item in invoices
        ],
    }


def _hostel_context(db: Session, student: Student) -> dict:
    allocation = (
        db.query(HostelAllocationV2)
        .filter(
            HostelAllocationV2.student_id == student.id,
            HostelAllocationV2.status.in_({"allocated", "checked_in"}),
        )
        .order_by(HostelAllocationV2.id.desc())
        .first()
    )
    complaints = (
        db.query(HostelComplaintV2)
        .filter(HostelComplaintV2.student_id == student.id)
        .order_by(HostelComplaintV2.id.desc())
        .limit(5)
        .all()
    )
    return {
        "allocation": (
            {
                "allocation_number": allocation.allocation_number,
                "status": allocation.status,
                "building": allocation.room.building.name,
                "building_code": allocation.room.building.code,
                "room_number": allocation.room.room_number,
                "room_type": allocation.room.room_type,
                "floor": allocation.room.floor_number,
                "remarks": allocation.remarks,
            }
            if allocation
            else None
        ),
        "complaints": [
            {
                "number": item.complaint_number,
                "title": item.title,
                "category": item.category,
                "status": item.status,
                "resolution": item.resolution,
            }
            for item in complaints
        ],
    }


def _transport_context(db: Session, student: Student) -> dict:
    allocation = (
        db.query(StudentTransportAllocationV2)
        .filter(
            StudentTransportAllocationV2.student_id == student.id,
            StudentTransportAllocationV2.status == "active",
        )
        .order_by(StudentTransportAllocationV2.id.desc())
        .first()
    )
    vehicle = None
    if allocation:
        assignment = (
            db.query(TransportRouteAssignmentV2)
            .filter(
                TransportRouteAssignmentV2.route_id == allocation.route_id,
                TransportRouteAssignmentV2.academic_session == allocation.academic_session,
                TransportRouteAssignmentV2.is_active.is_(True),
            )
            .first()
        )
        vehicle = assignment.vehicle if assignment else None
    issues = (
        db.query(TransportIssueV2)
        .filter(TransportIssueV2.student_id == student.id)
        .order_by(TransportIssueV2.id.desc())
        .limit(5)
        .all()
    )
    return {
        "allocation": (
            {
                "allocation_number": allocation.allocation_number,
                "status": allocation.status,
                "route": allocation.route.name,
                "route_code": allocation.route.code,
                "stop": allocation.stop.name,
                "pickup_time": allocation.stop.pickup_time,
                "landmark": allocation.stop.landmark,
                "vehicle_number": vehicle.vehicle_number if vehicle else None,
                "driver_name": vehicle.driver_name if vehicle else None,
                "driver_contact": vehicle.driver_contact if vehicle else None,
            }
            if allocation
            else None
        ),
        "issues": [
            {
                "number": item.issue_number,
                "title": item.title,
                "status": item.status,
                "resolution": item.resolution,
            }
            for item in issues
        ],
    }


def _certificate_context(db: Session, student: Student) -> dict:
    certificates = (
        db.query(Certificate)
        .filter(Certificate.student_id == student.id)
        .order_by(Certificate.id.desc())
        .all()
    )
    requests = (
        db.query(CertificateRequest)
        .filter(CertificateRequest.student_id == student.id)
        .order_by(CertificateRequest.requested_at.desc())
        .all()
    )
    return {
        "issued": [
            {
                "certificate_number": item.certificate_id,
                "type": item.certificate_type,
                "title": item.title,
                "issue_date": item.issue_date,
                "status": item.status,
            }
            for item in certificates
        ],
        "requests": [
            {
                "request_number": item.request_number,
                "type": item.certificate_type,
                "purpose": item.purpose,
                "status": item.status,
                "remarks": item.review_remarks,
                "rejection_reason": item.rejection_reason,
            }
            for item in requests
        ],
    }


def _support_context(db: Session, student: Student) -> dict:
    tickets = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.student_id == student.id)
        .order_by(HelpdeskTicketV2.id.desc())
        .limit(10)
        .all()
    )
    warnings = (
        db.query(EarlyWarning)
        .filter(EarlyWarning.student_id == student.id, EarlyWarning.is_active.is_(True))
        .order_by(EarlyWarning.id.desc())
        .all()
    )
    interventions = (
        db.query(Intervention)
        .filter(Intervention.student_id == student.id)
        .order_by(Intervention.id.desc())
        .all()
    )
    return {
        "helpdesk_tickets": [
            {
                "number": item.ticket_number,
                "category": item.category.name,
                "subject": item.subject,
                "priority": item.priority,
                "status": item.status,
                "resolution": item.resolution,
            }
            for item in tickets
        ],
        "active_warnings": [
            {
                "type": item.warning_type,
                "severity": item.severity,
                "title": item.title,
                "message": item.message,
                "recommended_action": item.recommended_action,
                "status": item.status,
            }
            for item in warnings
        ],
        "interventions": [
            {
                "type": item.intervention_type,
                "advisor": item.assigned_to,
                "priority": item.priority,
                "reason": item.reason,
                "due_date": item.due_date,
                "status": item.status,
                "notes": item.notes,
                "outcome": item.outcome,
            }
            for item in interventions
        ],
    }


def build_student_context(db: Session, student: Student) -> dict:
    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )
    offering_ids = [item.course_offering_id for item in enrollments]
    courses, attendance = _course_context(db, student)
    fees = _fee_context(db, student)
    support = _support_context(db, student)
    return {
        "profile": {
            "uni_id": student.uni_id,
            "university_id": student.university_id,
            "enrollment_number": student.enrollment_number,
            "student_name": student.full_name,
            "programme": student.programme,
            "semester": student.current_semester,
            "academic_session": student.academic_session,
            "department": student.department.name if student.department else None,
        },
        # Summary keys retained for the existing API response contract.
        "uni_id": student.uni_id,
        "student_name": student.full_name,
        "programme": student.programme,
        "semester": student.current_semester,
        "attendance_percentage": attendance["percentage"],
        "outstanding_fee": fees["outstanding"],
        "academic_status": attendance["status"],
        "courses": courses,
        "attendance": attendance,
        "results": _result_context(db, student),
        "timetable": _timetable_context(db, offering_ids),
        "examinations": _examination_context(db, student),
        "fees": fees,
        "hostel": _hostel_context(db, student),
        "transport": _transport_context(db, student),
        "certificates": _certificate_context(db, student),
        **support,
        "recommendations": generate_recommendations(student, db),
    }
