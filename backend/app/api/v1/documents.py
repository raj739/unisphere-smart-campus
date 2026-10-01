import hashlib
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.digital_document import DigitalDocument
from app.models.document_event import DocumentEvent
from app.models.student import Student
from app.models.user import User
from app.schemas.document import (
    AdminDocumentResponse,
    DocumentCreateRequest,
    DocumentEventResponse,
    DocumentResponse,
    DocumentStatusRequest,
    DocumentVerifyResponse,
    StudentDocumentResponse,
)

router = APIRouter(
    prefix="/documents",
    tags=["Documents"],
)


ALLOWED_DOCUMENT_TYPES = {
    "degree",
    "marksheet",
    "bonafide",
    "student_id",
    "fee_receipt",
    "migration",
    "transfer_certificate",
    "character_certificate",
    "admit_card",
    "other",
}


ALLOWED_STATUSES = {
    "issued",
    "active",
    "revoked",
    "expired",
    "cancelled",
}


def get_student(student_id: int, db: Session) -> Student:
    student = (
        db.query(Student)
        .filter(Student.id == student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student not found",
        )

    return student


def get_document(
    document_id: int,
    db: Session,
) -> DigitalDocument:
    document = (
        db.query(DigitalDocument)
        .filter(DigitalDocument.id == document_id)
        .first()
    )

    if document is None:
        raise HTTPException(
            status_code=404,
            detail="Document not found",
        )

    return document


def generate_document_number(
    document_type: str,
    student: Student,
) -> str:
    prefix_map = {
        "degree": "DEG",
        "marksheet": "MRK",
        "bonafide": "BON",
        "student_id": "SID",
        "fee_receipt": "FEE",
        "migration": "MIG",
        "transfer_certificate": "TC",
        "character_certificate": "CHR",
        "admit_card": "ADM",
        "other": "DOC",
    }

    prefix = prefix_map.get(document_type, "DOC")

    timestamp = datetime.now(timezone.utc).strftime(
        "%Y%m%d%H%M%S%f"
    )

    return f"{prefix}-{student.uni_id}-{timestamp}"


def generate_verification_token() -> str:
    return secrets.token_urlsafe(32)


def build_qr_payload(
    document_number: str,
    verification_token: str,
) -> str:
    return (
        f"/api/v1/documents/verify/"
        f"{verification_token}"
    )


@router.post(
    "",
    response_model=DocumentResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_document(
    payload: DocumentCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.document_type not in ALLOWED_DOCUMENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Invalid document type",
        )

    student = get_student(payload.student_id, db)

    document_number = generate_document_number(
        payload.document_type,
        student,
    )

    verification_token = generate_verification_token()

    document = DigitalDocument(
        student_id=student.id,
        document_type=payload.document_type,
        document_number=document_number,
        title=payload.title,
        issue_date=payload.issue_date,
        valid_until=payload.valid_until,
        status="issued",
        verification_token=verification_token,
        qr_payload=build_qr_payload(
            document_number,
            verification_token,
        ),
        issued_by_user_id=current_user.id,
    )

    db.add(document)
    db.flush()

    event = DocumentEvent(
        document_id=document.id,
        event_type="issued",
        performed_by_user_id=current_user.id,
        details="Document issued",
    )

    db.add(event)

    db.commit()
    db.refresh(document)

    return document


@router.get(
    "/me",
    response_model=list[StudentDocumentResponse],
)
def my_documents(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found",
        )

    return (
        db.query(DigitalDocument)
        .filter(
            DigitalDocument.student_id == student.id
        )
        .order_by(DigitalDocument.id.desc())
        .all()
    )


@router.get(
    "/students/{student_id}",
    response_model=list[StudentDocumentResponse],
    dependencies=[Depends(require_role("admin"))],
)
def student_documents(
    student_id: int,
    db: Session = Depends(get_db),
):
    get_student(student_id, db)

    return (
        db.query(DigitalDocument)
        .filter(
            DigitalDocument.student_id == student_id
        )
        .order_by(DigitalDocument.id.desc())
        .all()
    )


@router.get(
    "/admin/all",
    response_model=list[AdminDocumentResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_documents(db: Session = Depends(get_db)):
    rows = (
        db.query(DigitalDocument, Student)
        .join(Student, Student.id == DigitalDocument.student_id)
        .order_by(DigitalDocument.id.desc())
        .all()
    )
    return [
        {
            "id": document.id,
            "student_id": document.student_id,
            "student_name": student.full_name,
            "uni_id": student.uni_id,
            "programme": student.programme,
            "document_type": document.document_type,
            "document_number": document.document_number,
            "title": document.title,
            "issue_date": document.issue_date,
            "valid_until": document.valid_until,
            "status": document.status,
            "file_path": document.file_path,
            "verification_token": document.verification_token,
            "qr_payload": document.qr_payload,
        }
        for document, student in rows
    ]


@router.get(
    "/{document_id}",
    response_model=DocumentResponse,
)
def get_document_details(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    document = get_document(document_id, db)

    if current_user.role != "admin":
        student = (
            db.query(Student)
            .filter(Student.user_id == current_user.id)
            .first()
        )

        if student is None or document.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this document",
            )

    return document


@router.patch(
    "/{document_id}/status",
    response_model=DocumentResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_document_status(
    document_id: int,
    payload: DocumentStatusRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.status not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=400,
            detail="Invalid document status",
        )

    document = get_document(document_id, db)

    old_status = document.status
    document.status = payload.status

    event = DocumentEvent(
        document_id=document.id,
        event_type="status_changed",
        performed_by_user_id=current_user.id,
        details=f"Status changed from {old_status} to {payload.status}",
    )

    db.add(event)
    db.commit()
    db.refresh(document)

    return document


@router.get(
    "/{document_id}/events",
    response_model=list[DocumentEventResponse],
    dependencies=[Depends(require_role("admin"))],
)
def document_events(
    document_id: int,
    db: Session = Depends(get_db),
):
    get_document(document_id, db)

    return (
        db.query(DocumentEvent)
        .filter(
            DocumentEvent.document_id == document_id
        )
        .order_by(DocumentEvent.id.desc())
        .all()
    )


@router.get(
    "/verify/{verification_token}",
    response_model=DocumentVerifyResponse,
)
def verify_document(
    verification_token: str,
    db: Session = Depends(get_db),
):
    document = (
        db.query(DigitalDocument)
        .filter(
            DigitalDocument.verification_token
            == verification_token
        )
        .first()
    )

    if document is None:
        raise HTTPException(
            status_code=404,
            detail="Document could not be verified",
        )

    student = (
        db.query(Student)
        .filter(Student.id == document.student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Associated student not found",
        )

    valid = document.status in {
        "issued",
        "active",
    }

    return {
        "valid": valid,
        "document_number": document.document_number,
        "document_type": document.document_type,
        "title": document.title,
        "student_name": student.full_name,
        "uni_id": student.uni_id,
        "programme": student.programme,
        "issue_date": document.issue_date,
        "valid_until": document.valid_until,
        "status": document.status,
    }


@router.post(
    "/{document_id}/hash",
    response_model=DocumentResponse,
    dependencies=[Depends(require_role("admin"))],
)
def generate_document_hash(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    document = get_document(document_id, db)

    source = (
        f"{document.document_number}|"
        f"{document.student_id}|"
        f"{document.document_type}|"
        f"{document.issue_date}|"
        f"{document.status}"
    )

    document.file_hash = hashlib.sha256(
        source.encode("utf-8")
    ).hexdigest()

    event = DocumentEvent(
        document_id=document.id,
        event_type="hash_generated",
        performed_by_user_id=current_user.id,
        details="Document integrity hash generated",
    )

    db.add(event)
    db.commit()
    db.refresh(document)

    return document
