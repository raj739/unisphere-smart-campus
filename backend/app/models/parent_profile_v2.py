from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class ParentProfileV2(Base):
    __tablename__ = "parent_profiles_v2"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    full_name = Column(String(200), nullable=False)
    phone = Column(String(30), nullable=True)
    relationship_type = Column(String(50), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    user = relationship("User")
