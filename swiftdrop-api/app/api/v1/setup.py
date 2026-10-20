"""
One-time setup endpoint for database initialization
Access: POST /setup/initialize?secret=YOUR_SECRET_KEY
Access: POST /setup/reset?secret=YOUR_SECRET_KEY
Access: POST /setup/migrate?secret=YOUR_SECRET_KEY
"""
from fastapi import APIRouter, HTTPException, Query
import hmac
import subprocess
import sys

from sqlalchemy import text
from app.core.database import engine, Base
from app.config import get_settings
from app.models import (
    User, RiderProfile, OTPCode,
    Restaurant, MenuItem, PromoCode,
    Category, Order, OrderItem, DispatchLog,
    Payment, SupportTicket, Payout,
    Notification, Review, Address
    , DeliveryFailure, RefundRequest
)

async def run_migrations() -> list[str]:
    """Apply all pending column/table migrations safely (idempotent)."""
    migrations_done: list[str] = []

    async with engine.begin() as conn:
        # --- orders idempotency and order_items menu references ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'orders' AND column_name = 'idempotency_key'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE orders ADD COLUMN idempotency_key VARCHAR(100)
            """))
            migrations_done.append("order_idempotency_key")
        # Keep the oldest request when upgrading databases that predate the
        # unique constraint. The application will replay that order for retries.
        await conn.execute(text("""
            DELETE FROM orders newer
            USING orders older
            WHERE newer.customer_id = older.customer_id
              AND newer.idempotency_key IS NOT NULL
              AND newer.idempotency_key = older.idempotency_key
              AND newer.created_at > older.created_at
        """))
        await conn.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS uq_orders_customer_idempotency
            ON orders (customer_id, idempotency_key)
            WHERE idempotency_key IS NOT NULL
        """))

        await conn.execute(text("""
            DO $$
            BEGIN
                IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type_enum')
                   AND NOT EXISTS (
                       SELECT 1 FROM pg_enum
                       WHERE enumtypid = 'order_type_enum'::regtype
                         AND enumlabel = 'cosmetics'
                   ) THEN
                    ALTER TYPE order_type_enum ADD VALUE 'cosmetics';
                END IF;
            END $$;
        """))
        await conn.execute(text("""
            DO $$
            BEGIN
                IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status_enum')
                   AND NOT EXISTS (
                       SELECT 1 FROM pg_enum
                       WHERE enumtypid = 'order_status_enum'::regtype
                         AND enumlabel = 'DELIVERY_FAILED'
                   ) THEN
                    ALTER TYPE order_status_enum ADD VALUE 'DELIVERY_FAILED';
                END IF;
            END $$;
        """))

        await conn.execute(text("""
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM pg_type
                    WHERE typname = 'payment_transaction_status_enum'
                ) THEN
                    ALTER TYPE payment_transaction_status_enum
                    ADD VALUE IF NOT EXISTS 'superseded';
                    ALTER TYPE payment_transaction_status_enum
                    ADD VALUE IF NOT EXISTS 'ambiguous';
                END IF;
            END $$;
        """))

        # The catalog table must exist before adding the order-item foreign key.
        r = await conn.execute(text("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables WHERE table_name = 'cosmetics'
            )
        """))
        if not r.scalar():
            await conn.execute(text("""
                CREATE TABLE cosmetics (
                    id UUID PRIMARY KEY,
                    name VARCHAR(200) NOT NULL,
                    description TEXT,
                    price NUMERIC(10, 2) NOT NULL,
                    image_url TEXT,
                    is_available BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
                )
            """))
            migrations_done.append("created_cosmetics_table")

        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'order_items' AND column_name = 'menu_item_id'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE order_items ADD COLUMN menu_item_id UUID
            """))
            migrations_done.append("order_item_menu_item_id")
        await conn.execute(text("""
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'fk_order_items_menu_item_id'
                ) THEN
                    ALTER TABLE order_items
                    ADD CONSTRAINT fk_order_items_menu_item_id
                    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id);
                END IF;
            END $$;
        """))
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'order_items' AND column_name = 'cosmetic_product_id'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE order_items ADD COLUMN cosmetic_product_id UUID
            """))
            migrations_done.append("order_item_cosmetic_product_id")
        await conn.execute(text("""
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'fk_order_items_cosmetic_product_id'
                ) THEN
                    ALTER TABLE order_items
                    ADD CONSTRAINT fk_order_items_cosmetic_product_id
                    FOREIGN KEY (cosmetic_product_id) REFERENCES cosmetics(id);
                END IF;
            END $$;
        """))

        # --- users.password_hash ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'password_hash'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT ''
            """))
            migrations_done.append("password_hash")

        # --- users.onboarding_completed ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'onboarding_completed'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE users ADD COLUMN onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE
            """))
            migrations_done.append("onboarding_completed")

        # --- users.fcm_token ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'fcm_token'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE users ADD COLUMN fcm_token TEXT
            """))
            migrations_done.append("fcm_token")

        # --- rider_profiles.last_lat / last_lng ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'rider_profiles' AND column_name = 'last_lat'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE rider_profiles ADD COLUMN last_lat DOUBLE PRECISION
            """))
            await conn.execute(text("""
                ALTER TABLE rider_profiles ADD COLUMN last_lng DOUBLE PRECISION
            """))
            migrations_done.append("rider_location_columns")

        # --- orders.delivery_pin ---
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'orders' AND column_name = 'delivery_pin'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE orders ADD COLUMN delivery_pin VARCHAR(10)
            """))
            migrations_done.append("delivery_pin_column")

        for column, definition in (
            ("vendor_response_deadline", "TIMESTAMP WITH TIME ZONE"),
            ("vendor_responded_at", "TIMESTAMP WITH TIME ZONE"),
            ("dispatch_offer_deadline", "TIMESTAMP WITH TIME ZONE"),
            ("dispatch_attempts", "INTEGER NOT NULL DEFAULT 0"),
        ):
            r = await conn.execute(text("""
                SELECT column_name FROM information_schema.columns
                WHERE table_name = 'orders' AND column_name = :column
            """), {"column": column})
            if not r.fetchone():
                await conn.execute(text(
                    f"ALTER TABLE orders ADD COLUMN {column} {definition}"
                ))
                migrations_done.append(f"order_{column}")
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_orders_vendor_response_deadline "
            "ON orders (vendor_response_deadline)"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_orders_dispatch_offer_deadline "
            "ON orders (dispatch_offer_deadline)"
        ))
        await conn.run_sync(Base.metadata.create_all, tables=[
            DeliveryFailure.__table__, RefundRequest.__table__
        ])
        r = await conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'delivery_failures' AND column_name = 'resolved_by'
        """))
        if not r.fetchone():
            await conn.execute(text("""
                ALTER TABLE delivery_failures
                ADD COLUMN resolved_by UUID REFERENCES users(id)
            """))
            migrations_done.append("delivery_failure_resolved_by")
        migrations_done.append("delivery_failure_and_refund_tables_checked")

    return migrations_done

router = APIRouter(prefix="/setup", tags=["setup"])


def _validate_setup_secret(secret: str) -> None:
    configured_secret = get_settings().SETUP_SECRET
    if not configured_secret or not hmac.compare_digest(secret, configured_secret):
        raise HTTPException(status_code=403, detail="Invalid setup secret")


@router.post("/initialize")
async def initialize_database(secret: str = Query(..., description="Setup secret key")):
    """
    Initialize database with tables and seed data.
    This is a one-time setup endpoint - disable after use!
    """
    # Simple security check
    _validate_setup_secret(secret)
    
    try:
        # Run the initialization script
        result = subprocess.run(
            [sys.executable, "init_db.py"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd="/app"
        )
        
        if result.returncode == 0:
            return {
                "status": "success",
                "message": "Database initialized successfully",
                "output": result.stdout
            }
        else:
            raise HTTPException(
                status_code=500,
                detail={
                    "error": "Initialization failed",
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                }
            )
    
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Initialization timed out")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/migrate")
async def migrate_database(secret: str = Query(..., description="Setup secret key")):
    """
    Add missing columns to existing tables and promote admin user
    """
    _validate_setup_secret(secret)

    try:
        migrations_done = await run_migrations()

        # Also handle admin promotion (not in the shared helper to keep it focused)
        async with engine.begin() as conn:
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE email = :email"),
                {"email": "admin@swiftdrop.com"}
            )
            admin_user = result.fetchone()

            if admin_user:
                admin_id = str(admin_user[0])
                admin_email = admin_user[1]
                admin_role = admin_user[2]
                if admin_role != 'admin':
                    await conn.execute(
                        text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                        {"user_id": admin_id}
                    )
                    migrations_done.append(f"promoted {admin_email} from '{admin_role}' to 'admin'")
                else:
                    migrations_done.append(f"admin user already exists: {admin_email}")
            else:
                result = await conn.execute(
                    text("SELECT id, email, role FROM users WHERE email LIKE '%admin%' OR name LIKE '%admin%' LIMIT 1")
                )
                potential_admin = result.fetchone()
                if potential_admin:
                    await conn.execute(
                        text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                        {"user_id": str(potential_admin[0])}
                    )
                    migrations_done.append(f"promoted {potential_admin[1]} to admin")

        if migrations_done:
            return {
                "status": "success",
                "message": f"Migration completed: {', '.join(migrations_done)}",
                "changes": migrations_done,
            }
        return {"status": "success", "message": "No migration needed: all columns already exist"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Migration error: {str(e)}")


@router.post("/reset")
async def reset_database(secret: str = Query(..., description="Setup secret key")):
    """
    Drop all tables and recreate with seed data.
    WARNING: This will delete all data!
    """
    _validate_setup_secret(secret)
    
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        
        result = subprocess.run(
            [sys.executable, "init_db.py"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd="/app"
        )
        
        if result.returncode == 0:
            return {
                "status": "success",
                "message": "Database reset and initialized successfully",
                "output": result.stdout
            }
        else:
            raise HTTPException(
                status_code=500,
                detail={
                    "error": "Reset failed",
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                }
            )
    
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Reset timed out")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/promote-admin")
async def promote_to_admin(
    secret: str = Query(..., description="Setup secret key"),
    user_id: str = Query(..., description="User ID to promote to admin")
):
    """
    Promote a user to admin role.
    One-time setup endpoint - use with caution!
    """
    _validate_setup_secret(secret)
    
    try:
        async with engine.begin() as conn:
            # Check if user exists
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE id = :user_id"),
                {"user_id": user_id}
            )
            user = result.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail=f"User not found: {user_id}")
            
            old_role = user[2]
            
            # Update role to admin
            await conn.execute(
                text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                {"user_id": user_id}
            )
            
            return {
                "status": "success",
                "message": f"User {user[1]} promoted from '{old_role}' to 'admin'",
                "user_id": user_id,
                "email": user[1],
                "old_role": old_role,
                "new_role": "admin"
            }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/force-promote")
async def force_promote(
    secret: str = Query(..., description="Setup secret key"),
    user_id: str = Query(..., description="User ID to promote")
):
    """Force promote user to admin - debug endpoint"""
    _validate_setup_secret(secret)
    
    try:
        async with engine.begin() as conn:
            # Direct update without conditions
            await conn.execute(
                text("UPDATE users SET role = 'admin' WHERE id = :user_id"),
                {"user_id": user_id}
            )
            
            # Verify the update
            result = await conn.execute(
                text("SELECT id, email, role FROM users WHERE id = :user_id"),
                {"user_id": user_id}
            )
            user = result.fetchone()
            
            if user:
                return {
                    "status": "success",
                    "message": f"User promoted to admin",
                    "user_id": str(user[0]),
                    "email": user[1],
                    "role": user[2]
                }
            else:
                return {"status": "error", "message": "User not found after update"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "app": "Doorush API"}
