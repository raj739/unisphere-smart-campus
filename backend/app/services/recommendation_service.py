from sqlalchemy.orm import Session

from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.course import Course
from app.models.result import Result
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2


ATTENDANCE_THRESHOLD = 75.0


def _attendance_recommendations(student: Student, db: Session) -> list[dict]:
    recommendations = []
    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )
    for enrollment in enrollments:
        offering = enrollment.course_offering
        sessions = (
            db.query(AttendanceSessionV2)
            .filter(AttendanceSessionV2.course_offering_id == offering.id)
            .all()
        )
        if not sessions:
            continue
        records = (
            db.query(AttendanceRecordV2)
            .filter(
                AttendanceRecordV2.student_id == student.id,
                AttendanceRecordV2.attendance_session_id.in_(
                    [session.id for session in sessions]
                ),
            )
            .all()
        )
        attended = sum(
            1 for record in records if record.status in {"present", "late"}
        )
        percentage = round((attended / len(sessions)) * 100, 2)
        if percentage >= ATTENDANCE_THRESHOLD:
            continue
        recommendations.append(
            {
                "type": "Attendance",
                "priority": "High" if percentage < 60 else "Medium",
                "title": f"Improve attendance in {offering.course.code}",
                "message": (
                    f"Attendance in {offering.course.name} is {percentage:.1f}%, "
                    f"below the {ATTENDANCE_THRESHOLD:.0f}% target."
                ),
                "action": (
                    "Attend the next scheduled classes and speak with the "
                    "faculty member about any attendance barriers."
                ),
                "reason": "Live class-session attendance is below target.",
            }
        )
    return recommendations


def _academic_recommendations(student: Student, db: Session) -> list[dict]:
    results = (
        db.query(Result)
        .filter(Result.student_id == student.id)
        .all()
    )
    if not results:
        return []
    recommendations = []
    average_grade_point = sum(float(item.grade_point or 0) for item in results) / len(results)
    if average_grade_point < 7:
        recommendations.append(
            {
                "type": "Academic",
                "priority": "High",
                "title": "Academic support recommended",
                "message": f"Your current average grade point is {average_grade_point:.1f}.",
                "action": "Meet your faculty advisor and agree on a weekly recovery plan.",
                "reason": "Published results indicate that academic support is needed.",
            }
        )
    elif average_grade_point < 8:
        recommendations.append(
            {
                "type": "Academic",
                "priority": "Medium",
                "title": "Strengthen academic performance",
                "message": f"Your average grade point is {average_grade_point:.1f}.",
                "action": "Focus on weaker papers and maintain a consistent study plan.",
                "reason": "There is a clear opportunity to improve your published results.",
            }
        )

    lower_results = sorted(
        [item for item in results if float(item.grade_point or 0) < 8],
        key=lambda item: float(item.grade_point or 0),
    )
    courses = {
        course.id: course
        for course in db.query(Course)
        .filter(Course.id.in_([item.course_id for item in lower_results[:2]]))
        .all()
    } if lower_results else {}
    for result in lower_results[:2]:
        course = courses.get(result.course_id)
        label = (
            f"{course.code} - {course.name}"
            if course is not None
            else "this course"
        )
        recommendations.append(
            {
                "type": "Study Plan",
                "priority": "Medium",
                "title": f"Focus on {course.code if course else 'a weaker paper'}",
                "message": f"Your grade point in {label} is {float(result.grade_point or 0):.1f}.",
                "action": "Allocate additional weekly study time and use faculty office hours.",
                "reason": "This paper is currently among your lower-performing results.",
            }
        )
    return recommendations


def _fee_recommendations(student: Student, db: Session) -> list[dict]:
    outstanding = sum(
        float(invoice.outstanding_amount or 0)
        for invoice in db.query(StudentFeeInvoiceV2)
        .filter(StudentFeeInvoiceV2.student_id == student.id)
        .all()
    )
    if outstanding <= 0:
        return []
    return [
        {
            "type": "Fees",
            "priority": "Medium",
            "title": "Review outstanding balance",
            "message": f"INR {outstanding:,.2f} is currently outstanding.",
            "action": "Review your invoice details and contact the accounts office if support is needed.",
            "reason": "A live student invoice has an outstanding balance.",
        }
    ]


def generate_recommendations(student: Student, db: Session) -> dict:
    recommendations = [
        *_attendance_recommendations(student, db),
        *_academic_recommendations(student, db),
        *_fee_recommendations(student, db),
    ]
    if any(item["priority"] == "High" for item in recommendations):
        overall_status = "Needs Attention"
    elif recommendations:
        overall_status = "Stable with Recommendations"
    else:
        overall_status = "On Track"
    return {
        "uni_id": student.uni_id,
        "student_name": student.full_name,
        "overall_status": overall_status,
        "recommendations": recommendations,
    }
