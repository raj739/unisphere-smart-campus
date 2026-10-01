from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.student import Student
from app.models.user import User
from app.models.helpdesk_category_v2 import HelpdeskCategoryV2
from app.models.helpdesk_ticket_v2 import HelpdeskTicketV2
from app.models.helpdesk_message_v2 import HelpdeskMessageV2

from app.schemas.helpdesk_v2 import (
    HelpdeskCategoryCreateRequest,
    HelpdeskCategoryResponse,
    HelpdeskTicketCreateRequest,
    HelpdeskTicketResponse,
    HelpdeskTicketUpdateRequest,
    HelpdeskResolveRequest,
    HelpdeskMessageCreateRequest,
    HelpdeskMessageResponse,
)

router = APIRouter(
    prefix="/helpdesk-v2",
    tags=["Helpdesk V2"],
)

ALLOWED_PRIORITIES = {
    "low",
    "normal",
    "high",
    "urgent",
}

ALLOWED_STATUSES = {
    "open",
    "in_progress",
    "waiting",
    "resolved",
    "closed",
    "reopened",
}


def get_student_by_user(db: Session, user_id: int):
    student = (
        db.query(Student)
        .filter(Student.user_id == user_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


@router.post(
    "/categories",
    response_model=HelpdeskCategoryResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_category(
    request: HelpdeskCategoryCreateRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(HelpdeskCategoryV2)
        .filter(HelpdeskCategoryV2.code == request.code)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Helpdesk category code already exists",
        )

    category = HelpdeskCategoryV2(
        **request.model_dump()
    )

    db.add(category)
    db.commit()
    db.refresh(category)

    return category


@router.get(
    "/categories",
    response_model=list[HelpdeskCategoryResponse],
)
def list_categories(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(HelpdeskCategoryV2)
        .filter(HelpdeskCategoryV2.is_active == True)
        .order_by(HelpdeskCategoryV2.name)
        .all()
    )


@router.post(
    "/tickets",
    response_model=HelpdeskTicketResponse,
)
def create_ticket(
    request: HelpdeskTicketCreateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    if request.priority not in ALLOWED_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ticket priority",
        )

    category = (
        db.query(HelpdeskCategoryV2)
        .filter(
            HelpdeskCategoryV2.id == request.category_id,
            HelpdeskCategoryV2.is_active == True,
        )
        .first()
    )

    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk category not found",
        )

    ticket = HelpdeskTicketV2(
        ticket_number=f"UNI-HLP-{uuid4().hex[:12].upper()}",
        student_id=student.id,
        category_id=request.category_id,
        subject=request.subject,
        description=request.description,
        priority=request.priority,
        status="open",
    )

    db.add(ticket)
    db.commit()
    db.refresh(ticket)

    return ticket


@router.get(
    "/tickets/me",
    response_model=list[HelpdeskTicketResponse],
)
def my_tickets(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    return (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.student_id == student.id)
        .order_by(HelpdeskTicketV2.created_at.desc())
        .all()
    )


@router.get(
    "/tickets/{ticket_id}",
    response_model=HelpdeskTicketResponse,
)
def get_ticket(
    ticket_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ticket = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.id == ticket_id)
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    if current_user.role != "admin":
        student = get_student_by_user(db, current_user.id)

        if ticket.student_id != student.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot access this ticket",
            )

    return ticket


@router.get(
    "/tickets/admin/all",
    response_model=list[HelpdeskTicketResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_tickets(
    ticket_status: str | None = None,
    priority: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(HelpdeskTicketV2)

    if ticket_status:
        if ticket_status not in ALLOWED_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid ticket status",
            )

        query = query.filter(
            HelpdeskTicketV2.status == ticket_status
        )

    if priority:
        if priority not in ALLOWED_PRIORITIES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid ticket priority",
            )

        query = query.filter(
            HelpdeskTicketV2.priority == priority
        )

    return query.order_by(
        HelpdeskTicketV2.created_at.desc()
    ).all()


@router.patch(
    "/tickets/{ticket_id}",
    response_model=HelpdeskTicketResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_ticket(
    ticket_id: int,
    request: HelpdeskTicketUpdateRequest,
    db: Session = Depends(get_db),
):
    ticket = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.id == ticket_id)
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    if request.status is not None:
        if request.status not in ALLOWED_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid ticket status",
            )

        ticket.status = request.status

    if request.priority is not None:
        if request.priority not in ALLOWED_PRIORITIES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid ticket priority",
            )

        ticket.priority = request.priority

    if request.assigned_to_user_id is not None:
        user = (
            db.query(User)
            .filter(
                User.id == request.assigned_to_user_id,
                User.is_active == True,
            )
            .first()
        )

        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assigned user not found",
            )

        ticket.assigned_to_user_id = user.id

    db.commit()
    db.refresh(ticket)

    return ticket


@router.patch(
    "/tickets/{ticket_id}/resolve",
    response_model=HelpdeskTicketResponse,
    dependencies=[Depends(require_role("admin"))],
)
def resolve_ticket(
    ticket_id: int,
    request: HelpdeskResolveRequest,
    db: Session = Depends(get_db),
):
    ticket = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.id == ticket_id)
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    ticket.resolution = request.resolution
    ticket.status = "resolved"
    ticket.resolved_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(ticket)

    return ticket


@router.post(
    "/tickets/{ticket_id}/messages",
    response_model=HelpdeskMessageResponse,
)
def add_message(
    ticket_id: int,
    request: HelpdeskMessageCreateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ticket = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.id == ticket_id)
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    if current_user.role != "admin":
        student = get_student_by_user(db, current_user.id)

        if ticket.student_id != student.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot reply to this ticket",
            )

    message = HelpdeskMessageV2(
        ticket_id=ticket.id,
        sender_user_id=current_user.id,
        message=request.message,
    )

    if ticket.status == "resolved":
        ticket.status = "reopened"

    db.add(message)
    db.commit()
    db.refresh(message)

    return message


@router.get(
    "/tickets/{ticket_id}/messages",
    response_model=list[HelpdeskMessageResponse],
)
def list_messages(
    ticket_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ticket = (
        db.query(HelpdeskTicketV2)
        .filter(HelpdeskTicketV2.id == ticket_id)
        .first()
    )

    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Helpdesk ticket not found",
        )

    if current_user.role != "admin":
        student = get_student_by_user(db, current_user.id)

        if ticket.student_id != student.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot access these messages",
            )

    return (
        db.query(HelpdeskMessageV2)
        .filter(HelpdeskMessageV2.ticket_id == ticket_id)
        .order_by(HelpdeskMessageV2.created_at)
        .all()
    )
