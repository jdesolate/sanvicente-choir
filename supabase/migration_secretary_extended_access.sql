-- Migration: Secretary Extended Access
-- Grants secretary role access to treasurer features (fines, ledger)
-- and officer event management features (events, songs write).
-- Run this in the Supabase SQL Editor.

-- ── fines ──────────────────────────────────────────────────────────────────

drop policy if exists "fines: treasurer/admin read all" on fines;
create policy "fines: treasurer/admin read all" on fines for select
  using (auth_role() in ('secretary','treasurer','admin','super_admin'));

drop policy if exists "fines: treasurer/admin write" on fines;
create policy "fines: treasurer/admin write" on fines for all
  using  (auth_role() in ('secretary','treasurer','admin','super_admin'))
  with check (auth_role() in ('secretary','treasurer','admin','super_admin'));

-- ── ledger ─────────────────────────────────────────────────────────────────

drop policy if exists "ledger: treasurer/admin read" on ledger;
create policy "ledger: treasurer/admin read" on ledger for select
  using (auth_role() in ('secretary','treasurer','admin','super_admin'));

drop policy if exists "ledger: treasurer/admin write" on ledger;
create policy "ledger: treasurer/admin write" on ledger for all
  using  (auth_role() in ('secretary','treasurer','admin','super_admin'))
  with check (auth_role() in ('secretary','treasurer','admin','super_admin'));

-- ── events ─────────────────────────────────────────────────────────────────

drop policy if exists "events: admin write" on events;
create policy "events: admin write" on events for all
  using (auth_role() in ('secretary','officer','admin','super_admin'))
  with check (auth_role() in ('secretary','officer','admin','super_admin'));

-- ── songs ───────────────────────────────────────────────────────────────────

drop policy if exists "songs: admin write" on songs;
create policy "songs: admin write" on songs for all
  using (auth_role() in ('secretary','officer','admin','super_admin'))
  with check (auth_role() in ('secretary','officer','admin','super_admin'));
