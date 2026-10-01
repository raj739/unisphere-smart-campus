from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role

from app.models.fee_structure_v2 import FeeStructure
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.student_fee_invoice_item_v2 import StudentFeeInvoiceItemV2
from app.models.student_fee_adjustment_v2 import StudentFeeAdjustmentV2
from app.models.programme import Programme
from app.models.student import Student
from app.models.user import User

from app.schemas.fee_v2 import (
    FeeStructureCreateRequest,
    FeeStructureResponse,
    InvoiceCreateRequest,
    InvoiceResponse,
    InvoiceItemResponse,
    FeeAdjustmentRequest,
    FeePaymentUpdateRequest,
)

router = APIRouter(
    prefix="/fees-v2",
    tags=["Fees"],
)


def new_invoice_number() -> str:
    """Create a readable number without relying on a race-prone row count."""
    date_part = datetime.now(timezone.utc).strftime("%Y%m%d")
    unique_part = uuid4().hex[:8].upper()
    return f"UNI-FEE-{date_part}-{unique_part}"


def get_student(student_id: int, db: Session) -> Student:
    student = (
        db.query(Student)
        .filter(Student.id == student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student not found",
        )

    return student


def get_invoice(invoice_id: int, db: Session) -> StudentFeeInvoiceV2:
    invoice = (
        db.query(StudentFeeInvoiceV2)
        .filter(StudentFeeInvoiceV2.id == invoice_id)
        .first()
    )

    if invoice is None:
        raise HTTPException(
            status_code=404,
            detail="Fee invoice not found",
        )

    return invoice


def calculate_status(invoice: StudentFeeInvoiceV2) -> str:
    if invoice.outstanding_amount <= 0:
        return "paid"

    if invoice.paid_amount > 0:
        return "partially_paid"

    return "pending"


def invoice_response(
    invoice: StudentFeeInvoiceV2,
    db: Session,
):
    items = (
        db.query(StudentFeeInvoiceItemV2)
        .filter(
            StudentFeeInvoiceItemV2.invoice_id == invoice.id
        )
        .all()
    )

    return {
        "id": invoice.id,
        "student_id": invoice.student_id,
        "academic_session": invoice.academic_session,
        "semester": invoice.semester,
        "invoice_number": invoice.invoice_number,
        "total_amount": invoice.total_amount,
        "discount_amount": invoice.discount_amount,
        "waiver_amount": invoice.waiver_amount,
        "paid_amount": invoice.paid_amount,
        "outstanding_amount": invoice.outstanding_amount,
        "due_date": invoice.due_date,
        "status": invoice.status,
        "items": items,
    }


@router.post(
    "/structures",
    response_model=FeeStructureResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_fee_structure(
    payload: FeeStructureCreateRequest,
    db: Session = Depends(get_db),
):
    programme = (
        db.query(Programme)
        .filter(Programme.id == payload.programme_id)
        .first()
    )

    if programme is None:
        raise HTTPException(
            status_code=404,
            detail="Programme not found",
        )

    structure = FeeStructure(
        programme_id=payload.programme_id,
        semester=payload.semester,
        academic_session=payload.academic_session,
        fee_type=payload.fee_type,
        amount=payload.amount,
        mandatory=payload.mandatory,
        is_active=True,
    )

    db.add(structure)
    db.commit()
    db.refresh(structure)

    return structure


@router.get(
    "/structures",
    response_model=list[FeeStructureResponse],
)
def list_fee_structures(
    programme_id: int | None = None,
    semester: int | None = None,
    academic_session: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(FeeStructure).filter(
        FeeStructure.is_active.is_(True)
    )

    if programme_id is not None:
        query = query.filter(
            FeeStructure.programme_id == programme_id
        )

    if semester is not None:
        query = query.filter(
            FeeStructure.semester == semester
        )

    if academic_session is not None:
        query = query.filter(
            FeeStructure.academic_session == academic_session
        )

    return query.order_by(FeeStructure.id.desc()).all()


@router.post(
    "/invoices",
    response_model=InvoiceResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_invoice(
    payload: InvoiceCreateRequest,
    db: Session = Depends(get_db),
):
    student = get_student(payload.student_id, db)

    total = sum(item.amount for item in payload.items)

    invoice = StudentFeeInvoiceV2(
        student_id=student.id,
        academic_session=payload.academic_session,
        semester=payload.semester,
        invoice_number=new_invoice_number(),
        total_amount=total,
        discount_amount=0.0,
        waiver_amount=0.0,
        paid_amount=0.0,
        outstanding_amount=total,
        due_date=payload.due_date,
        status="pending",
    )

    db.add(invoice)
    db.flush()

    for item in payload.items:
        invoice_item = StudentFeeInvoiceItemV2(
            invoice_id=invoice.id,
            fee_type=item.fee_type,
            description=item.description,
            amount=item.amount,
        )

        db.add(invoice_item)

    db.commit()
    db.refresh(invoice)

    return invoice_response(invoice, db)


@router.get(
    "/me",
    response_model=list[InvoiceResponse],
)
def my_fees(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found",
        )

    invoices = (
        db.query(StudentFeeInvoiceV2)
        .filter(
            StudentFeeInvoiceV2.student_id == student.id
        )
        .order_by(StudentFeeInvoiceV2.id.desc())
        .all()
    )

    return [
        invoice_response(invoice, db)
        for invoice in invoices
    ]


@router.get(
    "/invoices/{invoice_id}",
    response_model=InvoiceResponse,
)
def get_my_invoice(
    invoice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    invoice = get_invoice(invoice_id, db)

    if current_user.role != "admin":
        student = (
            db.query(Student)
            .filter(Student.user_id == current_user.id)
            .first()
        )

        if student is None or invoice.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this invoice",
            )

    return invoice_response(invoice, db)


@router.get(
    "/admin/invoices",
    response_model=list[InvoiceResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_all_invoices(
    student_id: int | None = None,
    status: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(StudentFeeInvoiceV2)

    if student_id is not None:
        query = query.filter(
            StudentFeeInvoiceV2.student_id == student_id
        )

    if status is not None:
        query = query.filter(
            StudentFeeInvoiceV2.status == status
        )

    invoices = query.order_by(
        StudentFeeInvoiceV2.id.desc()
    ).all()

    return [
        invoice_response(invoice, db)
        for invoice in invoices
    ]


@router.post(
    "/invoices/{invoice_id}/adjustments",
    response_model=InvoiceResponse,
    dependencies=[Depends(require_role("admin"))],
)
def add_adjustment(
    invoice_id: int,
    payload: FeeAdjustmentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    invoice = get_invoice(invoice_id, db)

    if payload.amount > invoice.outstanding_amount:
        raise HTTPException(
            status_code=400,
            detail="Adjustment cannot exceed outstanding amount",
        )

    adjustment_type = payload.adjustment_type.lower()

    if adjustment_type not in {
        "discount",
        "scholarship",
        "waiver",
    }:
        raise HTTPException(
            status_code=400,
            detail="Invalid adjustment type",
        )

    adjustment = StudentFeeAdjustmentV2(
        student_id=invoice.student_id,
        invoice_id=invoice.id,
        adjustment_type=adjustment_type,
        amount=payload.amount,
        reason=payload.reason,
        approved_by_user_id=current_user.id,
    )

    db.add(adjustment)

    if adjustment_type == "discount":
        invoice.discount_amount += payload.amount
    else:
        invoice.waiver_amount += payload.amount

    invoice.outstanding_amount = max(
        invoice.total_amount
        - invoice.discount_amount
        - invoice.waiver_amount
        - invoice.paid_amount,
        0.0,
    )

    invoice.status = calculate_status(invoice)

    db.commit()
    db.refresh(invoice)

    return invoice_response(invoice, db)


@router.post(
    "/invoices/{invoice_id}/record-payment",
    response_model=InvoiceResponse,
    dependencies=[Depends(require_role("admin"))],
)
def record_payment(
    invoice_id: int,
    payload: FeePaymentUpdateRequest,
    db: Session = Depends(get_db),
):
    invoice = get_invoice(invoice_id, db)

    if payload.amount > invoice.outstanding_amount:
        raise HTTPException(
            status_code=400,
            detail="Payment cannot exceed outstanding amount",
        )

    invoice.paid_amount += payload.amount

    invoice.outstanding_amount = max(
        invoice.total_amount
        - invoice.discount_amount
        - invoice.waiver_amount
        - invoice.paid_amount,
        0.0,
    )

    invoice.status = calculate_status(invoice)

    db.commit()
    db.refresh(invoice)

    return invoice_response(invoice, db)
