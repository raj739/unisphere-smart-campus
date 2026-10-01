from datetime import date, datetime, timezone
from io import BytesIO
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from reportlab.graphics import renderPDF
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen import canvas
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.certificate import Certificate
from app.models.certificate_request import CertificateRequest as CertificateRequestModel
from app.models.student import Student
from app.models.user import User
from app.schemas.certificate import (
    CertificateRequestCreate,
    CertificateRequestResponse,
    CertificateResponse,
    CertificateReviewRequest,
    CertificateVerifyResponse,
)


router = APIRouter(prefix="/certificates", tags=["Certificates"])

CERTIFICATE_TYPES = {
    "bonafide": "Bonafide Certificate",
    "character": "Character Certificate",
    "transfer": "Transfer Certificate",
    "migration": "Migration Certificate",
    "provisional_degree": "Provisional Degree Certificate",
    "course_completion": "Course Completion Certificate",
    "medium_of_instruction": "Medium of Instruction Certificate",
    "enrollment": "Enrollment Certificate",
    "no_dues": "No-Dues Certificate",
    "hostel_residence": "Hostel Residence Certificate",
    "transport_usage": "Transport Usage Certificate",
    "internship": "Internship Certificate",
    "participation": "Participation Certificate",
    "merit_achievement": "Merit / Achievement Certificate",
    "scholarship": "Scholarship Certificate",
}

CERTIFICATE_PREFIXES = {
    "bonafide": "BON",
    "character": "CHR",
    "transfer": "TC",
    "migration": "MIG",
    "provisional_degree": "PROV",
    "course_completion": "CC",
    "medium_of_instruction": "MOI",
    "enrollment": "ENR",
    "no_dues": "NDC",
    "hostel_residence": "HRC",
    "transport_usage": "TUC",
    "internship": "INT",
    "participation": "PAR",
    "merit_achievement": "MER",
    "scholarship": "SCH",
}


def get_current_student(current_user: User, db: Session) -> Student:
    student = db.query(Student).filter(Student.user_id == current_user.id).first()
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )
    return student


def request_query(db: Session):
    return db.query(CertificateRequestModel).options(
        joinedload(CertificateRequestModel.student),
        joinedload(CertificateRequestModel.certificate),
    )


def certificate_query(db: Session):
    return db.query(Certificate).options(joinedload(Certificate.student))


def type_label(certificate_type: str) -> str:
    return CERTIFICATE_TYPES.get(
        certificate_type,
        certificate_type.replace("_", " ").title(),
    )


def verification_url(certificate: Certificate) -> str:
    return (
        "http://127.0.0.1:8000/api/v1/certificates/verify/"
        f"{certificate.certificate_id}"
    )


def request_payload(item: CertificateRequestModel):
    student = item.student
    certificate = item.certificate
    return {
        "id": item.id,
        "request_number": item.request_number,
        "student_id": item.student_id,
        "certificate_type": item.certificate_type,
        "certificate_type_label": type_label(item.certificate_type),
        "purpose": item.purpose,
        "delivery_mode": item.delivery_mode,
        "status": item.status,
        "requested_at": item.requested_at,
        "reviewed_at": item.reviewed_at,
        "review_remarks": item.review_remarks,
        "rejection_reason": item.rejection_reason,
        "certificate_id": item.certificate_id,
        "student_name": student.full_name,
        "student_uni_id": student.university_id or student.uni_id,
        "student_programme": student.programme,
        "issued_certificate_number": (
            certificate.certificate_id if certificate else None
        ),
    }


def certificate_payload(item: Certificate):
    student = item.student
    return {
        "id": item.id,
        "certificate_id": item.certificate_id,
        "certificate_type": item.certificate_type,
        "certificate_type_label": type_label(item.certificate_type),
        "title": item.title,
        "issue_date": item.issue_date,
        "status": item.status,
        "verification_url": verification_url(item),
        "student_name": student.full_name,
        "student_uni_id": student.university_id or student.uni_id,
        "student_programme": student.programme,
    }


