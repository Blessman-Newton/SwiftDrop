# SwiftDrop Backend - FastAPI + Paystack + Flutter Integration

## Overview

Production-ready backend for a multi-role delivery platform (food + parcel) targeting Ghana. FastAPI + PostgreSQL + Redis on Render, Paystack for payments, Africa's Talking for SMS OTP. Flutter app updated to connect to real backend.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | FastAPI (Python 3.11+) |
| Database | PostgreSQL 15 (Render Managed) |
| ORM | SQLAlchemy 2.0 (async) |
| Migrations | Alembic |
| Cache/PubSub | Redis (Render) |
| Auth | JWT + Phone OTP |
| Payments | Paystack (GHS) |
| SMS | Africas Talking |
| Hosting | Render (Web Service + PostgreSQL + Redis) |
| Currency | GHS (Ghana Cedis) |

## Database Schema

### Users (customers + riders)

`sql
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(15) UNIQUE NOT NULL,
  name          VARCHAR(100),
  email         VARCHAR(255),
  role          VARCHAR(10) NOT NULL CHECK (role IN ('customer', 'rider', 'admin')),
  avatar_url    TEXT,
  is_active     BOOLEAN DEFAULT true,
  is_verified   BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);
`

### Rider Profile

`sql
CREATE TABLE rider_profiles (
  user_id       UUID PRIMARY KEY REFERENCES users(id),
  is_online     BOOLEAN DEFAULT false,
  current_order_id UUID,
  rating        DECIMAL(3,2) DEFAULT 5.00,
  total_deliveries INT DEFAULT 0,
  earnings_balance DECIMAL(10,2) DEFAULT 0,
  vehicle_type  VARCHAR(20),
  license_number VARCHAR(50),
  is_banned     BOOLEAN DEFAULT false,
  dispatch_priority DECIMAL(3,2) DEFAULT 1.0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
`

### Orders

`sql
CREATE TABLE orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID NOT NULL REFERENCES users(id),
  rider_id        UUID REFERENCES users(id),
  order_type      VARCHAR(10) NOT NULL CHECK (order_type IN ('food', 'parcel')),
  status          VARCHAR(20) NOT NULL DEFAULT 'CREATED',
  restaurant_name VARCHAR(200),
  pickup_address  TEXT NOT NULL,
  pickup_lat      DOUBLE PRECISION,
  pickup_lng      DOUBLE PRECISION,
  delivery_address TEXT NOT NULL,
  delivery_lat    DOUBLE PRECISION,
  delivery_lng    DOUBLE PRECISION,
  subtotal        DECIMAL(10,2) NOT NULL,
  delivery_fee    DECIMAL(10,2) NOT NULL,
  tax             DECIMAL(10,2) NOT NULL,
  discount        DECIMAL(10,2) DEFAULT 0,
  total           DECIMAL(10,2) NOT NULL,
  promo_code      VARCHAR(20),
  payment_ref     VARCHAR(100),
  payment_status  VARCHAR(20) DEFAULT 'pending',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at    TIMESTAMPTZ,
  preparing_at    TIMESTAMPTZ,
  picked_up_at    TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  cancelled_at    TIMESTAMPTZ,
  status_history  JSONB DEFAULT '[]',
  metadata        JSONB DEFAULT '{}'
);
`

### Order Items

`sql
CREATE TABLE order_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  name        VARCHAR(200) NOT NULL,
  quantity    INT NOT NULL DEFAULT 1,
  price       DECIMAL(10,2) NOT NULL,
  notes       TEXT
);
`

### Dispatch Log

`sql
CREATE TABLE dispatch_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id),
  rider_id    UUID NOT NULL REFERENCES users(id),
  action      VARCHAR(20) NOT NULL,
  reason      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
`

### OTP Codes

`sql
CREATE TABLE otp_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       VARCHAR(15) NOT NULL,
  code        VARCHAR(6) NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  used        BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
`

## Order State Machine

`
CREATED -> CONFIRMED -> PREPARING -> READY_FOR_PICKUP -> PICKED_UP -> EN_ROUTE -> DELIVERED
    +--- CANCELLED (before PICKED_UP only)
`

Valid transitions:

| From | To | Actor |
|---|---|---|
| CREATED | CONFIRMED | system (payment success) |
| CONFIRMED | PREPARING | restaurant |
| PREPARING | READY_FOR_PICKUP | restaurant |
| READY_FOR_PICKUP | PICKED_UP | rider |
| PICKED_UP | EN_ROUTE | rider |
| EN_ROUTE | DELIVERED | rider |
| CREATED | CANCELLED | customer |
| CONFIRMED | CANCELLED | customer |
| PREPARING | CANCELLED | system |

## API Endpoints

### Auth

`
POST   /api/v1/auth/send-otp        Send OTP to phone
POST   /api/v1/auth/verify-otp      Verify OTP, return JWT
GET    /api/v1/auth/me               Get current user
`

### Orders

`
POST   /api/v1/orders               Create order
GET    /api/v1/orders               List my orders
GET    /api/v1/orders/{id}          Order detail
PATCH  /api/v1/orders/{id}/cancel   Cancel order
`

### Payments

