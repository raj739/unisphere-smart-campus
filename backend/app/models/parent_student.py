from sqlalchemy import Column, ForeignKey, Integer

from app.core.database import Base


class ParentStudentLink(Base):
    __tablename__ = "parent_student_links"

    id = Column(Integer, primary_key=True, index=True)

    parent_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )
