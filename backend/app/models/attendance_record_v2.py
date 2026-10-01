from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class AttendanceRecordV2(Base):
    __tablename__ = "attendance_records_v2"

    id = Column(Integer, primary_key=True, index=True)

    attendance_session_id = Column(
        Integer,
        ForeignKey("attendance_sessions_v2.id"),
        nullable=False,
    )

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    status = Column(
        String(30),
        nullable=False,
        default="present",
    )

    remarks = Column(
        String(500),
        nullable=True,
    )

    attendance_session = relationship(
        "AttendanceSessionV2"
    )

    student = relationship("Student")
