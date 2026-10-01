from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class TransportIssue(Base):
    __tablename__ = "transport_issues"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    issue_number = Column(
        String(100),
        unique=True,
        nullable=False,
    )

    subject = Column(String(200), nullable=False)
    description = Column(String(500), nullable=True)

    status = Column(
        String(50),
        nullable=False,
        default="Open",
    )

    created_date = Column(String(20), nullable=False)
