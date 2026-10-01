from sqlalchemy.orm import Session

from app.models.attendance import Attendance
from app.models.fee import FeeRecord
from app.models.result import Result
from app.models.student import Student
from app.services.gemini_service import (
    generate_gemini_response,
)
from app.services.rag_service import search_knowledge


def _build_student_context(
    student: Student,
    db: Session,
) -> str:

    attendances = (
        db.query(Attendance)
        .filter(
            Attendance.student_id == student.id
        )
        .all()
    )

    results = (
        db.query(Result)
        .filter(
            Result.student_id == student.id
        )
        .all()
    )

    fees = (
        db.query(FeeRecord)
        .filter(
            FeeRecord.student_id == student.id
        )
        .all()
    )

    context_parts = []

    context_parts.append(
        f"Student Name: {student.full_name}"
    )

    context_parts.append(
        f"Uni-ID: {student.uni_id}"
    )

    context_parts.append(
        f"Programme: {student.programme}"
    )

    context_parts.append(
        f"Current Semester: "
        f"{student.current_semester}"
    )

    # ---------------------------------------------
    # ATTENDANCE
    # ---------------------------------------------

    if attendances:

        context_parts.append(
            "\nATTENDANCE:"
        )

        for attendance in attendances:

            percentage = float(
                attendance.percentage or 0
            )

            context_parts.append(
                f"- Course ID: "
                f"{attendance.course_id}, "
                f"Classes Attended: "
                f"{attendance.classes_attended}/"
                f"{attendance.classes_held}, "
                f"Attendance: "
                f"{percentage:.1f}%"
            )

    # ---------------------------------------------
    # RESULTS
    # ---------------------------------------------

    if results:

        context_parts.append(
            "\nRESULTS:"
        )

        for result in results:

            context_parts.append(
                f"- Course ID: "
                f"{result.course_id}, "
                f"Grade: {result.grade}, "
                f"Grade Point: "
                f"{result.grade_point}, "
                f"Marks: {result.marks}"
            )

    # ---------------------------------------------
    # FEES
    # ---------------------------------------------

    if fees:

        context_parts.append(
            "\nFEES:"
        )

        for fee in fees:

            context_parts.append(
                f"- Academic Year: "
                f"{fee.academic_year}, "
                f"Semester: {fee.semester}, "
                f"Total: "
                f"₹{fee.total_amount:.2f}, "
                f"Paid: "
                f"₹{fee.paid_amount:.2f}, "
                f"Outstanding: "
                f"₹{fee.outstanding_amount:.2f}, "
                f"Due Date: "
                f"{fee.due_date}, "
                f"Status: {fee.status}"
            )

    return "\n".join(context_parts)


def _build_knowledge_context(
    message: str,
    db: Session,
) -> tuple[str, list[str]]:

    knowledge_results = search_knowledge(
        query=message,
        db=db,
        limit=3,
    )

    if not knowledge_results:

        return (
            "No matching university knowledge "
            "was found.",
            [],
        )

    parts = []
    sources = []

    for item in knowledge_results:

        parts.append(
            f"Title: {item['title']}\n"
            f"Category: {item['category']}\n"
            f"Content: {item['content']}\n"
            f"Source: {item.get('source')}"
        )

        sources.append(
            item["title"]
        )

    return (
        "\n\n".join(parts),
        sources,
    )


def generate_ai_response(
    message: str,
    student: Student,
    db: Session,
):

    student_context = _build_student_context(
        student=student,
        db=db,
    )

    knowledge_context, knowledge_sources = (
        _build_knowledge_context(
            message=message,
            db=db,
        )
    )

    combined_context = f"""
=== VERIFIED STUDENT DATA ===

{student_context}

=== VERIFIED UNIVERSITY KNOWLEDGE ===

{knowledge_context}
"""

    response = generate_gemini_response(
        message=message,
        context=combined_context,
    )

    lower_message = message.lower()

    if any(
        word in lower_message
        for word in [
            "attendance",
            "present",
            "absent",
        ]
    ):
        intent = "attendance"

    elif any(
        word in lower_message
        for word in [
            "cgpa",
            "result",
            "grade",
            "marks",
            "sgpa",
        ]
    ):
        intent = "academic_results"

    elif any(
        word in lower_message
        for word in [
            "fee",
            "fees",
            "payment",
            "outstanding",
        ]
    ):
        intent = "fees"

    elif any(
        word in lower_message
        for word in [
            "certificate",
            "verify",
            "bonafide",
        ]
    ):
        intent = "certificate"

    elif knowledge_sources:

        intent = "university_knowledge"

    else:

        intent = "general"

    return (
        response,
        intent,
        "gemini_rag",
        knowledge_sources,
    )