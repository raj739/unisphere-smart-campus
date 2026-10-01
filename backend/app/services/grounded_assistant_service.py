from datetime import datetime


def _contains(message: str, *terms: str) -> bool:
    return any(term in message for term in terms)


def _money(value) -> str:
    return f"INR {float(value or 0):,.2f}"


def _value(value, fallback: str = "not available") -> str:
    return str(value) if value not in (None, "") else fallback


def _attendance_answer(context: dict) -> str:
    attendance = context.get("attendance", {})
    percentage = attendance.get("percentage")
    if percentage is None:
        return "Attendance data has not been recorded for your active courses yet."
    lines = [
        f"Your overall attendance is {percentage:.1f}% "
        f"({attendance.get('classes_attended', 0)} of "
        f"{attendance.get('classes_counted', 0)} counted classes)."
    ]
    low_courses = [
        item
        for item in context.get("courses", [])
        if item.get("attendance_percentage") is not None
        and item["attendance_percentage"] < 75
    ]
    if low_courses:
        lines.append("Courses below the 75% target:")
        lines.extend(
            f"- {item['code']} - {item['name']}: "
            f"{item['attendance_percentage']:.1f}%"
            for item in low_courses
        )
        lines.append(
            "Attend upcoming classes consistently and contact the faculty member "
            "if an absence has been recorded incorrectly."
        )
    else:
        lines.append("No active course is currently below the 75% target.")
    return "\n".join(lines)


def _results_answer(context: dict) -> str:
    results = context.get("results", {})
    items = results.get("items", [])
    if not items:
        return "No published results are available in your account yet."
    average = results.get("average_grade_point")
    lines = [f"Your current average grade point is {average:.2f}."]
    lines.extend(
        f"- {_value(item.get('course_code'), 'Course')}: "
        f"grade {_value(item.get('grade'))}, "
        f"grade point {float(item.get('grade_point') or 0):.1f}, "
        f"marks {_value(item.get('marks'))}"
        for item in items
    )
    return "\n".join(lines)


def _timetable_answer(context: dict, message: str) -> str:
    entries = context.get("timetable", [])
    if not entries:
        return "No active timetable entries are available for your enrolled courses."
    today = datetime.now().strftime("%A")
    requested_day = next(
        (
            day
            for day in (
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
            )
            if day.lower() in message
        ),
        None,
    )
    if _contains(message, "today", "aaj", "आज"):
        requested_day = today
    selected = [item for item in entries if item["day"] == requested_day] if requested_day else entries
    if requested_day and not selected:
        return f"You have no timetable entries on {requested_day}."
    heading = f"Your {requested_day} timetable:" if requested_day else "Your weekly timetable:"
    lines = [heading]
    lines.extend(
        f"- {item['day']} {item['start_time']}-{item['end_time']}: "
        f"{item['course_code']} - {item['course_name']}, "
        f"{_value(item.get('building'), '')} {_value(item.get('room'), '').strip()}".rstrip()
        for item in selected
    )
    return "\n".join(lines)


def _examination_answer(context: dict) -> str:
    exams = context.get("examinations", [])
    if not exams:
        return "No examination registration is available in your account."
    lines = []
    for exam in exams:
        lines.append(
            f"{exam['name']} - registration {exam['registration_status']} "
            f"({_value(exam.get('registration_number'))})."
        )
        if exam.get("papers"):
            lines.extend(
                f"- {paper['date']} {paper['start_time']}-{paper['end_time']}: "
                f"{paper['course_code']} - {paper['course_name']}, "
                f"{_value(paper.get('building'), '')} {_value(paper.get('room'), '').strip()}".rstrip()
                for paper in exam["papers"]
            )
        else:
            lines.append("- The paper schedule has not been published yet.")
    return "\n".join(lines)


def _fees_answer(context: dict) -> str:
    fees = context.get("fees", {})
    invoices = fees.get("invoices", [])
    if not invoices:
        return "No fee invoice is available in your account."
    lines = [
        f"Fee summary: invoiced {_money(fees.get('total_invoiced'))}, "
        f"paid {_money(fees.get('total_paid'))}, and "
        f"outstanding {_money(fees.get('outstanding'))}."
    ]
    lines.extend(
        f"- {item['invoice_number']}: {_money(item.get('outstanding'))} outstanding, "
        f"status {item['status']}, due {_value(item.get('due_date'))}."
        for item in invoices
    )
    lines.append("Use the Fees section to review invoice and payment details.")
    return "\n".join(lines)


