"""Add the optional FCM token to users.

Revision ID: 20261020_add_user_fcm_token
Revises:
"""

from alembic import op


revision = "20261020_add_user_fcm_token"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Keep fresh-database bootstrap compatible with the existing application
    # while upgrading an already-created users table safely.
    op.execute(
        """
        DO $$
        BEGIN
            IF to_regclass('public.users') IS NOT NULL THEN
                ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
            END IF;
        END $$;
        """
    )


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS fcm_token")