`
POST   /api/v1/payments/initialize   Initialize Paystack transaction
POST   /api/v1/payments/webhook      Paystack webhook
GET    /api/v1/payments/{ref}/verify Verify payment
`

### Riders

`
POST   /api/v1/riders/online         Go online
POST   /api/v1/riders/offline        Go offline
GET    /api/v1/riders/available-orders List dispatchable orders
`

### Dispatch

`
POST   /api/v1/dispatch/{id}/accept  Rider accepts
POST   /api/v1/dispatch/{id}/reject  Rider rejects
`

## Payment Flow

`
1. Customer places order -> POST /orders -> status = CREATED
2. Flutter calls POST /payments/initialize
   -> Backend calls Paystack Initialize Transaction API
   -> Returns authorization_url
3. Customer pays on Paystack (card/bank/MOMO)
4. Paystack webhook -> POST /payments/webhook
   -> Backend verifies signature
   -> Updates order: payment_status=paid, status->CONFIRMED
5. Dispatch system assigns rider
`

## Project Structure

`
swiftdrop-api/
  app/
    __init__.py
    main.py
    config.py
    core/
      __init__.py
      database.py
      security.py
      exceptions.py
    models/
      __init__.py
      user.py
      order.py
    schemas/
      __init__.py
      auth.py
      order.py
      payment.py
      rider.py
    services/
      __init__.py
      auth_service.py
      sms_service.py
      order_service.py
      payment_service.py
      dispatch_service.py
    payments/
      __init__.py
      base.py
      paystack.py
    api/
      __init__.py
      deps.py
      v1/
        __init__.py
        router.py
        auth.py
        orders.py
        payments.py
        riders.py
        dispatch.py
  alembic/
    env.py
    versions/
  tests/
  alembic.ini
  requirements.txt
  Dockerfile
  render.yaml
  .env.example
`

## Render Deployment

`yaml
services:
  - type: web
    name: swiftdrop-api
    runtime: python
    buildCommand: pip install -r requirements.txt && alembic upgrade head
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port 
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: swiftdrop-db
          property: connectionString
      - key: REDIS_URL
        fromRedis:
          name: swiftdrop-redis
          property: connectionString
      - key: PAYSTACK_SECRET_KEY
        sync: false
      - key: PAYSTACK_PUBLIC_KEY
        sync: false
      - key: JWT_SECRET
        generateValue: true
      - key: AFRICASTALKING_API_KEY
        sync: false
      - key: AFRICASTALKING_USERNAME
        value: swiftdrop
  - type: postgres
    name: swiftdrop-db
    plan: starter
  - type: redis
    name: swiftdrop-redis
    plan: starter
`

## Flutter Changes

| File | Change |
|---|---|
| pubspec.yaml | Add dio, web_socket_channel |
| lib/services/api_client.dart | NEW: Dio HTTP client with JWT |
| lib/services/api_endpoints.dart | NEW: endpoint constants |
| lib/services/auth_service.dart | Rewrite: API-based auth |
| lib/providers/auth_provider.dart | Update: JWT token management |
| lib/screens/auth_screen.dart | Update: phone-first OTP flow |
| lib/screens/rider/rider_login_screen.dart | Update: API auth |
| lib/providers/providers.dart | Update: orders from API |
| lib/screens/restaurant_detail_screen.dart | Update: POST /orders + payment |
| lib/screens/parcel_summary_screen.dart | Update: POST /orders + payment |
| lib/screens/orders_screen.dart | Update: fetch from API |
| lib/screens/rider/rider_dashboard_screen.dart | Update: fetch from API |
| lib/screens/rider/rider_active_delivery_screen.dart | Update: API calls |
| lib/screens/profile_screen.dart | Update: wallet from API |

## Implementation Order

| Step | Module | Time |
|---|---|---|
| 1 | Project setup + config | 30 min |
| 2 | Auth (OTP + JWT + Africas Talking) | 1.5 hrs |
| 3 | Orders (state machine + CRUD) | 1.5 hrs |
| 4 | Paystack payments | 1.5 hrs |
| 5 | Dispatch (basic rider matching) | 1 hr |
| 6 | Rider endpoints | 30 min |
| 7 | Database migrations | 30 min |
| 8 | Render deployment | 30 min |
| 9 | Flutter HTTP client + API layer | 1 hr |
| 10 | Flutter auth integration | 1 hr |
| 11 | Flutter orders integration | 1 hr |
| 12 | Flutter payment integration | 1 hr |
| 13 | Flutter rider integration | 1 hr |
| **Total** | | **~13 hrs** |

## Environment Variables

`env
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@host/swiftdrop

# Redis
REDIS_URL=redis://default:pass@host:6379

# JWT
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRY_MINUTES=1440

# Paystack
PAYSTACK_SECRET_KEY=sk_test_xxx
PAYSTACK_PUBLIC_KEY=pk_test_xxx

# Africas Talking
AFRICASTALKING_API_KEY=xxx
AFRICASTALKING_USERNAME=swiftdrop
AFRICASTALKING_SENDER_ID=Swiftdrop

# App
APP_NAME=SwiftDrop
APP_ENV=development
APP_BASE_URL=http://localhost:8000
`