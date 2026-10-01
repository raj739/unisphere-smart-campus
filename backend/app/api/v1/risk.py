from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles
from app.core.security import get_current_user
from app.models.risk_assessment import RiskAssessment
from app.models.early_warning import EarlyWarning
from app.models.intervention import Intervention
from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.result import Result
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.student_fee_invoice_v2 import StudentFeeInvoiceV2
from app.schemas.risk import (
    PredictiveRunResponse,
    PredictiveStudentResponse,
    RiskAssessmentResponse,
    RiskCalculateRequest,
)
from app.services.risk_engine import RiskEngine
from app.services.early_warning_engine import EarlyWarningEngine


router = APIRouter(
    prefix="/risk",
    tags=["Risk Engine"],
)

_STAFF_ROLES = {"admin", "superadmin", "super_admin", "staff", "faculty"}


def _student_signals(student: Student, db: Session) -> dict:
    offering_ids = [
        row.course_offering_id
        for row in db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    ]
    session_ids = []
    if offering_ids:
        session_ids = [
            row.id
            for row in db.query(AttendanceSessionV2.id)
            .filter(AttendanceSessionV2.course_offering_id.in_(offering_ids))
            .all()
        ]
    attendance_records = []
    if session_ids:
        attendance_records = (
            db.query(AttendanceRecordV2)
            .filter(
                AttendanceRecordV2.student_id == student.id,
                AttendanceRecordV2.attendance_session_id.in_(session_ids),
            )
            .all()
        )
    counted_attendance = [
        item for item in attendance_records if item.status != "excused"
    ]
    attended = sum(
        1 for item in counted_attendance if item.status in {"present", "late"}
    )
    attendance = (
        round((attended / len(counted_attendance)) * 100, 2)
        if counted_attendance
        else None
    )
    engagement = (
        round(
            sum(
                1.0 if item.status in {"present", "late"} else 0.5
                if item.status == "excused"
                else 0.0
                for item in attendance_records
            )
            / len(attendance_records)
            * 100,
            2,
        )
        if attendance_records
        else None
    )
    results = (
        db.query(Result)
        .filter(Result.student_id == student.id, Result.marks.is_not(None))
        .all()
    )
    academic = (
        round(sum(float(item.marks) for item in results) / len(results), 2)
        if results
        else None
    )
    invoices = (
        db.query(StudentFeeInvoiceV2)
        .filter(StudentFeeInvoiceV2.student_id == student.id)
        .all()
    )
    outstanding = round(
        sum(max(float(item.outstanding_amount or 0), 0) for item in invoices),
        2,
    )
    evidence_count = int(bool(attendance_records)) + int(bool(results))
    if len(attendance_records) >= 5 and len(results) >= 2:
        confidence = "high"
    elif evidence_count:
        confidence = "medium"
    else:
        confidence = "low"
    return {
        "attendance": attendance,
        "academic": academic,
        "outstanding": outstanding,
        "engagement": engagement,
        "attendance_records": len(attendance_records),
        "result_count": len(results),
        "confidence": confidence,
    }


def _predictive_response(
    student: Student,
    assessment: RiskAssessment,
    signals: dict,
) -> PredictiveStudentResponse:
    has_evidence = signals["attendance"] is not None or signals["academic"] is not None
    if not has_evidence:
        performance = "Insufficient data"
        dropout_probability = None
    else:
        performance_inputs = [
            value
            for value in (signals["attendance"], signals["academic"])
            if value is not None
        ]
        projected_score = sum(performance_inputs) / len(performance_inputs)
        if projected_score >= 85:
            performance = "Excellent trajectory"
        elif projected_score >= 70:
            performance = "On track"
        elif projected_score >= 55:
            performance = "Needs support"
        else:
            performance = "Academic risk"
        dropout_probability = round(assessment.risk_score, 2)
    return PredictiveStudentResponse(
        assessment_id=assessment.id,
        student_id=student.id,
        uni_id=student.uni_id,
        student_name=student.full_name,
        programme=student.programme,
        risk_score=assessment.risk_score,
        risk_level=assessment.risk_level,
        predicted_performance=performance,
        dropout_probability=dropout_probability,
        attendance_percentage=signals["attendance"],
        academic_percentage=signals["academic"],
        outstanding_fees=signals["outstanding"],
        engagement_percentage=signals["engagement"],
        attendance_records=signals["attendance_records"],
        result_count=signals["result_count"],
        data_confidence=signals["confidence"],
        explanation=assessment.explanation,
        recommended_action=assessment.recommended_action,
        calculated_at=assessment.calculated_at,
    )


