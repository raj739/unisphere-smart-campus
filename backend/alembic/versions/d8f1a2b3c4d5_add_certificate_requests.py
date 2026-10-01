"""add certificate request workflow

Revision ID: d8f1a2b3c4d5
Revises: c41d90a7e201
Create Date: 2026-09-30 20:30:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d8f1a2b3c4d5"
down_revision: Union[str, Sequence[str], None] = "c41d90a7e201"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "certificate_requests",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("request_number", sa.String(length=120), nullable=False),
        sa.Column("student_id", sa.Integer(), nullable=False),
        sa.Column("certificate_type", sa.String(length=100), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=False),
        sa.Column("delivery_mode", sa.String(length=30), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reviewed_by_user_id", sa.Integer(), nullable=True),
        sa.Column("review_remarks", sa.Text(), nullable=True),
        sa.Column("rejection_reason", sa.Text(), nullable=True),
        sa.Column("certificate_id", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["certificate_id"], ["certificates.id"]),
        sa.ForeignKeyConstraint(["reviewed_by_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("certificate_id"),
        sa.UniqueConstraint("request_number"),
    )
    op.create_index(op.f("ix_certificate_requests_id"), "certificate_requests", ["id"])
    op.create_index(
        op.f("ix_certificate_requests_request_number"),
        "certificate_requests",
        ["request_number"],
        unique=True,
    )
    op.create_index(
        op.f("ix_certificate_requests_student_id"),
        "certificate_requests",
        ["student_id"],
    )
    op.create_index(
        op.f("ix_certificate_requests_certificate_type"),
        "certificate_requests",
        ["certificate_type"],
    )
    op.create_index(
        op.f("ix_certificate_requests_status"),
        "certificate_requests",
        ["status"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_certificate_requests_status"), table_name="certificate_requests")
    op.drop_index(op.f("ix_certificate_requests_certificate_type"), table_name="certificate_requests")
    op.drop_index(op.f("ix_certificate_requests_student_id"), table_name="certificate_requests")
    op.drop_index(op.f("ix_certificate_requests_request_number"), table_name="certificate_requests")
    op.drop_index(op.f("ix_certificate_requests_id"), table_name="certificate_requests")
    op.drop_table("certificate_requests")
