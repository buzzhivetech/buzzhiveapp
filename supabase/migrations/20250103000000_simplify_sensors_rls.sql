-- Simplified RLS for sensors table.
-- The sensors table is a shared lookup (firebase_sensor_id → uuid).
-- Access control lives on user_sensor_links, not sensors.
-- Run this in Supabase SQL Editor to fix 42501 errors.

-- Drop all existing sensors policies
drop policy if exists "Users can view linked sensors" on public.sensors;
drop policy if exists "Authenticated users can create sensors" on public.sensors;
drop policy if exists "Users can update sensors when linking" on public.sensors;

-- Any logged-in user can SELECT any sensor row
create policy "Logged-in users can read sensors" on public.sensors
  for select using (auth.uid() is not null);

-- Any logged-in user can INSERT (creating the sensor record when linking)
create policy "Logged-in users can insert sensors" on public.sensors
  for insert with check (auth.uid() is not null);

-- Any logged-in user can UPDATE (upsert on conflict needs this)
create policy "Logged-in users can update sensors" on public.sensors
  for update using (auth.uid() is not null);