def _sync_predictive_warnings(
    student: Student,
    assessment: RiskAssessment,
    signals: dict,
    db: Session,
) -> int:
    active_warnings = (
        db.query(EarlyWarning)
        .filter(
            EarlyWarning.student_id == student.id,
            EarlyWarning.risk_assessment_id.is_not(None),
            EarlyWarning.is_active.is_(True),
        )
        .all()
    )
    for warning in active_warnings:
        has_active_intervention = (
            db.query(Intervention)
            .filter(
                Intervention.warning_id == warning.id,
                Intervention.status.notin_({"Completed", "Cancelled"}),
            )
            .first()
            is not None
        )
        if not has_active_intervention:
            warning.status = "Superseded"
            warning.is_active = False

    if signals["attendance"] is None and signals["academic"] is None:
        return 0

    warning_signals = EarlyWarningEngine.generate(
        attendance=signals["attendance"] if signals["attendance"] is not None else 100.0,
        academic_percentage=signals["academic"] if signals["academic"] is not None else 100.0,
        fee_due=signals["outstanding"],
        engagement=signals["engagement"] if signals["engagement"] is not None else 100.0,
        risk_score=assessment.risk_score,
        risk_level=assessment.risk_level,
    )
    for signal in warning_signals:
        db.add(
            EarlyWarning(
                student_id=student.id,
                risk_assessment_id=assessment.id,
                warning_type=signal.warning_type,
                severity=signal.severity,
                title=signal.title,
                message=signal.message,
                trigger_value=signal.trigger_value,
                threshold_value=signal.threshold_value,
                recommended_action=signal.recommended_action,
                status="Open",
                is_active=True,
            )
        )
    return len(warning_signals)


@router.post(
    "/calculate",
    response_model=RiskAssessmentResponse,
)
def calculate_risk(
    payload: RiskCalculateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found.",
        )

    result = RiskEngine.calculate(
        attendance=payload.attendance,
        academic_percentage=payload.academic_percentage,
        fee_due=payload.fee_due,
        engagement=payload.engagement,
    )

    db.query(RiskAssessment).filter(
        RiskAssessment.student_id == student.id,
        RiskAssessment.is_active.is_(True),
    ).update(
        {"is_active": False},
        synchronize_session=False,
    )

    assessment = RiskAssessment(
        student_id=student.id,
        risk_score=result.score,
        risk_level=result.level,
        attendance_score=result.attendance_score,
        academic_score=result.academic_score,
        fee_score=result.fee_score,
        engagement_score=result.engagement_score,
        attendance_weight=RiskEngine.ATTENDANCE_WEIGHT,
        academic_weight=RiskEngine.ACADEMIC_WEIGHT,
        fee_weight=RiskEngine.FEE_WEIGHT,
        engagement_weight=RiskEngine.ENGAGEMENT_WEIGHT,
        explanation=result.explanation,
        recommended_action=result.recommended_action,
        is_active=True,
    )

    db.add(assessment)
    db.commit()
    db.refresh(assessment)

    return assessment


@router.get(
    "/me",
    response_model=RiskAssessmentResponse,
)
def get_my_risk(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found.",
        )

    assessment = (
        db.query(RiskAssessment)
        .filter(
            RiskAssessment.student_id == student.id,
            RiskAssessment.is_active.is_(True),
        )
        .order_by(desc(RiskAssessment.calculated_at))
        .first()
    )

    if not assessment:
        raise HTTPException(
            status_code=404,
            detail="No risk assessment available.",
        )

    return assessment


