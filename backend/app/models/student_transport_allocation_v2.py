from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class StudentTransportAllocationV2(Base):
    __tablename__ = "student_transport_allocations_v2"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    route_id = Column(Integer, ForeignKey("transport_routes_v2.id"), nullable=False)
    stop_id = Column(Integer, ForeignKey("transport_stops_v2.id"), nullable=False)
    allocation_number = Column(String(120), unique=True, nullable=False, index=True)
    academic_session = Column(String(50), nullable=False)
    status = Column(String(50), nullable=False, default="active")
    allocated_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    deactivated_at = Column(DateTime, nullable=True)
    remarks = Column(String(1000), nullable=True)
    allocated_by_user_id = Column(ForeignKey("users.id"), nullable=False)

    student = relationship("Student")
    route = relationship("TransportRouteV2")
    stop = relationship("TransportStopV2")
    allocated_by = relationship("User")
