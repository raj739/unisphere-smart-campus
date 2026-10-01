from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class TransportRouteV2(Base):
    __tablename__ = "transport_routes_v2"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(String(500), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    stops = relationship(
        "TransportStopV2",
        back_populates="route",
        cascade="all, delete-orphan",
    )
