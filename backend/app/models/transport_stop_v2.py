from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class TransportStopV2(Base):
    __tablename__ = "transport_stops_v2"

    id = Column(Integer, primary_key=True, index=True)
    route_id = Column(Integer, ForeignKey("transport_routes_v2.id"), nullable=False)
    name = Column(String(200), nullable=False)
    sequence_number = Column(Integer, nullable=False)
    pickup_time = Column(String(20), nullable=True)
    landmark = Column(String(300), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    route = relationship("TransportRouteV2", back_populates="stops")
