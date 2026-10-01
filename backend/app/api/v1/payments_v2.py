from datetime import datetime, timezone
import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role

from app.models.payment_transaction_v2 import PaymentTransactionV2
from app.models.payment_event_v2 import PaymentEventV2
from app.models.payment_receipt_v2 import PaymentReceiptV2
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.models.student import Student
from app.models.user import User

from app.schemas.payment_v2 import (
    PaymentInitiateRequest,
    PaymentTransactionResponse,
    PaymentVerifyRequest,
    PaymentWebhookRequest,
    PaymentReceiptResponse,
)

from app.services.payment_gateway import get_payment_gateway

router = APIRouter(
    prefix="/payments-v2",
    tags=["Payments"],
)


def get_invoice(
    invoice_id: int,
    db: Session,
) -> StudentFeeInvoiceV2:
    invoice = (
        db.query(StudentFeeInvoiceV2)
        .filter(
            StudentFeeInvoiceV2.id == invoice_id
        )
        .first()
    )

    if invoice is None:
        raise HTTPException(
            status_code=404,
            detail="Fee invoice not found",
        )

    return invoice


def get_transaction(
    transaction_id: int,
    db: Session,
) -> PaymentTransactionV2:
    transaction = (
        db.query(PaymentTransactionV2)
        .filter(
            PaymentTransactionV2.id == transaction_id
        )
        .first()
    )

    if transaction is None:
        raise HTTPException(
            status_code=404,
            detail="Payment transaction not found",
        )

    return transaction


def generate_transaction_number() -> str:
    return (
        f"PAY-{datetime.now().strftime('%Y%m%d')}-"
        f"{secrets.token_hex(5).upper()}"
    )


def generate_receipt_number() -> str:
    return (
        f"RCPT-{datetime.now().strftime('%Y%m%d')}-"
        f"{secrets.token_hex(5).upper()}"
    )


def update_invoice_after_payment(
    invoice: StudentFeeInvoiceV2,
    amount: float,
):
    invoice.paid_amount += amount

    invoice.outstanding_amount = max(
        invoice.total_amount
        - invoice.discount_amount
        - invoice.waiver_amount
        - invoice.paid_amount,
        0.0,
    )

    if invoice.outstanding_amount <= 0:
        invoice.status = "paid"
    else:
        invoice.status = "partially_paid"


def get_student_for_user(
    current_user: User,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(
            Student.user_id == current_user.id
        )
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found",
        )

    return student


