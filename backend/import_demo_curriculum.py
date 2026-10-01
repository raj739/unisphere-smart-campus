"""Idempotently import the supplied demo curriculum workbook."""

from __future__ import annotations

import argparse
import os
import re
import sys
import unicodedata
import zipfile
from collections import defaultdict
from pathlib import Path
from xml.etree import ElementTree as ET


BACKEND_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND_DIR / ".runtime_packages"))
sys.path.insert(0, str(BACKEND_DIR))
os.environ.setdefault(
    "DATABASE_URL",
    f"sqlite:///{(BACKEND_DIR / 'unisphere_flow.db').as_posix()}",
)

from app.core.database import SessionLocal
from app.models.academic_session import AcademicSession
from app.models.course import Course
from app.models.curriculum import Curriculum
from app.models.curriculum_course import CurriculumCourse
from app.models.programme import Programme
from app.models.programme_specialization import ProgrammeSpecialization
from app.models.semester import Semester


NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
REL_NS = {"r": "http://schemas.openxmlformats.org/package/2006/relationships"}
DOC_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
VERSION = "2026-27-demo-v1"
SOURCE_NAME = "Vikram University Demo Curriculum with Credit Summaries"
DISCLAIMER = "Demo/sample curriculum for workflow testing; not an official Vikram University syllabus."
SPECIALIZATION_ALIASES = {
    ("bcom", "bfsiandportalvariants"): "bfsi",
    ("mcom", "plain2year"): "plain",
    ("mjmc", "plain1yearand2yearvariants"): "2year",
}


def _column_index(reference: str) -> int:
    letters = "".join(character for character in reference if character.isalpha())
    value = 0
    for letter in letters:
        value = value * 26 + ord(letter.upper()) - 64
    return value - 1


def _sheet_rows(path: Path, wanted_sheet: str) -> list[list[str]]:
    with zipfile.ZipFile(path) as archive:
        shared: list[str] = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in root.findall("m:si", NS):
                shared.append("".join(node.text or "" for node in item.iterfind(".//m:t", NS)))

        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        targets = {item.attrib["Id"]: item.attrib["Target"] for item in relationships.findall("r:Relationship", REL_NS)}
        sheet_path = None
        for sheet in workbook.findall("m:sheets/m:sheet", NS):
            if sheet.attrib["name"] == wanted_sheet:
                target = targets[sheet.attrib[f"{{{DOC_REL}}}id"]].lstrip("/")
                sheet_path = target if target.startswith("xl/") else f"xl/{target}"
                break
        if sheet_path is None:
            raise ValueError(f"Worksheet not found: {wanted_sheet}")

        root = ET.fromstring(archive.read(sheet_path))
        rows: list[list[str]] = []
        for row in root.findall("m:sheetData/m:row", NS):
            values: list[str] = []
            for cell in row.findall("m:c", NS):
                index = _column_index(cell.attrib.get("r", "A1"))
                while len(values) <= index:
                    values.append("")
                cell_type = cell.attrib.get("t")
                value_node = cell.find("m:v", NS)
                if cell_type == "inlineStr":
                    value = "".join(node.text or "" for node in cell.iterfind(".//m:t", NS))
                elif value_node is None:
                    value = ""
                elif cell_type == "s":
                    value = shared[int(value_node.text or "0")]
                else:
                    value = value_node.text or ""
                values[index] = value.strip()
            rows.append(values)
        return rows


def _normalise(value: str) -> str:
    value = unicodedata.normalize("NFKD", value.casefold()).replace("&", "and")
    return re.sub(r"[^a-z0-9]+", "", value)


def _integer(value: str) -> int:
    return int(float(value or "0"))


def _records(path: Path) -> list[dict[str, str]]:
    rows = _sheet_rows(path, "Curriculum Master")
    headers = rows[0]
    return [dict(zip(headers, row)) for row in rows[1:] if row and row[0]]


