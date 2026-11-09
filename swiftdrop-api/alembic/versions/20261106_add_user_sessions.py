"""Add DB-backed user sessions and remove legacy plaintext order delivery PIN exposure."""

from alembic import op

revision = "20261106_add_user_sessions"
down_revision = "20261020_add_user_fcm_token"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS user_sessions (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token_hash VARCHAR(64) NOT NULL UNIQUE,
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            revoked_at TIMESTAMP WITH TIME ZONE,
            last_seen_at TIMESTAMP WITH TIME ZONE,
            ip_address VARCHAR(64),
            user_agent TEXT,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_user_sessions_user_id ON user_sessions(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_user_sessions_expires_at ON user_sessions(expires_at)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS user_sessions")
