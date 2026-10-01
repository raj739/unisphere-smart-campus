from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class HostelRoomV2(Base):
    __tablename__ = "hostel_rooms_v2"

    id = Column(Integer, primary_key=True, index=True)
    building_id = Column(Integer, ForeignKey("hostel_buildings_v2.id"), nullable=False)
    room_number = Column(String(50), nullable=False)
    floor_number = Column(Integer, nullable=True)
    room_type = Column(String(50), nullable=False, default="shared")
    capacity = Column(Integer, nullable=False, default=2)
    occupied_count = Column(Integer, nullable=False, default=0)
    status = Column(String(50), nullable=False, default="available")
    is_active = Column(Boolean, nullable=False, default=True)

    building = relationship("HostelBuildingV2", back_populates="rooms")