def _hostel_answer(context: dict) -> str:
    hostel = context.get("hostel", {})
    allocation = hostel.get("allocation")
    if not allocation:
        return "You do not currently have an active hostel allocation."
    lines = [
        f"Your hostel allocation is {allocation['building']} "
        f"({allocation['building_code']}), room {allocation['room_number']}, "
        f"floor {_value(allocation.get('floor'))}, "
        f"type {allocation['room_type']}, status {allocation['status']}."
    ]
    complaints = hostel.get("complaints", [])
    if complaints:
        lines.append("Recent hostel complaints:")
        lines.extend(
            f"- {item['number']}: {item['title']} - {item['status']}"
            for item in complaints
        )
    return "\n".join(lines)


def _transport_answer(context: dict) -> str:
    transport = context.get("transport", {})
    allocation = transport.get("allocation")
    if not allocation:
        return "You do not currently have an active transport allocation."
    lines = [
        f"Your route is {allocation['route']} ({allocation['route_code']}).",
        f"Pickup stop: {allocation['stop']} at "
        f"{_value(allocation.get('pickup_time'))}. "
        f"Landmark: {_value(allocation.get('landmark'))}.",
        f"Vehicle: {_value(allocation.get('vehicle_number'))}; "
        f"driver: {_value(allocation.get('driver_name'))}; "
        f"contact: {_value(allocation.get('driver_contact'))}.",
    ]
    issues = transport.get("issues", [])
    if issues:
        lines.append("Recent transport issues:")
        lines.extend(
            f"- {item['number']}: {item['title']} - {item['status']}"
            for item in issues
        )
    return "\n".join(lines)


def _certificate_answer(context: dict) -> str:
    certificates = context.get("certificates", {})
    issued = certificates.get("issued", [])
    requests = certificates.get("requests", [])
    lines = []
    if issued:
        lines.append("Issued certificates:")
        lines.extend(
            f"- {item['title']} ({item['certificate_number']}), "
            f"issued {item['issue_date']}, status {item['status']}"
            for item in issued
        )
    if requests:
        lines.append("Certificate requests:")
        lines.extend(
            f"- {item['request_number']}: {item['type'].replace('_', ' ').title()} - "
            f"{item['status']}"
            for item in requests
        )
    if not lines:
        return (
            "You have no certificate or active certificate request yet. "
            "Open Certificates to request an eligible non-academic certificate."
        )
    lines.append("Open Certificates to download issued items or submit a new request.")
    return "\n".join(lines)


def _helpdesk_answer(context: dict) -> str:
    tickets = context.get("helpdesk_tickets", [])
    if not tickets:
        return (
            "You have no helpdesk tickets. Open Helpdesk to create a ticket, "
            "choose a category, set the priority, and track the response."
        )
    lines = ["Your recent helpdesk tickets:"]
    lines.extend(
        f"- {item['number']}: {item['subject']} - {item['status']} "
        f"({item['priority']} priority)"
        for item in tickets
    )
    return "\n".join(lines)


def _success_answer(context: dict) -> str:
    warnings = context.get("active_warnings", [])
    interventions = context.get("interventions", [])
    lines = []
    if warnings:
        lines.append("Active support alerts:")
        lines.extend(
            f"- {item['severity']} - {item['title']}: {item['recommended_action']}"
            for item in warnings
        )
    else:
        lines.append("You have no active support alerts.")
    active_cases = [
        item
        for item in interventions
        if str(item.get("status", "")).lower() not in {"completed", "cancelled"}
    ]
    if active_cases:
        lines.append("Active support cases:")
        lines.extend(
            f"- {item['type']}: advisor {_value(item.get('advisor'), 'to be assigned')}, "
            f"status {item['status']}, due {_value(item.get('due_date'))}"
            for item in active_cases
        )
    return "\n".join(lines)


def _recommendation_answer(context: dict) -> str:
    data = context.get("recommendations", {})
    items = data.get("recommendations", [])
    if not items:
        return "Your current records are on track and no additional action is recommended."
    lines = [f"Your current status is {data.get('overall_status', 'assessed')}."]
    lines.extend(
        f"- {item['title']}: {item['action']}"
        for item in items[:5]
    )
    return "\n".join(lines)


