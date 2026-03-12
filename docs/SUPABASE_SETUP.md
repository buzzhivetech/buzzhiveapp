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

4. After all migrations run successfully, restart the app (`flutter run`).

## Tables

- **profiles** - App profile (display name, avatar) per user. Auto-created on sign-up via trigger.
- **sensors** - One row per sensor, keyed by `firebase_sensor_id` (the Firebase node/push key).
- **user_sensor_links** - Which sensors each user has linked (many-to-many).

## Row Level Security

- **profiles**: Users can only read/update their own row.
- **sensors**: Any logged-in user can read, insert, and update (shared lookup table).
- **user_sensor_links**: Users can only see/modify their own links.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| PGRST205 (table not found) | Migrations not run | Run migration 1 |
| 42501 (RLS violation) on sensors | Restrictive policies | Run migration 3 |
| 42501 on user_sensor_links | Not logged in or wrong user | Check auth state in app |
