"""link warnings and interventions

Revision ID: f0b3c4d5e6f7
Revises: e9a2b3c4d5e6
Create Date: 2026-10-01 10:35:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f0b3c4d5e6f7"
down_revision: Union[str, Sequence[str], None] = "e9a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("academic_interventions") as batch_op:
        batch_op.add_column(sa.Column("warning_id", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("notes", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("outcome", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True))
        batch_op.create_foreign_key(
            "fk_academic_interventions_warning_id",
            "early_warnings",
            ["warning_id"],
            ["id"],
        )
        batch_op.create_index(
            "ix_academic_interventions_warning_id",
            ["warning_id"],
        )
    op.execute(
        "UPDATE academic_interventions SET updated_at = CURRENT_TIMESTAMP "
        "WHERE updated_at IS NULL"
    )


def downgrade() -> None:
    with op.batch_alter_table("academic_interventions") as batch_op:
        batch_op.drop_index("ix_academic_interventions_warning_id")
        batch_op.drop_constraint(
            "fk_academic_interventions_warning_id",
            type_="foreignkey",
        )
        batch_op.drop_column("updated_at")
        batch_op.drop_column("outcome")
        batch_op.drop_column("notes")
        batch_op.drop_column("warning_id")
