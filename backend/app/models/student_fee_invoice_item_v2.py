from sqlalchemy import Column, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentFeeInvoiceItemV2(Base):
    __tablename__ = "student_fee_invoice_items_v2"

    id = Column(Integer, primary_key=True, index=True)

    invoice_id = Column(
        Integer,
        ForeignKey("student_fee_invoices_v2.id"),
        nullable=False,
    )

    fee_type = Column(
        String(100),
        nullable=False,
    )

    description = Column(
        String(250),
        nullable=True,
    )

    amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    invoice = relationship("StudentFeeInvoiceV2")
