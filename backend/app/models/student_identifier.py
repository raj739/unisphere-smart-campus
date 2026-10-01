from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentIdentifier(Base):
    __tablename__ = "student_identifiers"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    identifier_type = Column(
        String(50),
        nullable=False,
    )

    identifier_value = Column(
        String(150),
        nullable=False,
    )

    issuing_authority = Column(
        String(200),
        nullable=True,
    )

    is_verified = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    student = relationship("Student")