from pydantic import BaseModel, EmailStr, Field


class StudentIdentityResponse(BaseModel):
    student_id: int
    user_id: int
    uni_id: str

    full_name: str
    email: EmailStr

    university_id: str | None
    enrollment_number: str | None

    programme: str
    programme_id: int | None = None
    specialization_id: int | None = None
    curriculum_id: int | None = None
    academic_session_id: int | None = None
    current_semester: int
    academic_session: str | None

    department_id: int

    role: str
    is_active: bool


class StudentIdentityUpdateRequest(BaseModel):
    full_name: str | None = Field(
        default=None,
        min_length=2,
        max_length=200,
    )

    university_id: str | None = Field(
        default=None,
        max_length=100,
    )

    enrollment_number: str | None = Field(
        default=None,
        max_length=100,
    )

    programme: str | None = Field(
        default=None,
        min_length=2,
        max_length=150,
    )

    current_semester: int | None = Field(
        default=None,
        ge=1,
        le=20,
    )

    academic_session: str | None = Field(
        default=None,
        max_length=50,
    )


class AccountStatusRequest(BaseModel):
    is_active: bool


class StudentIdentifierResponse(BaseModel):
    id: int
    identifier_type: str
    identifier_value: str
    issuing_authority: str | None
    is_verified: bool


class StudentIdentifierCreateRequest(BaseModel):
    identifier_type: str = Field(
        min_length=2,
        max_length=50,
    )

    identifier_value: str = Field(
        min_length=1,
        max_length=150,
    )

    issuing_authority: str | None = Field(
        default=None,
        max_length=200,
    )

    is_verified: bool = False
