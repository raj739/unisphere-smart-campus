from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class HostelComplaintV2(Base):
    __tablename__ = "hostel_complaints_v2"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    room_id = Column(Integer, ForeignKey("hostel_rooms_v2.id"), nullable=True)
    complaint_number = Column(String(120), unique=True, nullable=False, index=True)
    category = Column(String(100), nullable=False)
    title = Column(String(250), nullable=False)
    description = Column(Text, nullable=False)
    priority = Column(String(30), nullable=False, default="normal")
    status = Column(String(50), nullable=False, default="open")
    resolution = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    resolved_at = Column(DateTime, nullable=True)
    resolved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    student = relationship("Student")
    room = relationship("HostelRoomV2")
    resolved_by = relationship("User")