def get_certificate_for_user(
    certificate_id: int,
    current_user: User,
    db: Session,
) -> Certificate:
    certificate = certificate_query(db).filter(Certificate.id == certificate_id).first()
    if certificate is None:
        raise HTTPException(status_code=404, detail="Certificate not found")
    if current_user.role != "admin":
        student = get_current_student(current_user, db)
        if certificate.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this certificate",
            )
    return certificate


def build_certificate_pdf(certificate: Certificate) -> BytesIO:
    student = certificate.student
    label = type_label(certificate.certificate_type)
    verify_url = verification_url(certificate)
    buffer = BytesIO()
    page_width, page_height = landscape(A4)
    pdf = canvas.Canvas(buffer, pagesize=(page_width, page_height))

    navy = colors.HexColor("#172554")
    teal = colors.HexColor("#0F766E")
    gold = colors.HexColor("#D6A84B")
    muted = colors.HexColor("#475569")

    pdf.setFillColor(colors.HexColor("#FAFBFC"))
    pdf.rect(0, 0, page_width, page_height, fill=1, stroke=0)
    pdf.setStrokeColor(navy)
    pdf.setLineWidth(5)
    pdf.rect(24, 24, page_width - 48, page_height - 48, fill=0, stroke=1)
    pdf.setStrokeColor(gold)
    pdf.setLineWidth(1.5)
    pdf.rect(34, 34, page_width - 68, page_height - 68, fill=0, stroke=1)

    pdf.setFillColor(navy)
    pdf.setFont("Helvetica-Bold", 25)
    pdf.drawCentredString(page_width / 2, page_height - 82, "VIKRAM UNIVERSITY")
    pdf.setFillColor(teal)
    pdf.setFont("Helvetica-Bold", 14)
    pdf.drawCentredString(page_width / 2, page_height - 108, "UJJAIN, MADHYA PRADESH")

    pdf.setFillColor(navy)
    pdf.setFont("Helvetica-Bold", 22)
    pdf.drawCentredString(page_width / 2, page_height - 160, label.upper())
    pdf.setStrokeColor(gold)
    pdf.line(page_width / 2 - 170, page_height - 170, page_width / 2 + 170, page_height - 170)

    pdf.setFillColor(muted)
    pdf.setFont("Helvetica", 13)
    pdf.drawCentredString(page_width / 2, page_height - 212, "This is to certify that")
    pdf.setFillColor(navy)
    pdf.setFont("Helvetica-Bold", 24)
    pdf.drawCentredString(page_width / 2, page_height - 250, student.full_name)

    pdf.setFillColor(muted)
    pdf.setFont("Helvetica", 13)
    pdf.drawCentredString(
        page_width / 2,
        page_height - 282,
        f"University ID: {student.university_id or student.uni_id}",
    )
    pdf.drawCentredString(
        page_width / 2,
        page_height - 305,
        f"Programme: {student.programme}",
    )
    pdf.drawCentredString(
        page_width / 2,
        page_height - 350,
        f"has been issued this {label} by Vikram University.",
    )

    pdf.setFillColor(navy)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(62, 90, f"Certificate No: {certificate.certificate_id}")
    pdf.drawString(62, 72, f"Issue Date: {certificate.issue_date}")

    pdf.setStrokeColor(muted)
    pdf.line(page_width - 250, 91, page_width - 75, 91)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawCentredString(page_width - 162, 72, "Authorized Signatory")

    qr = QrCodeWidget(verify_url)
    bounds = qr.getBounds()
    size = 78
    drawing = Drawing(
        size,
        size,
        transform=[
            size / (bounds[2] - bounds[0]),
            0,
            0,
            size / (bounds[3] - bounds[1]),
            0,
            0,
        ],
    )
    drawing.add(qr)
    renderPDF.draw(drawing, pdf, page_width / 2 - size / 2, 52)
    pdf.setFillColor(muted)
    pdf.setFont("Helvetica", 8)
    pdf.drawCentredString(page_width / 2, 43, "Scan to verify authenticity")

    pdf.showPage()
    pdf.save()
    buffer.seek(0)
    return buffer


