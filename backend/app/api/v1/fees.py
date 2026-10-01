from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.fee import FeeRecord
from app.models.payment import Payment
from app.models.student import Student
from app.models.user import User


router = APIRouter(
    prefix="/fees",
    tags=["Fees & Payments"],
)


def get_current_student(
    current_user: User,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


@router.get("")
def get_my_fees(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(FeeRecord)
        .filter(FeeRecord.student_id == student.id)
        .order_by(FeeRecord.id.desc())
        .all()
    )

    return [
        {
            "id": fee.id,
            "academic_year": fee.academic_year,
            "semester": fee.semester,
            "total_amount": fee.total_amount,
            "paid_amount": fee.paid_amount,
            "outstanding_amount": fee.outstanding_amount,
            "due_date": fee.due_date,
            "status": fee.status,
        }
        for fee in records
    ]


@router.get("/payments")
def get_my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(Payment)
        .filter(Payment.student_id == student.id)
        .order_by(Payment.id.desc())
        .all()
    )

    return [
        {
            "id": payment.id,
            "fee_record_id": payment.fee_record_id,
            "amount": payment.amount,
            "payment_date": payment.payment_date,
            "payment_method": payment.payment_method,
            "transaction_id": payment.transaction_id,
            "status": payment.status,
        }
        for payment in records
    ]


@router.get("/summary")
def get_fee_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    fee = (
        db.query(FeeRecord)
        .filter(
            FeeRecord.student_id == student.id,
            FeeRecord.semester == student.current_semester,
        )
        .order_by(FeeRecord.id.desc())
        .first()
    )

    if fee is None:
        return {
            "total_amount": 0,
            "paid_amount": 0,
            "outstanding_amount": 0,
            "due_date": None,
            "status": "No fee record",
        }

    return {
        "total_amount": fee.total_amount,
        "paid_amount": fee.paid_amount,
        "outstanding_amount": fee.outstanding_amount,
        "due_date": fee.due_date,
        "status": fee.status,
    }
