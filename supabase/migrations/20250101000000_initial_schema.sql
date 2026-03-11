-- Run this in Supabase Dashboard: SQL Editor → New query → paste → Run
-- Required for the app: profiles, sensors, user_sensor_links (and RLS).

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Sensors (keyed by Firebase node ID)
create table if not exists public.sensors (
  id uuid primary key default gen_random_uuid(),
  firebase_sensor_id text not null unique,
  display_name text,
  created_at timestamptz not null default now()
);

comment on column public.sensors.firebase_sensor_id is 'Node ID from Firebase path sensor_data/{id}/... (e.g. 10001)';

-- User–sensor links (many-to-many)
create table if not exists public.user_sensor_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sensor_id uuid not null references public.sensors(id) on delete cascade,
  display_name text,
  linked_at timestamptz not null default now(),
  unique(user_id, sensor_id)
);

comment on column public.user_sensor_links.display_name is 'User-specific label for this sensor';

-- Indexes
create index if not exists idx_sensors_firebase_sensor_id on public.sensors(firebase_sensor_id);
create index if not exists idx_user_sensor_links_user_id on public.user_sensor_links(user_id);
create index if not exists idx_user_sensor_links_sensor_id on public.user_sensor_links(sensor_id);

-- RLS
alter table public.profiles enable row level security;
alter table public.sensors enable row level security;
alter table public.user_sensor_links enable row level security;

-- Profiles: own row only
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Sensors: view if linked; insert when linking
drop policy if exists "Users can view linked sensors" on public.sensors;
create policy "Users can view linked sensors" on public.sensors for select
  using (id in (select sensor_id from public.user_sensor_links where user_id = auth.uid()));
drop policy if exists "Authenticated users can create sensors" on public.sensors;
create policy "Authenticated users can create sensors" on public.sensors for insert to authenticated with check (true);

-- User_sensor_links: own links only
drop policy if exists "Users can view own links" on public.user_sensor_links;
create policy "Users can view own links" on public.user_sensor_links for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own links" on public.user_sensor_links;
create policy "Users can insert own links" on public.user_sensor_links for insert with check (auth.uid() = user_id);
drop policy if exists "Users can delete own links" on public.user_sensor_links;
create policy "Users can delete own links" on public.user_sensor_links for delete using (auth.uid() = user_id);
drop policy if exists "Users can update own links" on public.user_sensor_links;
create policy "Users can update own links" on public.user_sensor_links for update using (auth.uid() = user_id);

-- Auto-create profile on sign-up (optional but recommended)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
