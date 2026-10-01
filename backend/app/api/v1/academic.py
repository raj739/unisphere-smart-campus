from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.attendance import Attendance
from app.models.course import Course
from app.models.examination import Examination
from app.models.result import Result
from app.models.student import Student
from app.models.student_course import StudentCourse
from app.models.timetable import TimetableEntry
from app.models.user import User

router = APIRouter(
    prefix="/academic",
    tags=["Academic"],
)


def get_current_student(
    current_user: User,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


@router.get("/courses")
def get_my_courses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(StudentCourse, Course)
        .join(Course, StudentCourse.course_id == Course.id)
        .filter(StudentCourse.student_id == student.id)
        .all()
    )

    return [
        {
            "id": course.id,
            "code": course.code,
            "name": course.name,
            "credits": course.credits,
            "semester_id": student_course.semester_id,
        }
        for student_course, course in records
    ]


@router.get("/attendance")
def get_my_attendance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(Attendance, Course)
        .join(Course, Attendance.course_id == Course.id)
        .filter(Attendance.student_id == student.id)
        .all()
    )

    return [
        {
            "course_id": course.id,
            "course_code": course.code,
            "course_name": course.name,
            "classes_held": attendance.classes_held,
            "classes_attended": attendance.classes_attended,
            "percentage": attendance.percentage,
        }
        for attendance, course in records
    ]


@router.get("/results")
def get_my_results(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(Result, Course)
        .join(Course, Result.course_id == Course.id)
        .filter(Result.student_id == student.id)
        .all()
    )

    return [
        {
            "course_id": course.id,
            "course_code": course.code,
            "course_name": course.name,
            "semester_id": result.semester_id,
            "grade": result.grade,
            "grade_point": result.grade_point,
            "marks": result.marks,
        }
        for result, course in records
    ]


@router.get("/timetable")
def get_my_timetable(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(TimetableEntry, Course)
        .join(Course, TimetableEntry.course_id == Course.id)
        .join(
            StudentCourse,
            StudentCourse.course_id == Course.id,
        )
        .filter(StudentCourse.student_id == student.id)
        .all()
    )

    return [
        {
            "id": timetable.id,
            "course_code": course.code,
            "course_name": course.name,
            "day_of_week": timetable.day_of_week,
            "start_time": timetable.start_time,
            "end_time": timetable.end_time,
            "faculty_name": timetable.faculty_name,
            "room": timetable.room,
            "session_type": timetable.session_type,
        }
        for timetable, course in records
    ]


@router.get("/examinations")
def get_my_examinations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_current_student(current_user, db)

    records = (
        db.query(Examination, Course)
        .join(Course, Examination.course_id == Course.id)
        .join(
            StudentCourse,
            StudentCourse.course_id == Course.id,
        )
        .filter(StudentCourse.student_id == student.id)
        .all()
    )

    return [
        {
            "id": examination.id,
            "course_code": course.code,
            "course_name": course.name,
            "examination_name": examination.examination_name,
            "exam_date": examination.exam_date,
            "start_time": examination.start_time,
            "end_time": examination.end_time,
            "venue": examination.venue,
        }
        for examination, course in records
    ]
