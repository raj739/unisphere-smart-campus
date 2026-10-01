from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, Integer, String, Text
from app.core.database import Base

class HelpdeskCategoryV2(Base):
    __tablename__ = "helpdesk_categories_v2"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(String(500), nullable=True)
    department = Column(String(150), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
