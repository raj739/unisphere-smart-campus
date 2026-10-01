from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.helpdesk import HelpdeskTicket
from app.models.student import Student
from app.models.user import User
from app.schemas.helpdesk import (
    HelpdeskCreateRequest,
    HelpdeskTicketResponse,
)

router = APIRouter(
    prefix="/helpdesk",
    tags=["Helpdesk"],
)


def get_current_student(
    current_user: User,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


def ticket_response(ticket: HelpdeskTicket):
    return HelpdeskTicketResponse(
        ticket_number=ticket.ticket_number,
        subject=ticket.subject,
        description=ticket.description,
        category=ticket.category,
        priority=ticket.priority,
        status=ticket.status,
        created_date=ticket.created_date,
        assigned_to=ticket.assigned_to,
    )


@router.get(
    "",
    response_model=list[HelpdeskTicketResponse],
)
def get_my_tickets(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    tickets = (
        db.query(HelpdeskTicket)
        .filter(HelpdeskTicket.student_id == student.id)
        .order_by(HelpdeskTicket.id.desc())
        .all()
    )

    return [ticket_response(ticket) for ticket in tickets]


@router.get(
    "/{ticket_number}",
    response_model=HelpdeskTicketResponse,
)
def get_ticket(
    ticket_number: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    ticket = (
        db.query(HelpdeskTicket)
        .filter(
            HelpdeskTicket.ticket_number == ticket_number,
            HelpdeskTicket.student_id == student.id,
        )
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    return ticket_response(ticket)


@router.post(
    "",
    response_model=HelpdeskTicketResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_ticket(
    request: HelpdeskCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    ticket_number = (
        f"TKT-{datetime.now().year}-"
        f"{uuid.uuid4().hex[:8].upper()}"
    )

    ticket = HelpdeskTicket(
        student_id=student.id,
        ticket_number=ticket_number,
        subject=request.subject,
        description=request.description,
        category=request.category,
        priority=request.priority,
        status="Open",
        created_date=datetime.now().strftime("%Y-%m-%d"),
        assigned_to=None,
    )

    db.add(ticket)
    db.commit()
    db.refresh(ticket)

    return ticket_response(ticket)