def answer_student_question(
    message: str,
    context: dict,
    knowledge_context: list[dict] | None = None,
) -> tuple[str | None, str]:
    """Return a verified local answer and its source, or None for provider use."""
    normalized = " ".join(message.lower().split())
    sections = []

    if _contains(normalized, "attendance", "present", "absent", "hazri", "उपस्थिति"):
        sections.append(_attendance_answer(context))
    if _contains(normalized, "result", "marks", "grade", "cgpa", "sgpa", "अंक", "परिणाम"):
        sections.append(_results_answer(context))
    timetable_intent = _contains(
        normalized,
        "timetable",
        "time table",
        "class",
        "aaj",
        "today",
        "आज",
    ) or (
        "schedule" in normalized
        and not _contains(normalized, "exam", "examination", "paper", "परीक्षा")
    )
    if timetable_intent:
        sections.append(_timetable_answer(context, normalized))
    exam_preparation = _contains(
        normalized,
        "prepare",
        "preparation",
        "study for",
        "तैयारी",
    )
    if not exam_preparation and _contains(
        normalized,
        "exam",
        "examination",
        "paper",
        "admit card",
        "परीक्षा",
    ):
        sections.append(_examination_answer(context))
    if _contains(normalized, "fee", "fees", "invoice", "payment", "due", "फीस", "भुगतान"):
        sections.append(_fees_answer(context))
    if _contains(normalized, "hostel", "room", "building", "warden", "छात्रावास"):
        sections.append(_hostel_answer(context))
    if _contains(normalized, "transport", "bus", "route", "pickup", "driver", "बस"):
        sections.append(_transport_answer(context))
    if _contains(normalized, "certificate", "bonafide", "migration", "प्रमाणपत्र"):
        sections.append(_certificate_answer(context))
    if _contains(normalized, "helpdesk", "ticket", "complaint", "grievance", "शिकायत"):
        sections.append(_helpdesk_answer(context))
    if _contains(normalized, "risk", "warning", "intervention", "support case", "dropout"):
        sections.append(_success_answer(context))
    if _contains(normalized, "recommend", "improve", "what next", "study plan", "advice"):
        sections.append(_recommendation_answer(context))

    if sections:
        return "\n\n".join(dict.fromkeys(sections)), "live_student_record"

    profile = context.get("profile", {})
    if _contains(normalized, "my profile", "who am i", "my id", "enrollment number"):
        return (
            f"You are {profile.get('student_name')}, student ID "
            f"{_value(profile.get('university_id') or profile.get('uni_id'))}, "
            f"enrolled in {profile.get('programme')}, semester "
            f"{profile.get('semester')}. Enrollment number: "
            f"{_value(profile.get('enrollment_number'))}.",
            "live_student_record",
        )
    if _contains(normalized, "course", "subject", "faculty", "teacher"):
        courses = context.get("courses", [])
        if not courses:
            return "No active course enrollment is available in your account.", "live_student_record"
        return (
            "Your active courses:\n"
            + "\n".join(
                f"- {item['code']} - {item['name']} "
                f"({_value(item.get('faculty'), 'faculty not assigned')})"
                for item in courses
            ),
            "live_student_record",
        )
    if _contains(normalized, "hello", "hi", "hey", "namaste", "नमस्ते"):
        return (
            f"Hello {profile.get('student_name', 'Student')}. I can help with your "
            "courses, attendance, results, timetable, examinations, fees, hostel, "
            "transport, certificates, helpdesk, and student-success support.",
            "assistant_capabilities",
        )
    if _contains(normalized, "what can you", "help me", "features", "sections"):
        return (
            "I can read your live UniSphere record and explain courses, attendance, "
            "results, timetable, examinations, fees, hostel, transport, certificates, "
            "helpdesk tickets, warnings, interventions, and personalized recommendations. "
            "I can explain and guide you, but I will not submit or approve an action "
            "without an explicit supported workflow.",
            "assistant_capabilities",
        )

    if knowledge_context:
        document = knowledge_context[0]
        return (
            f"Based on verified campus guidance ({document['title']}):\n"
            f"{document['content']}",
            "verified_knowledge",
        )
    return None, "external_provider"
