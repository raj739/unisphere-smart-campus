from app.core.database import SessionLocal
from app.models.certificate import Certificate
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

    certificates = [
        {
            "certificate_id": "CERT-VU-BCA-2026-0001",
            "certificate_type": "Degree",
            "title": "Bachelor of Computer Applications",
            "issue_date": "2027-06-30",
            "status": "Valid",
            "verification_token": "VERIFY-VU-0001",
        },
        {
            "certificate_id": "CERT-VU-BCA-2026-0002",
            "certificate_type": "Bonafide",
            "title": "Bonafide Certificate",
            "issue_date": "2026-09-15",
            "status": "Valid",
            "verification_token": "VERIFY-VU-0002",
        },
        {
            "certificate_id": "CERT-VU-BCA-2026-0003",
            "certificate_type": "Character",
            "title": "Character Certificate",
            "issue_date": "2026-09-15",
            "status": "Valid",
            "verification_token": "VERIFY-VU-0003",
        },
    ]

    for data in certificates:
        existing = (
            db.query(Certificate)
            .filter(
                Certificate.certificate_id
                == data["certificate_id"]
            )
            .first()
        )

        if existing is None:
            certificate = Certificate(
                student_id=student.id,
                certificate_id=data["certificate_id"],
                certificate_type=data["certificate_type"],
                title=data["title"],
                issue_date=data["issue_date"],
                status=data["status"],
                verification_token=data["verification_token"],
            )

            db.add(certificate)

            print(
                f"Certificate created: "
                f"{data['certificate_id']}"
            )
        else:
            print(
                f"Certificate already exists: "
                f"{data['certificate_id']}"
            )

    db.commit()

    print("")
    print("Certificate demo data seeded successfully.")
    print("Certificates: 3")

finally:
    db.close()
