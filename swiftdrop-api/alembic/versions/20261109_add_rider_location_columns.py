"""Add rider location columns required by the RiderProfile model.

Revision ID: 20261109_add_rider_location_columns
Revises:
"""

from alembic import op


revision = "20261109_rider_location_cols"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS rider_profiles
            ADD COLUMN IF NOT EXISTS last_lat DOUBLE PRECISION,
            ADD COLUMN IF NOT EXISTS last_lng DOUBLE PRECISION
        """
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS rider_profiles
            DROP COLUMN IF EXISTS last_lat,
            DROP COLUMN IF EXISTS last_lng
        """
    )
