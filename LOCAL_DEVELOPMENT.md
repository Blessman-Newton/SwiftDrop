# Local development

The local setup uses a FastAPI server and a local PostgreSQL database. The web
clients are local-first and do not contact the hosted API unless
`VITE_API_URL` is explicitly supplied. The Flutter client uses
`API_BASE_URL` when supplied.

## 1. Install prerequisites

Install these on Windows:

- Python 3.11 or newer
- Node.js 18 or newer
- PostgreSQL 15 or newer
- Flutter, only if you are testing the mobile client

Ensure `python`, `pip`, `node`, `npm`, `psql`, and (if needed) `flutter` are on
your PATH. Do not copy production secrets into the local environment.

## 2. Create the local database

Open `psql` as a PostgreSQL administrator and run:

```sql
CREATE USER swiftdrop WITH PASSWORD 'swiftdrop';
CREATE DATABASE swiftdrop OWNER swiftdrop;
```

If either object already exists, keep it and verify that the password and
database ownership match the local `DATABASE_URL`.

## 3. Configure and migrate the API

From `swiftdrop-api`:

```powershell
Copy-Item .env.example .env
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python create_tables.py
alembic upgrade head
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

`create_tables.py` creates the base schema for a new local database.
`alembic upgrade head` then applies every versioned change, including the
session and FCM migrations. The API lifespan also checks the schema on startup,
but running Alembic explicitly makes migration failures visible before testing.
The rider settings migration also creates `rider_profiles.service_types`; run
this command after pulling rider changes before testing service toggles.

Push notifications use Firebase Cloud Messaging. The Flutter app now
initializes FCM in local mode when `android/app/google-services.json` and the
generated Firebase options are present, while API calls still target the local
backend. To deliver pushes from the local backend, set either
`FIREBASE_CREDENTIALS_PATH` or `FIREBASE_CREDENTIALS_JSON` in the backend
`.env` using a Firebase Admin service-account credential, then restart Uvicorn.
Without Admin credentials, notifications are still saved in the local
database, but no external push is sent.

Check `http://localhost:8000/health` and
`http://localhost:8000/docs`. Development OTP responses include `dev_code`, so
SMS is not required locally.

## 4. Run the web clients

In separate PowerShell windows:

```powershell
cd swiftdrop-admin
npm install
npm run dev
```

Open `http://localhost:3001`.

```powershell
cd swiftdrop-merchant
npm install
npm run dev
```

Open `http://localhost:3000`. Both clients proxy `/api` to
`http://localhost:8000`; do not set `VITE_API_URL` for the normal local run.

## 5. Run Flutter locally

For Flutter Windows or Flutter web:

```powershell
cd swiftdrop_flutter
flutter pub get
flutter run -d windows
```

For an Android emulator, `localhost` means the emulator itself. Use:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical phone, the simplest USB-connected option is to keep the Flutter
base URL as `http://localhost:8000` and forward the API port:

```powershell
adb reverse tcp:8000 tcp:8000
adb reverse --list
```

Re-run the `adb reverse` command after reconnecting or restarting the device.
Alternatively, replace `10.0.2.2` with the PC's LAN IP, run Uvicorn with
`--host 0.0.0.0`, and allow port 8000 through the Windows firewall.

## Local-only behavior

The example environment leaves Paystack, Twilio, Firebase, TomTom, and Redis
unset. Paystack initialization and verification return a clear disabled error
instead of attempting an online request. OTPs are returned in development
responses, and maps return `503 Maps service not configured` until a TomTom key
is intentionally added.

Do not add hosted API URLs, production database URLs, provider keys, or Firebase
credentials to `.env.example`, frontend source, or Flutter source. Production
values belong in the deployment environment only.

## Migration procedure for a changed schema

1. Stop the API if it is running.
2. Activate the API virtual environment.
3. Back up the local database if it contains test data.
4. Run `alembic upgrade head`.
5. Start the API and verify `/health`.
6. Run the focused API tests:

   ```powershell
   pytest -q
   ```

For a brand-new database, run `python create_tables.py` before Alembic as
shown above. For an existing database, do not drop tables or rerun
`create_tables.py` as a substitute for migrations. Before production, take a
database backup and run the same Alembic revision against a staging copy first;
production deployment details remain in [MIGRATIONS.md](swiftdrop-api/MIGRATIONS.md).
