import importlib
import importlib.util
from pathlib import Path

from app.models.user import User


def test_user_model_keeps_fcm_token_nullable():
    column = User.__table__.c.fcm_token

    assert column.nullable is True


def test_fcm_migration_is_idempotent(monkeypatch):
    migration_path = (
        Path(__file__).parents[1]
        / "alembic"
        / "versions"
        / "20261020_add_user_fcm_token.py"
    )
    spec = importlib.util.spec_from_file_location("fcm_migration", migration_path)
    assert spec and spec.loader
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    statements: list[str] = []

    monkeypatch.setattr(migration.op, "execute", statements.append)

    migration.upgrade()
    migration.downgrade()

    assert "ADD COLUMN IF NOT EXISTS fcm_token TEXT" in statements[0]
    assert "DROP COLUMN IF EXISTS fcm_token" in statements[1]
