from sqlalchemy import Column, ForeignKey, Integer, Float, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class FeeRecord(Base):
    __tablename__ = "fee_records"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )
    academic_year = Column(String(50), nullable=False)
    semester = Column(Integer, nullable=False)

    total_amount = Column(Float, nullable=False, default=0.0)
    paid_amount = Column(Float, nullable=False, default=0.0)
    outstanding_amount = Column(Float, nullable=False, default=0.0)

    due_date = Column(String(20), nullable=True)
    status = Column(String(50), nullable=False, default="Pending")

    student = relationship("Student")
