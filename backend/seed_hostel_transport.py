from app.core.database import SessionLocal
from app.models.hostel import HostelAllocation
from app.models.hostel_complaint import HostelComplaint
from app.models.transport import TransportAllocation
from app.models.transport_issue import TransportIssue
from app.models.student import Student


db = SessionLocal()

try:
    student = (
        db.query(Student)
        .filter(
            Student.uni_id == "UNI-MP-VU-BCA-2026-001247"
        )
        .first()
    )

    if student is None:
        print("Aarav student profile not found.")
        raise SystemExit

    # ---------------------------------------------------------
    # Hostel allocation
    # ---------------------------------------------------------

    hostel = (
        db.query(HostelAllocation)
        .filter(
            HostelAllocation.student_id == student.id
        )
        .first()
    )

    if hostel is None:
        hostel = HostelAllocation(
            student_id=student.id,
            hostel_name="Vikram Boys Hostel",
            block="Block B",
            room_number="B-204",
            bed_number="02",
            sharing_type="Triple Sharing",
            academic_year="2026-2027",
            fee_amount=18000,
            warden_name="Dr Suresh Patel",
            status="Allocated",
        )

        db.add(hostel)
        print("Hostel allocation created.")
    else:
        print("Hostel allocation already exists.")

    # ---------------------------------------------------------
    # Hostel complaints
    # ---------------------------------------------------------

    hostel_complaints = [
        {
            "complaint_number": "HST-2026-001",
            "subject": "Hostel Wi-Fi Issue",
            "description": "Wi-Fi connectivity issue in Block B.",
            "status": "Resolved",
            "priority": "Low",
            "created_date": "2026-09-12",
        },
        {
            "complaint_number": "HST-2026-002",
            "subject": "Room Maintenance",
            "description": "Electrical maintenance requested for room B-204.",
            "status": "In Progress",
            "priority": "Medium",
            "created_date": "2026-09-18",
        },
    ]

    for data in hostel_complaints:
        existing = (
            db.query(HostelComplaint)
            .filter(
                HostelComplaint.complaint_number
                == data["complaint_number"]
            )
            .first()
        )

        if existing is None:
            db.add(
                HostelComplaint(
                    student_id=student.id,
                    complaint_number=data["complaint_number"],
                    subject=data["subject"],
                    description=data["description"],
                    status=data["status"],
                    priority=data["priority"],
                    created_date=data["created_date"],
                )
            )

            print(
                f"Hostel complaint created: "
                f"{data['complaint_number']}"
            )
        else:
            print(
                f"Hostel complaint already exists: "
                f"{data['complaint_number']}"
            )

    # ---------------------------------------------------------
    # Transport allocation
    # ---------------------------------------------------------

    transport = (
        db.query(TransportAllocation)
        .filter(
            TransportAllocation.student_id == student.id
        )
        .first()
    )

    if transport is None:
        transport = TransportAllocation(
            student_id=student.id,
            route_number="R-07",
            bus_number="MP-13-AB-2045",
            pass_status="Active",
            driver_name="Rajendra Singh",
            departure_time="08:10 AM",
            university_arrival="08:50 AM",
            status="Active",
        )

        db.add(transport)
        print("Transport allocation created.")
    else:
        print("Transport allocation already exists.")

    # ---------------------------------------------------------
    # Transport issues
    # ---------------------------------------------------------

    transport_issues = [
        {
            "issue_number": "TRN-2026-001",
            "subject": "Transport Pass Renewal",
            "description": "Transport pass renewal request.",
            "status": "Closed",
            "created_date": "2026-09-05",
        },
    ]

    for data in transport_issues:
        existing = (
            db.query(TransportIssue)
            .filter(
                TransportIssue.issue_number
                == data["issue_number"]
            )
            .first()
        )

        if existing is None:
            db.add(
                TransportIssue(
                    student_id=student.id,
                    issue_number=data["issue_number"],
                    subject=data["subject"],
                    description=data["description"],
                    status=data["status"],
                    created_date=data["created_date"],
                )
            )

            print(
                f"Transport issue created: "
                f"{data['issue_number']}"
            )
        else:
            print(
                f"Transport issue already exists: "
                f"{data['issue_number']}"
            )

    db.commit()

    print("")
    print("Hostel & Transport demo data seeded successfully.")
    print("Hostel allocation: 1")
    print("Hostel complaints: 2")
    print("Transport allocation: 1")
    print("Transport issues: 1")

finally:
    db.close()
