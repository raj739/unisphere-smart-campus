"""add versioned curricula

Revision ID: c41d90a7e201
Revises: b82f41c9a401
Create Date: 2026-09-30 17:10:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c41d90a7e201"
down_revision: Union[str, Sequence[str], None] = "b82f41c9a401"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "curricula",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("catalog_key", sa.String(length=250), nullable=False),
        sa.Column("programme_id", sa.Integer(), nullable=False),
        sa.Column("specialization_id", sa.Integer(), nullable=True),
        sa.Column("academic_session_id", sa.Integer(), nullable=True),
        sa.Column("name", sa.String(length=300), nullable=False),
        sa.Column("version", sa.String(length=50), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("is_demo", sa.Boolean(), nullable=False),
        sa.Column("source_name", sa.String(length=300), nullable=True),
        sa.Column("disclaimer", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["academic_session_id"], ["academic_sessions.id"]),
        sa.ForeignKeyConstraint(["programme_id"], ["programmes.id"]),
        sa.ForeignKeyConstraint(
            ["specialization_id"],
            ["programme_specializations.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "catalog_key",
            "version",
            name="uq_curriculum_catalog_version",
        ),
    )
    op.create_index(op.f("ix_curricula_id"), "curricula", ["id"], unique=False)
    op.create_index(
        op.f("ix_curricula_catalog_key"),
        "curricula",
        ["catalog_key"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curricula_programme_id"),
        "curricula",
        ["programme_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curricula_specialization_id"),
        "curricula",
        ["specialization_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curricula_academic_session_id"),
        "curricula",
        ["academic_session_id"],
        unique=False,
    )
    op.create_index(op.f("ix_curricula_status"), "curricula", ["status"], unique=False)
    op.create_index(op.f("ix_curricula_is_demo"), "curricula", ["is_demo"], unique=False)

    op.create_table(
        "curriculum_courses",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("curriculum_id", sa.Integer(), nullable=False),
        sa.Column("course_id", sa.Integer(), nullable=False),
        sa.Column("semester_number", sa.Integer(), nullable=False),
        sa.Column("source_paper_code", sa.String(length=50), nullable=False),
        sa.Column("paper_type", sa.String(length=50), nullable=False),
        sa.Column("theory_credits", sa.Integer(), nullable=False),
        sa.Column("practical_credits", sa.Integer(), nullable=False),
        sa.Column("total_credits", sa.Integer(), nullable=False),
        sa.Column("has_practical", sa.Boolean(), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.Column("weekly_hours", sa.Integer(), nullable=True),
        sa.Column("max_marks", sa.Integer(), nullable=True),
        sa.Column("passing_marks", sa.Integer(), nullable=True),
        sa.Column("elective_group", sa.String(length=100), nullable=True),
        sa.ForeignKeyConstraint(["course_id"], ["courses.id"]),
        sa.ForeignKeyConstraint(
            ["curriculum_id"],
            ["curricula.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "curriculum_id",
            "semester_number",
            "source_paper_code",
            name="uq_curriculum_semester_paper",
        ),
    )
    op.create_index(
        op.f("ix_curriculum_courses_id"),
        "curriculum_courses",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curriculum_courses_curriculum_id"),
        "curriculum_courses",
        ["curriculum_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curriculum_courses_course_id"),
        "curriculum_courses",
        ["course_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_curriculum_courses_semester_number"),
        "curriculum_courses",
        ["semester_number"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_curriculum_courses_semester_number"),
        table_name="curriculum_courses",
    )
    op.drop_index(
        op.f("ix_curriculum_courses_course_id"),
        table_name="curriculum_courses",
    )
    op.drop_index(
        op.f("ix_curriculum_courses_curriculum_id"),
        table_name="curriculum_courses",
    )
    op.drop_index(op.f("ix_curriculum_courses_id"), table_name="curriculum_courses")
    op.drop_table("curriculum_courses")
    op.drop_index(op.f("ix_curricula_is_demo"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_status"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_academic_session_id"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_specialization_id"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_programme_id"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_catalog_key"), table_name="curricula")
    op.drop_index(op.f("ix_curricula_id"), table_name="curricula")
    op.drop_table("curricula")