@router.get("/types")
def list_certificate_types(current_user: User = Depends(get_current_user)):
    return [
        {"code": code, "label": label}
        for code, label in CERTIFICATE_TYPES.items()
    ]


@router.post(
    "/requests",
    response_model=CertificateRequestResponse,
)
def create_certificate_request(
    payload: CertificateRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)
    if payload.certificate_type not in CERTIFICATE_TYPES:
        raise HTTPException(status_code=400, detail="Invalid certificate type")
    if payload.delivery_mode != "digital":
        raise HTTPException(status_code=400, detail="Only digital delivery is supported")

    existing = (
        db.query(CertificateRequestModel)
        .filter(
            CertificateRequestModel.student_id == student.id,
            CertificateRequestModel.certificate_type == payload.certificate_type,
            CertificateRequestModel.status.in_(
                ["submitted", "under_review", "approved"]
            ),
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=409,
            detail="An active request for this certificate already exists",
        )

    item = CertificateRequestModel(
        request_number=f"CR-{uuid4().hex[:12].upper()}",
        student_id=student.id,
        certificate_type=payload.certificate_type,
        purpose=payload.purpose,
        delivery_mode="digital",
        status="submitted",
    )
    db.add(item)
    db.commit()
    item = request_query(db).filter(CertificateRequestModel.id == item.id).first()
    return request_payload(item)


@router.get(
    "/requests/me",
    response_model=list[CertificateRequestResponse],
)
def my_certificate_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)
    items = (
        request_query(db)
        .filter(CertificateRequestModel.student_id == student.id)
        .order_by(CertificateRequestModel.requested_at.desc())
        .all()
    )
    return [request_payload(item) for item in items]


@router.patch(
    "/requests/{request_id}/cancel",
    response_model=CertificateRequestResponse,
)
def cancel_certificate_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)
    item = request_query(db).filter(
        CertificateRequestModel.id == request_id,
        CertificateRequestModel.student_id == student.id,
    ).first()
    if item is None:
        raise HTTPException(status_code=404, detail="Certificate request not found")
    if item.status not in {"submitted", "under_review"}:
        raise HTTPException(status_code=409, detail="This request can no longer be cancelled")
    item.status = "cancelled"
    db.commit()
    db.refresh(item)
    return request_payload(item)


@router.get(
    "/admin/overview",
    dependencies=[Depends(require_role("admin"))],
)
def certificate_admin_overview(db: Session = Depends(get_db)):
    requests = request_query(db).order_by(
        CertificateRequestModel.requested_at.desc()
    ).all()
    certificates = certificate_query(db).order_by(Certificate.id.desc()).all()
    return {
        "metrics": {
            "total_requests": len(requests),
            "pending_review": len([
                item for item in requests
                if item.status in {"submitted", "under_review"}
            ]),
            "approved": len([item for item in requests if item.status == "approved"]),
            "issued": len(certificates),
            "valid": len([item for item in certificates if item.status == "Valid"]),
            "revoked": len([item for item in certificates if item.status == "Revoked"]),
        },
        "requests": [request_payload(item) for item in requests],
        "certificates": [certificate_payload(item) for item in certificates],
    }


