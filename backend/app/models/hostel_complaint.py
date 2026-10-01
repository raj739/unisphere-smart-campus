from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class HostelComplaint(Base):
    __tablename__ = "hostel_complaints"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    complaint_number = Column(
        String(100),
        unique=True,
        nullable=False,
    )

    subject = Column(
        String(200),
        nullable=False,
    )

    description = Column(
        String(500),
        nullable=True,
    )

    status = Column(
        String(50),
        nullable=False,
        default="Open",
    )

    priority = Column(
        String(50),
        nullable=False,
        default="Medium",
    )

    created_date = Column(
        String(20),
        nullable=False,
    )

    student = relationship("Student")
