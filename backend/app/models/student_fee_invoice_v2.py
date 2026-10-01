from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentFeeInvoiceV2(Base):
    __tablename__ = "student_fee_invoices_v2"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    academic_session = Column(
        String(50),
        nullable=False,
    )

    semester = Column(
        Integer,
        nullable=False,
    )

    invoice_number = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
    )

    total_amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    discount_amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    waiver_amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    paid_amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    outstanding_amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    due_date = Column(
        String(20),
        nullable=True,
    )

    status = Column(
        String(50),
        nullable=False,
        default="pending",
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    student = relationship("Student")
