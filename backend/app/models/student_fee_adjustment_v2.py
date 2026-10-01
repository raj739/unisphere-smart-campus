from sqlalchemy import Column, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentFeeAdjustmentV2(Base):
    __tablename__ = "student_fee_adjustments_v2"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    invoice_id = Column(
        Integer,
        ForeignKey("student_fee_invoices_v2.id"),
        nullable=False,
    )

    adjustment_type = Column(
        String(50),
        nullable=False,
    )

    amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    reason = Column(
        String(500),
        nullable=True,
    )

    approved_by_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    student = relationship("Student")
    invoice = relationship("StudentFeeInvoiceV2")
    approved_by = relationship("User")
