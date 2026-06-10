-- San Vicente Choir — Supabase Schema
-- Run this in the Supabase SQL Editor after creating the project.
-- After running, enable RLS on each table in the Table Editor (or via the
-- ALTER TABLE statements below) and apply the RLS policies in this file.

-- ─────────────────────────────────────────
-- EXTENSIONS
-- ─────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
-- TABLES
-- ─────────────────────────────────────────

-- profiles
-- One row per auth user. Created immediately after sign-up.
create table if not exists profiles (
  id                uuid        primary key references auth.users on delete cascade,
  full_name         text        not null,
  contact_number    text,
  birthday          date,
  age               int,
  school_occupation text,
  voice_part        text        check (voice_part in ('soprano','alto','tenor','bass')),
  role              text        not null default 'member'
                                check (role in ('member','secretary','admin')),
  status            text        not null default 'pending'
                                check (status in ('pending','active','associate','honorary')),
  custom_fields     jsonb       not null default '{}',
  created_at        timestamptz not null default now(),
  approved_at       timestamptz,
  approved_by       uuid        references profiles(id)
);

-- custom_field_definitions
-- Admin-defined extra fields shown on the registration form.
create table if not exists custom_field_definitions (
  id            uuid        primary key default uuid_generate_v4(),
  field_name    text        not null,
  field_type    text        not null check (field_type in ('text','number','date','dropdown')),
  field_options jsonb       not null default '[]',
  is_required   boolean     not null default false,
  sort_order    int         not null default 0,
  created_at    timestamptz not null default now()
);

-- events
create table if not exists events (
  id          uuid        primary key default uuid_generate_v4(),
  title       text        not null,
  event_date  date        not null,
  event_type  text        not null check (event_type in ('core','major','special')),
  description text,
  created_by  uuid        references profiles(id),
  created_at  timestamptz not null default now()
);

-- attendance
create table if not exists attendance (
  id         uuid        primary key default uuid_generate_v4(),
  event_id   uuid        not null references events(id) on delete cascade,
  member_id  uuid        not null references profiles(id) on delete cascade,
  status     text        not null check (status in ('present','absent','excused')),
  marked_by  uuid        references profiles(id),
  marked_at  timestamptz not null default now(),
  unique (event_id, member_id)
);

-- absence_requests
create table if not exists absence_requests (
  id            uuid        primary key default uuid_generate_v4(),
  member_id     uuid        not null references profiles(id) on delete cascade,
  event_id      uuid        not null references events(id) on delete cascade,
  request_type  text        not null check (request_type in ('advance','retroactive')),
  reason        text        not null,
  status        text        not null default 'pending'
                            check (status in ('pending','approved','rejected')),
  reviewer_note text,
  reviewed_by   uuid        references profiles(id),
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now()
);

-- songs
create table if not exists songs (
  id                  uuid        primary key default uuid_generate_v4(),
  title               text        not null,
  lyrics              text        not null,
  language_tags       text[]      not null default '{}',
  liturgical_use_tags text[]      not null default '{}',
  season_tags         text[]      not null default '{}',
  gdrive_url          text,
  youtube_url         text,
  created_by          uuid        references profiles(id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- Auto-update updated_at on songs
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger songs_updated_at
  before update on songs
  for each row execute procedure update_updated_at();

-- ─────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────

alter table profiles              enable row level security;
alter table custom_field_definitions enable row level security;
alter table events                enable row level security;
alter table attendance            enable row level security;
alter table absence_requests      enable row level security;
alter table songs                 enable row level security;

-- Helper: returns true when the calling user has the given role or higher.
-- Role hierarchy: admin > secretary > member
create or replace function auth_role()
returns text language sql security definer stable as $$
  select role from profiles where id = auth.uid()
$$;

-- ── profiles ──────────────────────────────

-- Any authenticated user reads their own row.
create policy "profiles: read own"
  on profiles for select
  using (id = auth.uid());

-- Secretary and admin read all rows.
create policy "profiles: secretary/admin read all"
  on profiles for select
  using (auth_role() in ('secretary','admin'));

-- A user inserts their own profile row (triggered at sign-up).
create policy "profiles: insert own"
  on profiles for insert
  with check (id = auth.uid());

-- A user updates their own non-sensitive fields.
create policy "profiles: update own"
  on profiles for update
  using (id = auth.uid());

-- Admin can update any profile (to change role/status/approval).
create policy "profiles: admin update any"
  on profiles for update
  using (auth_role() = 'admin');

-- ── custom_field_definitions ──────────────

-- Any authenticated user can read field definitions (needed for register form).
create policy "custom_fields: authenticated read"
  on custom_field_definitions for select
  using (auth.uid() is not null);

-- Only admin can write.
create policy "custom_fields: admin write"
  on custom_field_definitions for all
  using (auth_role() = 'admin')
  with check (auth_role() = 'admin');

-- ── events ────────────────────────────────

-- Any authenticated user reads events.
create policy "events: authenticated read"
  on events for select
  using (auth.uid() is not null);

-- Only admin can create, update, or delete events.
create policy "events: admin write"
  on events for all
  using (auth_role() = 'admin')
  with check (auth_role() = 'admin');

-- ── attendance ────────────────────────────

-- Secretary and admin read all attendance rows.
create policy "attendance: secretary/admin read all"
  on attendance for select
  using (auth_role() in ('secretary','admin'));

-- A member reads only their own attendance rows.
create policy "attendance: member read own"
  on attendance for select
  using (member_id = auth.uid());

-- Secretary and admin can insert/update attendance.
create policy "attendance: secretary/admin write"
  on attendance for all
  using (auth_role() in ('secretary','admin'))
  with check (auth_role() in ('secretary','admin'));

-- ── absence_requests ──────────────────────

-- Member inserts their own requests.
create policy "absence_requests: member insert own"
  on absence_requests for insert
  with check (member_id = auth.uid());

-- Member reads their own requests.
create policy "absence_requests: member read own"
  on absence_requests for select
  using (member_id = auth.uid());

-- Secretary and admin read all requests.
create policy "absence_requests: secretary/admin read all"
  on absence_requests for select
  using (auth_role() in ('secretary','admin'));

-- Secretary and admin update requests (approve/reject).
create policy "absence_requests: secretary/admin update"
  on absence_requests for update
  using (auth_role() in ('secretary','admin'))
  with check (auth_role() in ('secretary','admin'));

-- ── songs ─────────────────────────────────

-- Any authenticated user reads songs.
create policy "songs: authenticated read"
  on songs for select
  using (auth.uid() is not null);

-- Only admin can write songs.
create policy "songs: admin write"
  on songs for all
  using (auth_role() = 'admin')
  with check (auth_role() = 'admin');
