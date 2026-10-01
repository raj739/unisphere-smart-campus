from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base


class CurriculumCourse(Base):
    __tablename__ = "curriculum_courses"
    __table_args__ = (
        UniqueConstraint(
            "curriculum_id",
            "semester_number",
            "source_paper_code",
            name="uq_curriculum_semester_paper",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    curriculum_id = Column(
        Integer,
        ForeignKey("curricula.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False, index=True)
    semester_number = Column(Integer, nullable=False, index=True)
    source_paper_code = Column(String(50), nullable=False)
    paper_type = Column(String(50), nullable=False)
    theory_credits = Column(Integer, nullable=False, default=0)
    practical_credits = Column(Integer, nullable=False, default=0)
    total_credits = Column(Integer, nullable=False, default=0)
    has_practical = Column(Boolean, nullable=False, default=False)
    display_order = Column(Integer, nullable=False, default=0)
    weekly_hours = Column(Integer, nullable=True)
    max_marks = Column(Integer, nullable=True)
    passing_marks = Column(Integer, nullable=True)
    elective_group = Column(String(100), nullable=True)

    curriculum = relationship("Curriculum", back_populates="courses")
    course = relationship("Course")
