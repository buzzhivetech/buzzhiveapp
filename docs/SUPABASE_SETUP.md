# Supabase Setup

The app expects these tables in your Supabase project. If you see:

**`could not find the table 'public.user_sensor_links' in the schema cache (PGRST205)`**

then the schema has not been applied yet.

## Apply the Schema

1. Open [Supabase Dashboard](https://supabase.com/dashboard) -> your project.
2. Go to **SQL Editor** -> **New query**.
3. Run each migration file **in order**:

| Order | File | Purpose |
|---|---|---|
| 1 | `supabase/migrations/20250101000000_initial_schema.sql` | Creates `profiles`, `sensors`, `user_sensor_links` tables with RLS and indexes |
| 2 | `supabase/migrations/20250102000000_sensors_rls_fix.sql` | Adds `created_by` column and fixes INSERT/SELECT/UPDATE policies on `sensors` |
| 3 | `supabase/migrations/20250103000000_simplify_sensors_rls.sql` | Simplifies `sensors` RLS to allow any logged-in user to read/insert/update |
| 4 | `supabase/migrations/20250104000000_delete_user_function.sql` | Adds `delete_user_account()` RPC used by the settings screen |
| 5 | `supabase/migrations/20250105000000_customer_onboarding.sql` | Adds `sensor_status` enum, claim-code columns, `claim_attempts`, `claim_result` type, and locks down `sensors` RLS to read-only |
| 6 | `supabase/migrations/20250105000001_claim_sensor_rpc.sql` | Creates the `claim_sensor(p_device_id, p_claim_code)` RPC (SECURITY DEFINER with `SELECT FOR UPDATE` + bcrypt verify + rate-limit) |
| 7 | `supabase/migrations/20250106000000_seed_existing_sensors.sql` | Seeds claim codes for existing sensors (5, 8, 10001-10005) and prints them via `RAISE NOTICE` |

4. After all migrations run successfully, restart the app (`flutter run`).

> **Record the seed claim codes.** Migration 7 prints each code via `RAISE NOTICE`.
> In the Supabase SQL Editor they appear in the "Results" pane next to the query. Copy
> them to a password manager before closing the tab — they are stored as bcrypt
> hashes and cannot be recovered.

## Tables

- **profiles** - App profile (display name, avatar) per user. Auto-created on sign-up via trigger.
- **sensors** - One row per sensor, keyed by `firebase_sensor_id`. `status` is `factory` until a user claims it.
- **user_sensor_links** - Which sensors each user has linked (many-to-many).
- **claim_attempts** - Append-only log used by `claim_sensor` to rate-limit brute-force attempts.

## Row Level Security

- **profiles**: Users can only read/update their own row.
- **sensors**: Users can **read** sensors they have linked. No client-side `INSERT/UPDATE/DELETE` — all mutations go through the `claim_sensor` RPC.
- **user_sensor_links**: Users can only see/modify their own links.
- **claim_attempts**: No RLS policies (default-deny). The RPC bypasses RLS as `SECURITY DEFINER`.

## Running the RPC test

```bash
psql "$SUPABASE_DB_URL" -f supabase/tests/claim_sensor_test.sql
```

The test is wrapped in a transaction that rolls back, so it can be run against any environment.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| PGRST205 (table not found) | Migrations not run | Run migration 1 |
| 42501 (RLS violation) on sensors | Restrictive policies | Run migration 3; after migration 5 this is expected for writes - use `claim_sensor` |
| 42501 on user_sensor_links | Not logged in or wrong user | Check auth state in app |
| `error_code=unknown_device` from claim_sensor | `firebase_sensor_id` not in `public.sensors` | Run migration 7 or manually insert a factory row |
| `error_code=rate_limited` | >10 failed claim attempts in 10 min | Wait 10 minutes, or delete rows from `public.claim_attempts` in dev |