def import_workbook(path: Path, dry_run: bool = False) -> dict[str, int]:
    records = _records(path)
    db = SessionLocal()
    stats = {
        "workbook_rows": len(records),
        "curricula_created": 0,
        "curricula_updated": 0,
        "courses_created": 0,
        "courses_updated": 0,
        "curriculum_links_created": 0,
        "curriculum_links_updated": 0,
        "semesters_created": 0,
    }
    try:
        programmes = db.query(Programme).all()
        programme_map = {_normalise(item.name): item for item in programmes}
        specializations = db.query(ProgrammeSpecialization).all()
        specialization_map = {
            (item.programme_id, _normalise(item.name)): item for item in specializations
        }

        unmatched_programmes: set[str] = set()
        unmatched_specializations: set[str] = set()
        resolved: list[tuple[dict[str, str], Programme, ProgrammeSpecialization | None]] = []
        for record in records:
            programme_name = record["Programme"]
            programme = programme_map.get(_normalise(programme_name))
            if programme is None:
                unmatched_programmes.add(programme_name)
                continue
            specialization_name = record["Specialisation / Subject"]
            specialization_key = SPECIALIZATION_ALIASES.get(
                (_normalise(programme_name), _normalise(specialization_name)),
                _normalise(specialization_name),
            )
            specialization = specialization_map.get(
                (programme.id, specialization_key)
            )
            if specialization is None and specialization_key != "plain":
                unmatched_specializations.add(f"{programme_name} / {specialization_name}")
                continue
            resolved.append((record, programme, specialization))

        if unmatched_programmes or unmatched_specializations:
            details = [
                *(f"programme: {value}" for value in sorted(unmatched_programmes)),
                *(f"specialization: {value}" for value in sorted(unmatched_specializations)),
            ]
            raise ValueError("Workbook catalogue mismatch:\n" + "\n".join(details))

        if dry_run:
            db.rollback()
            return {**stats, "matched_rows": len(resolved)}

        max_semester = max(_integer(record["Semester"]) for record, _, _ in resolved)
        existing_semester_numbers = {item.number for item in db.query(Semester).all()}
        for number in range(1, max_semester + 1):
            if number not in existing_semester_numbers:
                db.add(Semester(number=number, name=f"Semester {number}", academic_year="2026-27"))
                stats["semesters_created"] += 1

        academic_session = (
            db.query(AcademicSession)
            .filter(AcademicSession.is_active.is_(True))
            .order_by(AcademicSession.start_year.desc())
            .first()
        )
        grouped: dict[tuple[int, int | None], list[dict[str, str]]] = defaultdict(list)
        resolved_entities: dict[tuple[int, int | None], tuple[Programme, ProgrammeSpecialization | None]] = {}
        for record, programme, specialization in resolved:
            key = (programme.id, specialization.id if specialization else None)
            grouped[key].append(record)
            resolved_entities[key] = (programme, specialization)

        curricula: dict[tuple[int, int | None], Curriculum] = {}
        for key, group in grouped.items():
            programme, specialization = resolved_entities[key]
            specialization_code = specialization.code if specialization else "PLAIN"
            catalog_key = f"{programme.code}:{specialization_code}"
            curriculum = (
                db.query(Curriculum)
                .filter(Curriculum.catalog_key == catalog_key, Curriculum.version == VERSION)
                .first()
            )
            display_name = specialization.name if specialization else group[0]["Specialisation / Subject"]
            if curriculum is None:
                curriculum = Curriculum(
                    catalog_key=catalog_key,
                    programme_id=programme.id,
                    specialization_id=specialization.id if specialization else None,
                    academic_session_id=academic_session.id if academic_session else None,
                    name=f"{programme.name} - {display_name} Demo Curriculum",
                    version=VERSION,
                    status="draft",
                    is_demo=True,
                    source_name=SOURCE_NAME,
                    disclaimer=DISCLAIMER,
                )
                db.add(curriculum)
                db.flush()
                stats["curricula_created"] += 1
            else:
                curriculum.academic_session_id = academic_session.id if academic_session else None
                curriculum.source_name = SOURCE_NAME
                curriculum.disclaimer = DISCLAIMER
                curriculum.is_demo = True
                stats["curricula_updated"] += 1
            curricula[key] = curriculum

        existing_courses = {
            item.code: item
            for item in db.query(Course).filter(Course.code.like("DEMO-%")).all()
        }
        existing_links = {
            (item.curriculum_id, item.semester_number, item.source_paper_code): item
            for item in db.query(CurriculumCourse).all()
        }
        display_order: dict[tuple[int, int], int] = defaultdict(int)
        for record, programme, specialization in resolved:
            row_id = _integer(record["ID"])
            course_code = f"DEMO-{row_id:05d}"
            credits = _integer(record["Total Credits"])
            course = existing_courses.get(course_code)
            if course is None:
                course = Course(
                    code=course_code,
                    name=record["Paper / Course Title"],
                    credits=credits,
                    department_id=programme.department_id,
                )
                db.add(course)
                db.flush()
                existing_courses[course_code] = course
                stats["courses_created"] += 1
            else:
                course.name = record["Paper / Course Title"]
                course.credits = credits
                course.department_id = programme.department_id
                stats["courses_updated"] += 1

            key = (programme.id, specialization.id if specialization else None)
            curriculum = curricula[key]
            semester_number = _integer(record["Semester"])
            source_paper_code = record["Paper Code"]
            display_key = (curriculum.id, semester_number)
            display_order[display_key] += 1
            link_key = (curriculum.id, semester_number, source_paper_code)
            link = existing_links.get(link_key)
            values = {
                "course_id": course.id,
                "paper_type": record["Paper Type"],
                "theory_credits": _integer(record["Theory Credits"]),
                "practical_credits": _integer(record["Practical Credits"]),
                "total_credits": credits,
                "has_practical": record["Practical Component"].casefold() == "yes",
                "display_order": display_order[display_key],
            }
            if link is None:
                link = CurriculumCourse(
                    curriculum_id=curriculum.id,
                    semester_number=semester_number,
                    source_paper_code=source_paper_code,
                    **values,
                )
                db.add(link)
                existing_links[link_key] = link
                stats["curriculum_links_created"] += 1
            else:
                for field, value in values.items():
                    setattr(link, field, value)
                stats["curriculum_links_updated"] += 1

        db.commit()
        return stats
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("workbook", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    arguments = parser.parse_args()
    results = import_workbook(arguments.workbook, arguments.dry_run)
    print("Demo curriculum workbook processed.")
    for key, value in results.items():
        print(f"{key}: {value}")
