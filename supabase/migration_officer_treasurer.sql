-- Migration: add officer and treasurer roles
-- Run this in the Supabase SQL Editor.

-- 1. Extend the role check constraint
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('member','secretary','officer','treasurer','admin','super_admin'));

-- 2. Update RLS policies to include officer and treasurer where applicable
--    Drop and recreate each affected policy.

-- ── profiles ───────────────────────────────────────────────────────────────
-- officer and treasurer need to see all members (for attendance/fines context)
drop policy if exists "profiles: secretary/admin read all" on profiles;
create policy "profiles: secretary/admin read all" on profiles for select
  using (auth_role() in ('secretary','officer','treasurer','admin','super_admin'));

-- ── events ─────────────────────────────────────────────────────────────────
-- officer can create/edit events (same as secretary)
drop policy if exists "events: admin write" on events;
create policy "events: admin write" on events for all
  using (auth_role() in ('officer','admin','super_admin'))
  with check (auth_role() in ('officer','admin','super_admin'));

-- ── attendance ─────────────────────────────────────────────────────────────
drop policy if exists "attendance: secretary/admin read all" on attendance;
create policy "attendance: secretary/admin read all" on attendance for select
  using (auth_role() in ('secretary','officer','admin','super_admin'));

drop policy if exists "attendance: secretary/admin write" on attendance;
create policy "attendance: secretary/admin write" on attendance for all
  using (auth_role() in ('secretary','officer','admin','super_admin'))
  with check (auth_role() in ('secretary','officer','admin','super_admin'));

-- ── absence_requests ────────────────────────────────────────────────────────
drop policy if exists "absence_requests: secretary/admin read all" on absence_requests;
create policy "absence_requests: secretary/admin read all" on absence_requests for select
  using (auth_role() in ('secretary','officer','admin','super_admin'));

drop policy if exists "absence_requests: secretary/admin update" on absence_requests;
create policy "absence_requests: secretary/admin update" on absence_requests for update
  using (auth_role() in ('secretary','officer','admin','super_admin'))
  with check (auth_role() in ('secretary','officer','admin','super_admin'));

-- ── songs ───────────────────────────────────────────────────────────────────
-- officer can manage songs and toggle is_currently_practicing
drop policy if exists "songs: admin write" on songs;
create policy "songs: admin write" on songs for all
  using (auth_role() in ('officer','admin','super_admin'))
  with check (auth_role() in ('officer','admin','super_admin'));
