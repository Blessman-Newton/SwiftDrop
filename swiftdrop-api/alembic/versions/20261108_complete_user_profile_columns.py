"""Complete user profile columns for existing local databases.

Revision ID: 20261108_user_profile_cols
Revises:
"""

from alembic import op


revision = "20261108_user_profile_cols"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE IF EXISTS users "
        "ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE"
    )
    op.execute(
        "ALTER TABLE IF EXISTS users "
        "ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(10, 2) DEFAULT 0.0"
    )
    op.execute(
        "ALTER TABLE IF EXISTS users "
        "ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0"
    )
    op.execute(
        "ALTER TABLE IF EXISTS users "
        "ADD COLUMN IF NOT EXISTS membership_tier VARCHAR(20) DEFAULT 'Bronze'"
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE users
            DROP COLUMN IF EXISTS onboarding_completed,
            DROP COLUMN IF EXISTS wallet_balance,
            DROP COLUMN IF EXISTS loyalty_points,
            DROP COLUMN IF EXISTS membership_tier
        """
    )
