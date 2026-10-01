from dotenv import load_dotenv

load_dotenv()

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import models
from app.api.v1.academic import router as academic_router
from app.api.v1.academic_admin import router as academic_admin_router
from app.api.v1.academic_passport import router as academic_passport_router
from app.api.v1.admin import router as admin_router
from app.api.v1.ai import router as ai_router
from app.api.v1.ai_v2 import router as ai_v2_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.attendance_v2 import router as attendance_v2_router
from app.api.v1.audit import router as audit_router
from app.api.v1.auth import router as auth_router
from app.api.v1.certificates import router as certificates_router
from app.api.v1.curricula import router as curricula_router
from app.api.v1.documents import router as documents_router
from app.api.v1.early_warning import router as early_warning_router
from app.api.v1.enrollment import router as enrollment_router
from app.api.v1.events import router as events_router
from app.api.v1.examinations_v2 import router as examinations_v2_router
from app.api.v1.fees import router as fees_router
from app.api.v1.fees_v2 import router as fees_v2_router
from app.api.v1.helpdesk import router as helpdesk_router
from app.api.v1.helpdesk_v2 import router as helpdesk_v2_router
from app.api.v1.hostel import router as hostel_router
from app.api.v1.hostel_v2 import router as hostel_v2_router
from app.api.v1.identity import router as identity_router
from app.api.v1.interventions import router as intervention_router
from app.api.v1.interventions_v2 import router as interventions_v2_router
from app.api.v1.lifecycle import router as lifecycle_router
from app.api.v1.master_data import router as master_data_router
from app.api.v1.notifications_v2 import router as notifications_v2_router
from app.api.v1.parent import router as parent_router
from app.api.v1.parent_v2 import router as parent_v2_router
from app.api.v1.passport_sharing import router as passport_sharing_router
from app.api.v1.payments_v2 import router as payments_v2_router
from app.api.v1.rbac import router as rbac_router
from app.api.v1.realtime import router as realtime_router
from app.api.v1.recommendations import router as recommendations_router
from app.api.v1.reports import router as reports_router
from app.api.v1.risk import router as risk_router
from app.api.v1.students import router as students_router
from app.api.v1.timetable_v2 import router as timetable_v2_router
from app.api.v1.transport import router as transport_router
from app.api.v1.transport_v2 import router as transport_v2_router
from app.api.v1.voice_v2 import router as voice_v2_router
from app.core.database import get_db
from app.core.production_settings import validate_production_settings
from app.models.academic_session import AcademicSession
from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.course_offering import CourseOffering
from app.models.examination_registration_paper_v2 import ExaminationRegistrationPaperV2
from app.models.examination_registration_v2 import ExaminationRegistrationV2
from app.models.examination_schedule_v2 import ExaminationScheduleV2
from app.models.examination_v2 import ExaminationV2
from app.models.programme import Programme
from app.models.student_enrollment import StudentEnrollment
from app.models.student_lifecycle import StudentLifecycle
from app.models.student_lifecycle_event import StudentLifecycleEvent
from app.models.timetable_entry_v2 import TimetableEntryV2

settings = validate_production_settings()

app = FastAPI(
    title="UniSphere API",
    description="Smart University Digital Campus Platform",
    version="1.0.0",
    debug=settings.debug,
)

if settings.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.allowed_origins),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# ── v1 core routers ──────────────────────────────────────────────────────────
app.include_router(auth_router, prefix="/api/v1")
app.include_router(rbac_router, prefix="/api/v1")
app.include_router(students_router, prefix="/api/v1")
app.include_router(academic_router, prefix="/api/v1")
app.include_router(fees_router, prefix="/api/v1")
app.include_router(certificates_router, prefix="/api/v1")
app.include_router(hostel_router, prefix="/api/v1")
app.include_router(transport_router, prefix="/api/v1")
app.include_router(helpdesk_router, prefix="/api/v1")
app.include_router(parent_router, prefix="/api/v1")
app.include_router(admin_router, prefix="/api/v1")
app.include_router(risk_router, prefix="/api/v1")
app.include_router(intervention_router, prefix="/api/v1")
app.include_router(ai_router, prefix="/api/v1")
app.include_router(recommendations_router, prefix="/api/v1")
app.include_router(voice_v2_router, prefix="/api/v1")

# ── v2 routers ───────────────────────────────────────────────────────────────
app.include_router(identity_router, prefix="/api/v1")
app.include_router(master_data_router, prefix="/api/v1")
app.include_router(curricula_router, prefix="/api/v1")
app.include_router(academic_admin_router, prefix="/api/v1")
app.include_router(lifecycle_router, prefix="/api/v1")
app.include_router(enrollment_router, prefix="/api/v1")
app.include_router(timetable_v2_router, prefix="/api/v1")
app.include_router(attendance_v2_router, prefix="/api/v1")
app.include_router(examinations_v2_router, prefix="/api/v1")
app.include_router(documents_router, prefix="/api/v1")
app.include_router(fees_v2_router, prefix="/api/v1")
app.include_router(payments_v2_router, prefix="/api/v1")
app.include_router(hostel_v2_router, prefix="/api/v1")
app.include_router(helpdesk_v2_router, prefix="/api/v1")
app.include_router(parent_v2_router, prefix="/api/v1")
app.include_router(notifications_v2_router, prefix="/api/v1")
app.include_router(ai_v2_router, prefix="/api/v1")
app.include_router(transport_v2_router, prefix="/api/v1")
app.include_router(early_warning_router, prefix="/api/v1")
app.include_router(interventions_v2_router, prefix="/api/v1")
app.include_router(academic_passport_router, prefix="/api/v1")
app.include_router(passport_sharing_router, prefix="/api/v1")
app.include_router(audit_router, prefix="/api/v1")
app.include_router(realtime_router, prefix="/api/v1")
app.include_router(events_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")
app.include_router(reports_router, prefix="/api/v1")


@app.get("/")
def root():
    return {
        "message": "UniSphere API is running",
        "platform": "Smart University Digital Campus",
        "version": "1.0.0",
    }


@app.get("/api/v1/health")
def health_check():
    return {
        "status": "healthy",
        "service": "unisphere-api",
    }


@app.get("/api/v1/health/database")
@app.get("/health/database")
def database_health(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT 1"))

    return {
        "status": "healthy",
        "database": "connected",
        "result": result.scalar(),
    }
