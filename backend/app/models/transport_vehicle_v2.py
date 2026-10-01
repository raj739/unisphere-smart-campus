from sqlalchemy import Boolean, Column, Integer, String
from app.core.database import Base

class TransportVehicleV2(Base):
    __tablename__ = "transport_vehicles_v2"

    id = Column(Integer, primary_key=True, index=True)
    vehicle_number = Column(String(50), unique=True, nullable=False, index=True)
    vehicle_type = Column(String(50), nullable=False, default="bus")
    capacity = Column(Integer, nullable=False, default=40)
    driver_name = Column(String(200), nullable=True)
    driver_contact = Column(String(30), nullable=True)
    status = Column(String(50), nullable=False, default="available")
    is_active = Column(Boolean, nullable=False, default=True)
