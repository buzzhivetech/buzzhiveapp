-- Fix RLS on sensors so link flow works: INSERT + RETURNING id + UPDATE on conflict.
-- Run in Supabase SQL Editor if the link-sensor 42501 error persists.

-- 1) Allow SELECT on rows you created (so .select('id') after insert returns the row)
alter table public.sensors add column if not exists created_by uuid references auth.users(id) default auth.uid();

-- 2) SELECT: linked to you OR you created the row
drop policy if exists "Users can view linked sensors" on public.sensors;
create policy "Users can view linked sensors" on public.sensors for select
  using (
    id in (select sensor_id from public.user_sensor_links where user_id = auth.uid())
    or created_by = auth.uid()
  );

-- 3) Allow UPDATE so upsert can update existing sensor (e.g. display_name on conflict)
drop policy if exists "Users can update sensors when linking" on public.sensors;
create policy "Users can update sensors when linking" on public.sensors for update
  with check (auth.uid() is not null);

-- 4) Ensure INSERT allows any logged-in user (role-agnostic)
drop policy if exists "Authenticated users can create sensors" on public.sensors;
create policy "Authenticated users can create sensors" on public.sensors for insert
  with check (auth.uid() is not null);
