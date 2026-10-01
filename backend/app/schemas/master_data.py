from pydantic import BaseModel, ConfigDict, Field


class UniversityCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    city: str | None = Field(default=None, max_length=100)
    state: str | None = Field(default=None, max_length=100)


class UniversityResponse(BaseModel):
    id: int
    name: str
    code: str
    city: str | None
    state: str | None


class DepartmentCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    university_id: int


class DepartmentResponse(BaseModel):
    id: int
    name: str
    code: str
    university_id: int


class ProgrammeCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    department_id: int
    duration_years: int = Field(ge=1, le=10)
    category: str | None = Field(default=None, max_length=100)


class ProgrammeSpecializationCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)


class ProgrammeSpecializationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    programme_id: int
    name: str
    code: str
    is_active: bool


class ProgrammeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    code: str
    department_id: int
    duration_years: int
    category: str | None
    is_active: bool
    specializations: list[ProgrammeSpecializationResponse] = []


class AcademicSessionCreateRequest(BaseModel):
    name: str = Field(min_length=4, max_length=50)
    start_year: int = Field(ge=2000, le=2100)
    end_year: int = Field(ge=2000, le=2100)


class AcademicSessionResponse(BaseModel):
    id: int
    name: str
    start_year: int
    end_year: int
    is_active: bool


class SemesterCreateRequest(BaseModel):
    number: int = Field(ge=1, le=20)
    name: str = Field(min_length=2, max_length=100)
    academic_year: str | None = Field(default=None, max_length=50)


class SemesterResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    number: int
    name: str
    academic_year: str | None


class CourseCreateRequest(BaseModel):
    code: str = Field(min_length=2, max_length=50)
    name: str = Field(min_length=2, max_length=200)
    credits: int = Field(ge=0, le=100)
    department_id: int | None = None


class CourseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    code: str
    name: str
    credits: int
    department_id: int | None
