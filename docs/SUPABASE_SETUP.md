# Supabase setup

The app expects these tables in your Supabase project. If you see:

**`could not find the table 'public.user_sensor_links' in the schema cache (PGRST205)`**

then the schema has not been applied yet.

## Apply the schema

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project.
2. Go to **SQL Editor** → **New query**.
3. Paste the contents of **`supabase/migrations/20250101000000_initial_schema.sql`**.
4. Click **Run**.

This creates:

- **profiles** – app profile (display name, avatar) per user
- **sensors** – one row per sensor, keyed by `firebase_sensor_id`
- **user_sensor_links** – which sensors each user has linked

plus indexes and Row Level Security (RLS) so users only see their own data.

After it runs successfully, run the app again (`flutter run`).
