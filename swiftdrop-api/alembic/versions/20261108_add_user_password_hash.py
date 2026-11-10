"""Add the password hash to users.

Revision ID: 20261108_add_user_password_hash
Revises:
"""

from alembic import op


revision = "20261108_add_user_password_hash"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF to_regclass('public.users') IS NOT NULL THEN
                ALTER TABLE users
                ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT '';
            END IF;
        END $$;
        """
    )


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS password_hash")
