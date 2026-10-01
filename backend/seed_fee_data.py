from app.core.database import SessionLocal
from app.models.fee import FeeRecord
from app.models.payment import Payment
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
    # Fee record
    # ---------------------------------------------------------

    fee = (
        db.query(FeeRecord)
        .filter(
            FeeRecord.student_id == student.id,
            FeeRecord.academic_year == "2026-2027",
            FeeRecord.semester == student.current_semester,
        )
        .first()
    )

    if fee is None:
        fee = FeeRecord(
            student_id=student.id,
            academic_year="2026-2027",
            semester=student.current_semester,
            total_amount=48500,
            paid_amount=44000,
            outstanding_amount=4500,
            due_date="2026-09-30",
            status="Partially Paid",
        )

        db.add(fee)
        db.flush()

        print("Fee record created.")
    else:
        print("Fee record already exists.")

    # ---------------------------------------------------------
    # Payment 1
    # ---------------------------------------------------------

    payment = (
        db.query(Payment)
        .filter(
            Payment.transaction_id == "TXN-VU-2026-0001"
        )
        .first()
    )

    if payment is None:
        db.add(
            Payment(
                student_id=student.id,
                fee_record_id=fee.id,
                amount=25000,
                payment_date="2026-08-15",
                payment_method="UPI",
                transaction_id="TXN-VU-2026-0001",
                status="Success",
            )
        )
        print("Payment 1 created.")
    else:
        print("Payment 1 already exists.")

    # ---------------------------------------------------------
    # Payment 2
    # ---------------------------------------------------------

    payment = (
        db.query(Payment)
        .filter(
            Payment.transaction_id == "TXN-VU-2026-0002"
        )
        .first()
    )

    if payment is None:
        db.add(
            Payment(
                student_id=student.id,
                fee_record_id=fee.id,
                amount=19000,
                payment_date="2026-07-10",
                payment_method="Net Banking",
                transaction_id="TXN-VU-2026-0002",
                status="Success",
            )
        )
        print("Payment 2 created.")
    else:
        print("Payment 2 already exists.")

    db.commit()

    print("")
    print("Fee demo data seeded successfully.")
    print("Semester Fee: ₹48,500")
    print("Paid: ₹44,000")
    print("Outstanding: ₹4,500")
    print("Payments: 2")

finally:
    db.close()
