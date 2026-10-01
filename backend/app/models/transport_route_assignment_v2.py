from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class TransportRouteAssignmentV2(Base):
    __tablename__ = "transport_route_assignments_v2"

    id = Column(Integer, primary_key=True, index=True)
    route_id = Column(Integer, ForeignKey("transport_routes_v2.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("transport_vehicles_v2.id"), nullable=False)
    academic_session = Column(String(50), nullable=False)
    status = Column(String(50), nullable=False, default="active")
    is_active = Column(Boolean, nullable=False, default=True)

    route = relationship("TransportRouteV2")
    vehicle = relationship("TransportVehicleV2")
