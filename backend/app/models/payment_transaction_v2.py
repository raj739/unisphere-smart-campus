from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class PaymentTransactionV2(Base):
    __tablename__ = "payment_transactions_v2"

    id = Column(Integer, primary_key=True, index=True)

    invoice_id = Column(
        Integer,
        ForeignKey("student_fee_invoices_v2.id"),
        nullable=False,
        index=True,
    )

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    transaction_number = Column(
        String(120),
        unique=True,
        nullable=False,
        index=True,
    )

    gateway_transaction_id = Column(
        String(200),
        nullable=True,
        index=True,
    )

    idempotency_key = Column(
        String(200),
        unique=True,
        nullable=False,
        index=True,
    )

    amount = Column(
        Float,
        nullable=False,
    )

    currency = Column(
        String(10),
        nullable=False,
        default="INR",
    )

    payment_method = Column(
        String(50),
        nullable=False,
        default="online",
    )

    status = Column(
        String(40),
        nullable=False,
        default="initiated",
    )

    gateway_name = Column(
        String(100),
        nullable=True,
    )

    gateway_order_id = Column(
        String(200),
        nullable=True,
        index=True,
    )

    failure_reason = Column(
        String(500),
        nullable=True,
    )

    paid_at = Column(
        DateTime,
        nullable=True,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    invoice = relationship("StudentFeeInvoiceV2")
    student = relationship("Student")
