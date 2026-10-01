from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class HelpdeskTicket(Base):
    __tablename__ = "helpdesk_tickets"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    ticket_number = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
    )

    subject = Column(String(200), nullable=False)

    description = Column(
        String(1000),
        nullable=True,
    )

    category = Column(
        String(100),
        nullable=False,
    )

    priority = Column(
        String(50),
        nullable=False,
        default="Medium",
    )

    status = Column(
        String(50),
        nullable=False,
        default="Open",
    )

    created_date = Column(
        String(20),
        nullable=False,
    )

    assigned_to = Column(
        String(150),
        nullable=True,
    )
