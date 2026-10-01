from sqlalchemy import Column, ForeignKey, Integer, Float, String

from app.core.database import Base


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    fee_record_id = Column(
        Integer,
        ForeignKey("fee_records.id"),
        nullable=False,
    )

    amount = Column(Float, nullable=False)
    payment_date = Column(String(20), nullable=False)
    payment_method = Column(String(50), nullable=False)
    transaction_id = Column(String(150), unique=True, nullable=False)
    status = Column(String(50), nullable=False, default="Success")
