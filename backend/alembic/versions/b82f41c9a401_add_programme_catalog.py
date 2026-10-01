"""add programme categories and specializations

Revision ID: b82f41c9a401
Revises: 0cf1f03dce0a
Create Date: 2026-09-30 14:20:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b82f41c9a401"
down_revision: Union[str, Sequence[str], None] = "0cf1f03dce0a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "programmes",
        sa.Column("category", sa.String(length=100), nullable=True),
    )
    op.create_index(
        op.f("ix_programmes_category"),
        "programmes",
        ["category"],
        unique=False,
    )
    op.create_table(
        "programme_specializations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("programme_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("code", sa.String(length=50), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(
            ["programme_id"],
            ["programmes.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "programme_id",
            "name",
            name="uq_programme_specialization_name",
        ),
    )
    op.create_index(
        op.f("ix_programme_specializations_id"),
        "programme_specializations",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_programme_specializations_programme_id"),
        "programme_specializations",
        ["programme_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_programme_specializations_programme_id"),
        table_name="programme_specializations",
    )
    op.drop_index(
        op.f("ix_programme_specializations_id"),
        table_name="programme_specializations",
    )
    op.drop_table("programme_specializations")
    op.drop_index(op.f("ix_programmes_category"), table_name="programmes")
    op.drop_column("programmes", "category")
