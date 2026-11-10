"""Add delivery PIN storage to orders.

Revision ID: 20261109_add_order_delivery_pin
Revises:
"""

from alembic import op


revision = "20261109_order_delivery_pin"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS orders
            ADD COLUMN IF NOT EXISTS delivery_pin VARCHAR(10)
        """
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE IF EXISTS orders
            DROP COLUMN IF EXISTS delivery_pin
        """
    )
