from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.models.academic_session import AcademicSession
from app.models.department import Department
from app.models.programme import Programme
from app.models.programme_specialization import ProgrammeSpecialization
from app.models.course import Course
from app.models.semester import Semester
from app.models.university import University
from app.models.user import User
from app.schemas.master_data import (
    AcademicSessionCreateRequest,
    AcademicSessionResponse,
    DepartmentCreateRequest,
    DepartmentResponse,
    ProgrammeCreateRequest,
    ProgrammeResponse,
    ProgrammeSpecializationCreateRequest,
    ProgrammeSpecializationResponse,
    UniversityCreateRequest,
    UniversityResponse,
    SemesterCreateRequest,
    SemesterResponse,
    CourseCreateRequest,
    CourseResponse,
)

router = APIRouter(
    prefix="/master-data",
    tags=["University Master Data"],
)


@router.post(
    "/universities",
    response_model=UniversityResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_university(
    request: UniversityCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    code = request.code.strip().upper()

    existing = (
        db.query(University)
        .filter(University.code == code)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="University code already exists",
        )

    university = University(
        name=request.name.strip(),
        code=code,
        city=request.city.strip() if request.city else None,
        state=request.state.strip() if request.state else None,
    )

    db.add(university)
    db.commit()
    db.refresh(university)

    return university


@router.get(
    "/universities",
    response_model=list[UniversityResponse],
)
def get_universities(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(University)
        .order_by(University.id.asc())
        .all()
    )


@router.post(
    "/departments",
    response_model=DepartmentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_department(
    request: DepartmentCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    university = (
        db.query(University)
        .filter(University.id == request.university_id)
        .first()
    )

    if university is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="University not found",
        )

    code = request.code.strip().upper()

    existing = (
        db.query(Department)
        .filter(
            Department.university_id == request.university_id,
            Department.code == code,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Department code already exists in this university",
        )

    department = Department(
        name=request.name.strip(),
        code=code,
        university_id=request.university_id,
    )

    db.add(department)
    db.commit()
    db.refresh(department)

    return department


@router.get(
    "/departments",
    response_model=list[DepartmentResponse],
)
def get_departments(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(Department)
        .order_by(Department.id.asc())
        .all()
    )


@router.post(
    "/programmes",
    response_model=ProgrammeResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_programme(
    request: ProgrammeCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    department = (
        db.query(Department)
        .filter(Department.id == request.department_id)
        .first()
    )

    if department is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Department not found",
        )

    code = request.code.strip().upper()

    existing = (
        db.query(Programme)
        .filter(
            Programme.department_id == request.department_id,
            Programme.code == code,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Programme code already exists in this department",
        )

    programme = Programme(
        name=request.name.strip(),
        code=code,
        department_id=request.department_id,
        duration_years=request.duration_years,
        category=request.category.strip() if request.category else None,
        is_active=True,
    )

    db.add(programme)
    db.commit()
    db.refresh(programme)

    return programme


@router.get(
    "/programmes",
    response_model=list[ProgrammeResponse],
)
def get_programmes(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(Programme)
        .order_by(Programme.category.asc(), Programme.name.asc())
        .all()
    )


@router.post(
    "/programmes/{programme_id}/specializations",
    response_model=ProgrammeSpecializationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_programme_specialization(
    programme_id: int,
    request: ProgrammeSpecializationCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    programme = db.query(Programme).filter(Programme.id == programme_id).first()
    if programme is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Programme not found",
        )

    name = request.name.strip()
    existing = (
        db.query(ProgrammeSpecialization)
        .filter(
            ProgrammeSpecialization.programme_id == programme_id,
            ProgrammeSpecialization.name == name,
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Specialization already exists in this programme",
        )

    specialization = ProgrammeSpecialization(
        programme_id=programme_id,
        name=name,
        code=request.code.strip().upper(),
        is_active=True,
    )
    db.add(specialization)
    db.commit()
    db.refresh(specialization)
    return specialization


@router.post(
    "/academic-sessions",
    response_model=AcademicSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_academic_session(
    request: AcademicSessionCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    if request.end_year <= request.start_year:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="End year must be greater than start year",
        )

    name = request.name.strip()

    existing = (
        db.query(AcademicSession)
        .filter(AcademicSession.name == name)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Academic session already exists",
        )

    session = AcademicSession(
        name=name,
        start_year=request.start_year,
        end_year=request.end_year,
        is_active=True,
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


@router.get(
    "/academic-sessions",
    response_model=list[AcademicSessionResponse],
)
def get_academic_sessions(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(AcademicSession)
        .order_by(AcademicSession.start_year.desc())
        .all()
    )


@router.post(
    "/semesters",
    response_model=SemesterResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_semester(
    request: SemesterCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    existing = (
        db.query(Semester)
        .filter(Semester.number == request.number, Semester.academic_year == request.academic_year)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Semester already exists for this academic year",
        )
    semester = Semester(
        number=request.number,
        name=request.name.strip(),
        academic_year=request.academic_year.strip() if request.academic_year else None,
    )
    db.add(semester)
    db.commit()
    db.refresh(semester)
    return semester


@router.get(
    "/semesters",
    response_model=list[SemesterResponse],
)
def get_semesters(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return db.query(Semester).order_by(Semester.number.asc(), Semester.id.asc()).all()


@router.post(
    "/courses",
    response_model=CourseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_course(
    request: CourseCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    code = request.code.strip().upper()
    existing = db.query(Course).filter(Course.code == code).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Course code already exists",
        )
    course = Course(
        code=code,
        name=request.name.strip(),
        credits=request.credits,
        department_id=request.department_id,
    )
    db.add(course)
    db.commit()
    db.refresh(course)
    return course


@router.get(
    "/courses",
    response_model=list[CourseResponse],
)
def get_courses(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return db.query(Course).order_by(Course.code.asc()).all()
