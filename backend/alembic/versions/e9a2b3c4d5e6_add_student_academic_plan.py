"""add student academic plan links

Revision ID: e9a2b3c4d5e6
Revises: d8f1a2b3c4d5
Create Date: 2026-09-30 23:50:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e9a2b3c4d5e6"
down_revision: Union[str, Sequence[str], None] = "d8f1a2b3c4d5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("students") as batch_op:
        batch_op.add_column(sa.Column("programme_id", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("specialization_id", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("curriculum_id", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("academic_session_id", sa.Integer(), nullable=True))
        batch_op.create_foreign_key("fk_students_programme_id", "programmes", ["programme_id"], ["id"])
        batch_op.create_foreign_key("fk_students_specialization_id", "programme_specializations", ["specialization_id"], ["id"])
        batch_op.create_foreign_key("fk_students_curriculum_id", "curricula", ["curriculum_id"], ["id"])
        batch_op.create_foreign_key("fk_students_academic_session_id", "academic_sessions", ["academic_session_id"], ["id"])
        batch_op.create_index("ix_students_programme_id", ["programme_id"])
        batch_op.create_index("ix_students_specialization_id", ["specialization_id"])
        batch_op.create_index("ix_students_curriculum_id", ["curriculum_id"])
        batch_op.create_index("ix_students_academic_session_id", ["academic_session_id"])


def downgrade() -> None:
    with op.batch_alter_table("students") as batch_op:
        batch_op.drop_index("ix_students_academic_session_id")
        batch_op.drop_index("ix_students_curriculum_id")
        batch_op.drop_index("ix_students_specialization_id")
        batch_op.drop_index("ix_students_programme_id")
        batch_op.drop_constraint("fk_students_academic_session_id", type_="foreignkey")
        batch_op.drop_constraint("fk_students_curriculum_id", type_="foreignkey")
        batch_op.drop_constraint("fk_students_specialization_id", type_="foreignkey")
        batch_op.drop_constraint("fk_students_programme_id", type_="foreignkey")
        batch_op.drop_column("academic_session_id")
        batch_op.drop_column("curriculum_id")
        batch_op.drop_column("specialization_id")
        batch_op.drop_column("programme_id")
