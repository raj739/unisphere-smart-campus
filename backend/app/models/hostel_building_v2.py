from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class HostelBuildingV2(Base):
    __tablename__ = "hostel_buildings_v2"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    hostel_type = Column(String(50), nullable=False, default="general")
    gender = Column(String(30), nullable=True)
    address = Column(String(300), nullable=True)
    total_floors = Column(Integer, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    rooms = relationship(
        "HostelRoomV2",
        back_populates="building",
        cascade="all, delete-orphan",
    )