@router.patch(
    "/requests/{request_id}/review",
    response_model=CertificateRequestResponse,
    dependencies=[Depends(require_role("admin"))],
)
def review_certificate_request(
    request_id: int,
    payload: CertificateReviewRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = request_query(db).filter(CertificateRequestModel.id == request_id).first()
    if item is None:
        raise HTTPException(status_code=404, detail="Certificate request not found")
    if item.status not in {"submitted", "under_review"}:
        raise HTTPException(status_code=409, detail="This request has already been reviewed")
    if payload.action not in {"under_review", "approved", "rejected"}:
        raise HTTPException(status_code=400, detail="Invalid review action")
    if payload.action == "rejected" and not (payload.remarks or "").strip():
        raise HTTPException(status_code=400, detail="Rejection reason is required")

    item.status = payload.action
    item.reviewed_by_user_id = current_user.id
    item.reviewed_at = datetime.now(timezone.utc)
    item.review_remarks = payload.remarks
    item.rejection_reason = payload.remarks if payload.action == "rejected" else None
    db.commit()
    db.refresh(item)
    return request_payload(item)


@router.post(
    "/requests/{request_id}/issue",
    response_model=CertificateResponse,
    dependencies=[Depends(require_role("admin"))],
)
def issue_certificate(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = request_query(db).filter(CertificateRequestModel.id == request_id).first()
    if item is None:
        raise HTTPException(status_code=404, detail="Certificate request not found")
    if item.status != "approved":
        raise HTTPException(status_code=409, detail="Approve the request before issuing")
    if item.certificate_id is not None:
        raise HTTPException(status_code=409, detail="Certificate has already been issued")

    prefix = CERTIFICATE_PREFIXES[item.certificate_type]
    certificate = Certificate(
        student_id=item.student_id,
        certificate_id=f"VU-{prefix}-{date.today().year}-{uuid4().hex[:8].upper()}",
        certificate_type=item.certificate_type,
        title=type_label(item.certificate_type),
        issue_date=date.today().isoformat(),
        status="Valid",
        verification_token=uuid4().hex,
    )
    db.add(certificate)
    db.flush()
    item.certificate_id = certificate.id
    item.status = "issued"
    item.reviewed_by_user_id = current_user.id
    item.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    certificate = certificate_query(db).filter(Certificate.id == certificate.id).first()
    return certificate_payload(certificate)


@router.patch(
    "/issued/{certificate_id}/revoke",
    response_model=CertificateResponse,
    dependencies=[Depends(require_role("admin"))],
)
def revoke_certificate(
    certificate_id: int,
    db: Session = Depends(get_db),
):
    certificate = certificate_query(db).filter(Certificate.id == certificate_id).first()
    if certificate is None:
        raise HTTPException(status_code=404, detail="Certificate not found")
    certificate.status = "Revoked"
    db.commit()
    db.refresh(certificate)
    return certificate_payload(certificate)


@router.get("/issued/{certificate_id}/pdf")
def download_certificate_pdf(
    certificate_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    certificate = get_certificate_for_user(certificate_id, current_user, db)
    pdf = build_certificate_pdf(certificate)
    filename = f"{certificate.certificate_id}.pdf"
    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("", response_model=list[CertificateResponse])
def get_my_certificates(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)
    certificates = (
        certificate_query(db)
        .filter(Certificate.student_id == student.id)
        .order_by(Certificate.id.desc())
        .all()
    )
    return [certificate_payload(item) for item in certificates]


@router.get(
    "/verify/{certificate_number}",
    response_model=CertificateVerifyResponse,
)
def verify_certificate(
    certificate_number: str,
    db: Session = Depends(get_db),
):
    certificate = certificate_query(db).filter(
        Certificate.certificate_id == certificate_number
    ).first()
    if certificate is None:
        raise HTTPException(status_code=404, detail="Certificate not found")
    student = certificate.student
    return {
        "valid": certificate.status == "Valid",
        "certificate_id": certificate.certificate_id,
        "certificate_type": certificate.certificate_type,
        "certificate_type_label": type_label(certificate.certificate_type),
        "title": certificate.title,
        "issue_date": certificate.issue_date,
        "status": certificate.status,
        "student_name": student.full_name,
        "student_uni_id": student.university_id or student.uni_id,
        "student_programme": student.programme,
    }
