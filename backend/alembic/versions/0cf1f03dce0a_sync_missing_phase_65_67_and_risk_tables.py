"""sync missing Phase 65-67 and risk tables

Revision ID: 0cf1f03dce0a
Revises: 6aeaef35989d
Create Date: 2026-09-26 20:36:25.297280

"""
from typing import Sequence, Union

# revision identifiers, used by Alembic.
revision: str = '0cf1f03dce0a'
down_revision: Union[str, Sequence[str], None] = '6aeaef35989d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Preserve the historical revision without duplicating the initial schema."""
    # These tables were added to 6aeaef35989d before this revision was committed.
    # Retaining the revision as a no-op keeps already-deployed databases on a
    # coherent history and lets fresh databases reach head without collisions.


def downgrade() -> None:
    """Do not drop tables owned by the initial schema revision."""
