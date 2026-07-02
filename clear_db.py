import psycopg2
conn = psycopg2.connect(host='localhost', dbname='swiftdrop', user='swiftdrop', password='admin@123')
cur = conn.cursor()
cur.execute("SELECT tablename FROM pg_tables WHERE schemaname='public'")
tables = [r[0] for r in cur.fetchall()]
for t in tables:
    cur.execute(f'TRUNCATE TABLE "{t}" CASCADE')
conn.commit()
cur.close()
conn.close()
print('Cleared:', ', '.join(tables))
