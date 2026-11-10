"""Persist rider service preferences.

Revision ID: 20261109_add_rider_service_types
Revises:
"""

from alembic import op


revision = "20261109_rider_service_types"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS rider_profiles
            ADD COLUMN IF NOT EXISTS service_types JSONB NOT NULL DEFAULT '[]'::jsonb
        """
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS rider_profiles
            DROP COLUMN IF EXISTS service_types
        """
    )
