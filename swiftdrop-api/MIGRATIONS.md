# Database migration procedure

The custom migration is additive and idempotent for columns, enum values,
tables, indexes, and foreign keys. It must run after the base application
tables have been created. It is not a replacement for the initial database
schema setup.

Before production:

1. Back up PostgreSQL, especially before the idempotency-index cleanup. If
   duplicate non-null customer/idempotency rows exist, the migration keeps
   the oldest order and deletes newer duplicates so the unique partial index
   can be created.
2. Configure the API's production database URL and a random
   `SETUP_SECRET` value. The setup secret is not compiled into the API and
   must be supplied through the deployment secret store or environment.
3. Apply the migration through an authenticated deployment/admin channel:

   ```powershell
   $baseUrl = "https://api.example.com/api/v1"
   $secret = "<SETUP_SECRET>"
   Invoke-RestMethod -Method Post -Uri "$baseUrl/setup/migrate?secret=$secret"
   ```

   The equivalent curl command is:

   ```text
   curl -X POST "https://api.example.com/api/v1/setup/migrate?secret=<configured-migration-secret>"
   ```

4. Verify the response lists the completed changes, then inspect the
   PostgreSQL schema for the cosmetics table, `order_items.cosmetic_product_id`,
   its foreign key, the order idempotency column, its partial unique index,
   payment-attempt enum values (`superseded` and `ambiguous`), the additive
   `orders.DELIVERY_FAILED` enum value, and the workflow columns
   `vendor_response_deadline`, `vendor_responded_at`,
   `dispatch_offer_deadline`, and `dispatch_attempts`.
5. Confirm the `delivery_failures` and `refund_requests` tables have been
   created with their order uniqueness constraints, and that
   `delivery_failures.resolved_by` exists. Existing orders remain
   valid; the new tables start empty and are populated only by the guarded
   workflow APIs.
6. Disable or restrict the setup route after the migration. Do not expose the
   migration secret in source control, logs, or client applications.

Run the migration once per target environment. Existing food and parcel rows
remain compatible; new cosmetics rows require a valid catalog product ID, and
gas orders continue to use the legacy parcel marker and metadata contract.
The migration creates an empty cosmetics catalog; it does not seed products or
prices. Populate that catalog through the authenticated admin/catalog workflow
before enabling cosmetics checkout.

## Operational workflow processing

Vendor response deadlines are persisted when food orders are created. An
authenticated administrator must run the following operation periodically
(for example, from a protected scheduler) to cancel overdue, unacknowledged
orders:

```text
POST /api/v1/admin/operations/expire-vendor-orders
```

The operation is idempotent and records the timeout reason in order status
history. Rider offer deadlines and reassignment are persisted by dispatch
operations. Run the following protected operation from a scheduler at least
once per minute to expire offers and safely requeue them for another rider:

```text
POST /api/v1/dispatch/operations/expire-offers?limit=50
```

The endpoint uses row locks with `skip_locked`, is safe to retry, and records
an `EXPIRED` dispatch log. A scheduler or equivalent worker is still required;
deploying the endpoint alone does not provide automatic timeout processing.

Refund transitions are intentionally guarded:
`requested -> under_review -> approved -> processing -> completed|failed`.
Rejection is allowed before processing, and only a provider-confirmed action
can move a refund to `completed`. Delivery failures are resolved by an admin
through `PATCH /api/v1/admin/delivery-failures/{failure_id}` with a required
`final_outcome` when setting `status=resolved`.