@router.get(
    "/me/prediction",
    response_model=PredictiveStudentResponse,
)
def get_my_predictive_result(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student profile not found.")
    assessment = (
        db.query(RiskAssessment)
        .filter(
            RiskAssessment.student_id == student.id,
            RiskAssessment.is_active.is_(True),
        )
        .order_by(desc(RiskAssessment.calculated_at))
        .first()
    )
    if assessment is None:
        raise HTTPException(
            status_code=404,
            detail="No prediction is available yet.",
        )
    return _predictive_response(
        student,
        assessment,
        _student_signals(student, db),
    )


@router.get(
    "/students",
    response_model=list[RiskAssessmentResponse],
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def get_risk_students(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """List all active risk assessments. Staff/admin only."""
    assessments = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.is_active.is_(True))
        .order_by(desc(RiskAssessment.risk_score))
        .all()
    )

    return assessments


@router.get(
    "/dashboard",
    response_model=list[PredictiveStudentResponse],
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def get_predictive_dashboard(db: Session = Depends(get_db)):
    assessments = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.is_active.is_(True))
        .order_by(desc(RiskAssessment.risk_score))
        .all()
    )
    students = {
        student.id: student
        for student in db.query(Student)
        .filter(Student.id.in_([item.student_id for item in assessments]))
        .all()
    } if assessments else {}
    return [
        _predictive_response(
            students[item.student_id],
            item,
            _student_signals(students[item.student_id], db),
        )
        for item in assessments
        if item.student_id in students
    ]


@router.post(
    "/recalculate-all",
    response_model=PredictiveRunResponse,
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def recalculate_all_student_risk(db: Session = Depends(get_db)):
    students = db.query(Student).order_by(Student.full_name.asc()).all()
    responses = []
    warnings_created = 0
    for student in students:
        signals = _student_signals(student, db)
        result = RiskEngine.calculate(
            attendance=signals["attendance"] if signals["attendance"] is not None else 85.0,
            academic_percentage=signals["academic"] if signals["academic"] is not None else 75.0,
            fee_due=signals["outstanding"],
            engagement=signals["engagement"] if signals["engagement"] is not None else 85.0,
        )
        has_evidence = signals["attendance"] is not None or signals["academic"] is not None
        risk_level = result.level if has_evidence else "Insufficient Data"
        db.query(RiskAssessment).filter(
            RiskAssessment.student_id == student.id,
            RiskAssessment.is_active.is_(True),
        ).update({"is_active": False}, synchronize_session=False)
        evidence_note = (
            f" Data confidence is {signals['confidence']}; "
            f"based on {signals['attendance_records']} attendance records "
            f"and {signals['result_count']} published results."
        )
        assessment = RiskAssessment(
            student_id=student.id,
            risk_score=result.score,
            risk_level=risk_level,
            attendance_score=result.attendance_score,
            academic_score=result.academic_score,
            fee_score=result.fee_score,
            engagement_score=result.engagement_score,
            attendance_weight=RiskEngine.ATTENDANCE_WEIGHT,
            academic_weight=RiskEngine.ACADEMIC_WEIGHT,
            fee_weight=RiskEngine.FEE_WEIGHT,
            engagement_weight=RiskEngine.ENGAGEMENT_WEIGHT,
            explanation=(
                result.explanation + evidence_note
                if has_evidence
                else "No attendance or published-result evidence is available. "
                "A risk prediction has not been assigned."
            ),
            recommended_action=(
                result.recommended_action
                if has_evidence
                else "Record attendance and publish assessed marks before using this prediction."
            ),
            is_active=True,
        )
        db.add(assessment)
        db.flush()
        warnings_created += _sync_predictive_warnings(
            student,
            assessment,
            signals,
            db,
        )
        responses.append(_predictive_response(student, assessment, signals))
    db.commit()
    responses.sort(key=lambda item: item.risk_score, reverse=True)
    return PredictiveRunResponse(
        students_evaluated=len(responses),
        high_risk=sum(1 for item in responses if item.risk_level == "High"),
        medium_risk=sum(1 for item in responses if item.risk_level == "Medium"),
        low_risk=sum(1 for item in responses if item.risk_level == "Low"),
        insufficient_data=sum(
            1 for item in responses if item.risk_level == "Insufficient Data"
        ),
        warnings_created=warnings_created,
        active_warnings=(
            db.query(EarlyWarning)
            .filter(EarlyWarning.is_active.is_(True))
            .count()
        ),
        assessments=responses,
    )

