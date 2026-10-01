from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class HostelAllocationV2(Base):
    __tablename__ = "hostel_allocations_v2"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    room_id = Column(Integer, ForeignKey("hostel_rooms_v2.id"), nullable=False)
    allocation_number = Column(String(120), unique=True, nullable=False, index=True)
    status = Column(String(50), nullable=False, default="allocated")
    allocated_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    check_in_at = Column(DateTime, nullable=True)
    check_out_at = Column(DateTime, nullable=True)
    remarks = Column(Text, nullable=True)
    allocated_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    student = relationship("Student")
    room = relationship("HostelRoomV2")
    allocated_by = relationship("User")
