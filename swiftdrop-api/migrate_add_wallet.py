import sys
import os
import psycopg2

db_url = "postgresql://swiftdrop_db_rhbc_user:HwIiKbZVmdi39YrJbgnl02geqqfFOT3T@dpg-d94o4d57vvec73dstc5g-a.oregon-postgres.render.com:5432/swiftdrop_db_rhbc"

try:
    print("Connecting to database...")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    print("Altering users table to add wallet columns...")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(10, 2) DEFAULT 0.0;")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS membership_tier VARCHAR(20) DEFAULT 'Bronze';")
    
    conn.commit()
    print("Migration successful!")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error executing migration: {e}")
    sys.exit(1)
