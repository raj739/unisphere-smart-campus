from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi.responses import Response

from app.core.dependencies import require_roles
from app.core.security import get_current_user
from app.schemas.reports import ReportRequest
from app.services.report_service import ReportService


router = APIRouter(
    prefix="/reports",
    tags=["Reports"],
)


@router.post(
    "/pdf",
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def generate_pdf_report(
    request: ReportRequest,
    current_user=Depends(get_current_user),
):
    data = ReportService.build_pdf(
        title=request.title,
        rows=request.rows,
        metadata=request.metadata,
    )

    return Response(
        content=data,
        media_type="application/pdf",
        headers={
            "Content-Disposition": (
                'attachment; filename="unisphere_report.pdf"'
            )
        },
    )


@router.post(
    "/excel",
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def generate_excel_report(
    request: ReportRequest,
    current_user=Depends(get_current_user),
):
    data = ReportService.build_excel(
        title=request.title,
        rows=request.rows,
        metadata=request.metadata,
    )

    return Response(
        content=data,
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "spreadsheetml.sheet"
        ),
        headers={
            "Content-Disposition": (
                'attachment; filename="unisphere_report.xlsx"'
            )
        },
    )


@router.get("/health")
def report_health(
    current_user=Depends(get_current_user),
):
    return {
        "success": True,
        "module": "reports",
        "pdf": True,
        "excel": True,
    }