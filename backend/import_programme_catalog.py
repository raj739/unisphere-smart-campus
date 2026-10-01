"""Idempotently load the 2026-27 Vikram University programme catalogue."""

from app.core.database import SessionLocal
from app.data.vikram_programme_catalog import CATALOG, DEPARTMENTS
from app.models.department import Department
from app.models.programme import Programme
from app.models.programme_specialization import ProgrammeSpecialization
from app.models.university import University


def import_catalog() -> dict[str, int]:
    db = SessionLocal()
    stats = {
        "departments_created": 0,
        "programmes_created": 0,
        "programmes_updated": 0,
        "specializations_created": 0,
        "specializations_updated": 0,
    }

    try:
        university = (
            db.query(University).filter(University.code == "VU").first()
            or db.query(University).order_by(University.id.asc()).first()
        )
        if university is None:
            university = University(
                name="Vikram University",
                code="VU",
                city="Ujjain",
                state="Madhya Pradesh",
            )
            db.add(university)
            db.flush()

        departments: dict[str, Department] = {}
        for code, name in DEPARTMENTS.items():
            department = (
                db.query(Department)
                .filter(
                    Department.university_id == university.id,
                    Department.code == code,
                )
                .first()
            )
            if department is None:
                department = Department(
                    university_id=university.id,
                    code=code,
                    name=name,
                )
                db.add(department)
                db.flush()
                stats["departments_created"] += 1
            elif department.name != name:
                department.name = name
            departments[code] = department

        for item in CATALOG:
            programme = (
                db.query(Programme)
                .filter(Programme.code == item["code"])
                .first()
            )
            department = departments[item["department"]]
            if programme is None:
                programme = Programme(
                    name=item["name"],
                    code=item["code"],
                    department_id=department.id,
                    duration_years=item["duration_years"],
                    category=item["category"],
                    is_active=True,
                )
                db.add(programme)
                db.flush()
                stats["programmes_created"] += 1
            else:
                programme.name = item["name"]
                programme.department_id = department.id
                programme.duration_years = item["duration_years"]
                programme.category = item["category"]
                programme.is_active = True
                stats["programmes_updated"] += 1

            for index, name in enumerate(item["specializations"], start=1):
                specialization = (
                    db.query(ProgrammeSpecialization)
                    .filter(
                        ProgrammeSpecialization.programme_id == programme.id,
                        ProgrammeSpecialization.name == name,
                    )
                    .first()
                )
                code = f"{programme.code}-{index:03d}"
                if specialization is None:
                    specialization = ProgrammeSpecialization(
                        programme_id=programme.id,
                        name=name,
                        code=code,
                        is_active=True,
                    )
                    db.add(specialization)
                    stats["specializations_created"] += 1
                else:
                    specialization.code = code
                    specialization.is_active = True
                    stats["specializations_updated"] += 1

        db.commit()
        return stats
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    results = import_catalog()
    print("Vikram University programme catalogue imported.")
    for key, value in results.items():
        print(f"{key}: {value}")