@router.post(
    "/initiate",
    response_model=PaymentTransactionResponse,
)
def initiate_payment(
    payload: PaymentInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    invoice = get_invoice(
        payload.invoice_id,
        db,
    )

    student = get_student_for_user(
        current_user,
        db,
    )

    if invoice.student_id != student.id:
        raise HTTPException(
            status_code=403,
            detail="You cannot pay this invoice",
        )

    if invoice.status == "paid":
        raise HTTPException(
            status_code=409,
            detail="Invoice is already fully paid",
        )

    if payload.amount > invoice.outstanding_amount:
        raise HTTPException(
            status_code=400,
            detail="Payment amount exceeds outstanding amount",
        )

    existing = (
        db.query(PaymentTransactionV2)
        .filter(
            PaymentTransactionV2.idempotency_key
            == payload.idempotency_key
        )
        .first()
    )

    if existing is not None:
        return existing

    transaction = PaymentTransactionV2(
        invoice_id=invoice.id,
        student_id=student.id,
        transaction_number=generate_transaction_number(),
        idempotency_key=payload.idempotency_key,
        amount=payload.amount,
        currency="INR",
        payment_method=payload.payment_method,
        status="initiated",
    )

    db.add(transaction)
    db.flush()

    gateway = get_payment_gateway()

    order = gateway.create_order(
        transaction_number=transaction.transaction_number,
        amount=transaction.amount,
        currency=transaction.currency,
    )

    transaction.gateway_name = order.gateway_name
    transaction.gateway_order_id = order.gateway_order_id
    transaction.status = "pending"

    db.commit()
    db.refresh(transaction)

    return transaction


@router.get(
    "/me",
    response_model=list[PaymentTransactionResponse],
)
def my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_for_user(
        current_user,
        db,
    )

    return (
        db.query(PaymentTransactionV2)
        .filter(
            PaymentTransactionV2.student_id
            == student.id
        )
        .order_by(
            PaymentTransactionV2.id.desc()
        )
        .all()
    )


@router.get(
    "/{transaction_id}",
    response_model=PaymentTransactionResponse,
)
def get_my_payment(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = get_transaction(
        transaction_id,
        db,
    )

    if current_user.role != "admin":
        student = get_student_for_user(
            current_user,
            db,
        )

        if transaction.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this payment",
            )

    return transaction


@router.post(
    "/{transaction_id}/verify",
    response_model=PaymentTransactionResponse,
    dependencies=[Depends(require_role("admin"))],
)
def verify_payment(
    transaction_id: int,
    payload: PaymentVerifyRequest,
    db: Session = Depends(get_db),
):
    transaction = get_transaction(
        transaction_id,
        db,
    )

    if transaction.status == "success":
        return transaction

    transaction.gateway_transaction_id = (
        payload.gateway_transaction_id
    )

    if not payload.success:
        transaction.status = "failed"
        transaction.failure_reason = (
            payload.failure_reason
        )

        db.commit()
        db.refresh(transaction)

        return transaction

    invoice = get_invoice(
        transaction.invoice_id,
        db,
    )

    if (
        transaction.amount
        > invoice.outstanding_amount
    ):
        raise HTTPException(
            status_code=409,
            detail="Payment exceeds invoice balance",
        )

    transaction.status = "success"
    transaction.paid_at = datetime.now(timezone.utc)

    update_invoice_after_payment(
        invoice,
        transaction.amount,
    )

    existing_receipt = (
        db.query(PaymentReceiptV2)
        .filter(
            PaymentReceiptV2.payment_transaction_id
            == transaction.id
        )
        .first()
    )

    if existing_receipt is None:
        receipt = PaymentReceiptV2(
            payment_transaction_id=transaction.id,
            receipt_number=generate_receipt_number(),
        )

        db.add(receipt)

    db.commit()
    db.refresh(transaction)

    return transaction


@router.post(
    "/webhook",
    response_model=dict,
)
def payment_webhook(
    payload: PaymentWebhookRequest,
    db: Session = Depends(get_db),
):
    existing_event = (
        db.query(PaymentEventV2)
        .filter(
            PaymentEventV2.event_id
            == payload.event_id
        )
        .first()
    )

    if existing_event is not None:
        return {
            "status": "already_processed",
        }

    transaction = None

    if payload.transaction_number:
        transaction = (
            db.query(PaymentTransactionV2)
            .filter(
                PaymentTransactionV2.transaction_number
                == payload.transaction_number
            )
            .first()
        )

    event = PaymentEventV2(
        payment_transaction_id=(
            transaction.id
            if transaction
            else None
        ),
        event_id=payload.event_id,
        event_type=payload.event_type,
        gateway_name="external",
        payload=payload.payload,
        processing_status="received",
    )

    db.add(event)

    if transaction is not None:
        if payload.status == "success":
            if transaction.status != "success":
                invoice = get_invoice(
                    transaction.invoice_id,
                    db,
                )

                if (
                    transaction.amount
                    <= invoice.outstanding_amount
                ):
                    transaction.status = "success"
                    transaction.gateway_transaction_id = (
                        payload.gateway_transaction_id
                    )
                    transaction.paid_at = (
                        datetime.now(timezone.utc)
                    )

                    update_invoice_after_payment(
                        invoice,
                        transaction.amount,
                    )

                    receipt = (
                        db.query(PaymentReceiptV2)
                        .filter(
                            PaymentReceiptV2.payment_transaction_id
                            == transaction.id
                        )
                        .first()
                    )

                    if receipt is None:
                        db.add(
                            PaymentReceiptV2(
                                payment_transaction_id=transaction.id,
                                receipt_number=generate_receipt_number(),
                            )
                        )

            event.processing_status = "processed"

        elif payload.status == "failed":
            transaction.status = "failed"
            event.processing_status = "processed"

    db.commit()

    return {
        "status": "received",
    }


@router.get(
    "/receipts/{transaction_id}",
    response_model=PaymentReceiptResponse,
)
def get_receipt(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = get_transaction(
        transaction_id,
        db,
    )

    if current_user.role != "admin":
        student = get_student_for_user(
            current_user,
            db,
        )

        if transaction.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this receipt",
            )

    receipt = (
        db.query(PaymentReceiptV2)
        .filter(
            PaymentReceiptV2.payment_transaction_id
            == transaction.id
        )
        .first()
    )

    if receipt is None:
        raise HTTPException(
            status_code=404,
            detail="Payment receipt not available",
        )

    return {
        "id": receipt.id,
        "payment_transaction_id": receipt.payment_transaction_id,
        "receipt_number": receipt.receipt_number,
        "issued_at": receipt.issued_at.isoformat(),
        "document_id": receipt.document_id,
    }


@router.get(
    "/admin/transactions",
    response_model=list[PaymentTransactionResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_transactions(
    status: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(PaymentTransactionV2)

    if status is not None:
        query = query.filter(
            PaymentTransactionV2.status == status
        )

    return (
        query.order_by(
            PaymentTransactionV2.id.desc()
        )
        .all()
    )
