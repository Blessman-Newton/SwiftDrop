# SwiftDrop Backend (Render) - Required Environment Variables

## Critical (set in Render Dashboard → swiftdrop-api → Environment)
| Name | Purpose | Where to get value |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Render Postgres dashboard (Internal Database URL recommended) |
| `JWT_SECRET` | Signs auth/session tokens (ROTATE exposed secret) | Generate: `python -c "import secrets; print(secrets.token_urlsafe(64))"` |
| `CORS_ORIGINS` | Allowed web origins (comma-separated) | Your deployed admin/merchant URLs, e.g. `https://admin.example.com,https://merchant.example.com` |
| `APP_BASE_URL` | Public API base URL | Render service URL, e.g. `https://swiftdrop-api.onrender.com` |
| `ENVIRONMENT` | Enables production hardening | `production` |
| `PAYSTACK_SECRET_KEY` | Paystack server secret (ROTATE if exposed) | Paystack Dashboard → Settings → API Keys & Webhooks |
| `PAYSTACK_PUBLIC_KEY` | Paystack public key | Paystack Dashboard → Settings → API Keys & Webhooks |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Admin credentials (ROTATE if exposed) | Firebase Console → Project Settings → Service accounts → Generate new private key (paste JSON as single line) |
| `TOMTOM_API_KEY` | Server-side maps proxy key (ROTATE exposed key) | TomTom Developer Portal → API Keys (restrict by domain/IP where possible) |

## Recommended / optional
| Name | Purpose | Where to get value |
|---|---|---|
| `SESSION_COOKIE_NAME` | Cookie name for web auth | `swiftdrop_session` (default) |
| `SESSION_COOKIE_SAMESITE` | Cookie SameSite policy | `lax` (default); use `none` only if cross-site and HTTPS |
| `SESSION_COOKIE_SECURE` | Secure cookies (HTTPS) | `true` in production |
| `COOKIE_DOMAIN` | Shared cookie domain (if needed) | Your root domain, e.g. `.example.com`; leave empty otherwise |
| `ALLOW_PUBLIC_MERCHANT_SIGNUP` | Allow merchant self-signup | `false` by default; set `true` only if intended |
| `ALLOW_PUBLIC_SETUP_ENDPOINTS` | Enable `/setup/*` endpoints | Keep `false` in production |
| `SETUP_SECRET` | Required if setup endpoints enabled | Generate strong random secret |
| `TWILIO_ACCOUNT_SID` | SMS/OTP provider | Twilio Console (ROTATE if exposed) |
| `TWILIO_AUTH_TOKEN` | SMS/OTP provider auth (ROTATE if exposed) | Twilio Console |
| `TWILIO_VERIFY_SERVICE_SID` | Twilio Verify service | Twilio Console → Verify |
| `GOOGLE_MAPS_API_KEY` | Legacy/server maps (if still used) | Google Cloud Console (rotate/restrict; prefer TomTom proxy) |

## Render actions (step-by-step)
1. Open **Render Dashboard** → your Postgres → copy **Internal Database URL** → set `DATABASE_URL` on `swiftdrop-api` (if not already linked).
2. Open **swiftdrop-api** → **Environment** → add/update variables above. For secrets, use Render’s secret values (not committed files).
3. **Rotate exposed secrets** before/with deploy: generate new `JWT_SECRET`; rotate Paystack keys; generate new Firebase service account key; revoke/rotate exposed Twilio creds; rotate TomTom key. Update Render env vars with new values.
4. Deploy: push changes. `render.yaml` start command runs `alembic upgrade head` automatically; confirm deploy logs show migration success for `20261106_add_user_sessions`.
5. Set `CORS_ORIGINS` to your real admin/merchant web origins (no `*`). After deploy, verify login sets HttpOnly cookie and `/api/v1/auth/me` works with `credentials: include` from web.
6. Keep `ALLOW_PUBLIC_SETUP_ENDPOINTS=false` in production. Use admin-provisioning flows instead of public setup.

## Local/dev
- Copy `swiftdrop-api/.env.example` to `.env` (not committed) and fill values. Use `ENVIRONMENT=development` locally.
