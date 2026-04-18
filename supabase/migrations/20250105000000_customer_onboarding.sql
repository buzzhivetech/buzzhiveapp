-- Customer-ready onboarding for BLE sensors.
--
-- Moves ownership from "link any firebase_sensor_id you know" to
-- "claim a pre-registered device with the factory claim code on the sticker".
-- All ownership mutations are funneled through the claim_sensor RPC
-- (SECURITY DEFINER); client-side writes to public.sensors are forbidden.

-- pgcrypto provides bcrypt via crypt() + gen_salt('bf').
create extension if not exists pgcrypto with schema extensions;

-- Lifecycle of a sensor from factory floor to a user's dashboard.
do $$ begin
  create type public.sensor_status as enum ('factory', 'claimed', 'disabled');
exception when duplicate_object then null; end $$;

alter table public.sensors
  add column if not exists status public.sensor_status not null default 'factory',
  add column if not exists claim_code_hash text,
  add column if not exists claimed_by uuid references auth.users(id) on delete set null,
  add column if not exists claimed_at timestamptz,
  add column if not exists hw_rev text,
  add column if not exists fw_version text;

comment on column public.sensors.status is
  'factory: available to claim. claimed: owned by claimed_by. disabled: recalled / bricked.';
comment on column public.sensors.claim_code_hash is
  'bcrypt hash (from extensions.crypt + gen_salt(''bf'')) of the device sticker claim code.';

-- Index for the status filter in claim_sensor; partial keeps it cheap.
create index if not exists idx_sensors_factory_by_device_id
  on public.sensors(firebase_sensor_id)
  where status = 'factory';

-- Attempt log for rate-limiting claim_sensor brute-force attempts.
create table if not exists public.claim_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  succeeded boolean not null,
  attempted_at timestamptz not null default now()
);

create index if not exists idx_claim_attempts_user_recent
  on public.claim_attempts(user_id, attempted_at desc);

alter table public.claim_attempts enable row level security;
-- No policies = default-deny for authenticated/anon. The RPC runs as security
-- definer and bypasses RLS for its own writes.

-- Typed result surface for claim_sensor. Returning a row is friendlier to
-- client parsing than raising exceptions through PostgREST.
do $$ begin
  create type public.claim_result as (
    ok boolean,
    error_code text,
    sensor_id uuid
  );
exception when duplicate_object then null; end $$;

-- Drop the legacy "anyone logged-in can write sensors" policies so the table
-- is default-deny under RLS. Reads stay open because we have a select policy
-- further down that scopes to linked sensors.
drop policy if exists "Authenticated users can create sensors" on public.sensors;
drop policy if exists "Users can update sensors when linking" on public.sensors;
drop policy if exists "Logged-in users can insert sensors" on public.sensors;
drop policy if exists "Logged-in users can update sensors" on public.sensors;

-- Keep a select policy that mirrors "you can see sensors linked to you".
-- Replace 20250103's overly-permissive "any logged-in user can read any sensor".
drop policy if exists "Logged-in users can read sensors" on public.sensors;
drop policy if exists "Users can view linked sensors" on public.sensors;
create policy "Users can view linked sensors" on public.sensors for select
  using (
    id in (select sensor_id from public.user_sensor_links where user_id = auth.uid())
  );
