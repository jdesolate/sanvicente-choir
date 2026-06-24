-- Migration: Session 15 — Treasurer Features
-- Creates fines and ledger tables with RLS policies.
-- Run this in the Supabase SQL Editor.

-- ── fines ──────────────────────────────────────────────────────────────────

create table if not exists fines (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references profiles(id) on delete cascade,
  event_id     uuid not null references events(id) on delete cascade,
  amount       numeric not null default 20,
  status       text not null default 'unpaid'
               check (status in ('unpaid', 'paid', 'waived')),
  notes        text,
  recorded_by  uuid references profiles(id),
  paid_at      timestamptz,
  created_at   timestamptz default now()
);

alter table fines enable row level security;

-- Member reads their own fines
create policy "fines: member read own" on fines for select
  using (member_id = auth.uid());

-- Treasurer and admin read all fines
create policy "fines: treasurer/admin read all" on fines for select
  using (auth_role() in ('treasurer','admin','super_admin'));

-- Treasurer and admin write fines
create policy "fines: treasurer/admin write" on fines for all
  using  (auth_role() in ('treasurer','admin','super_admin'))
  with check (auth_role() in ('treasurer','admin','super_admin'));

-- ── ledger ─────────────────────────────────────────────────────────────────

create table if not exists ledger (
  id           uuid primary key default gen_random_uuid(),
  type         text not null check (type in ('income','expense')),
  amount       numeric not null check (amount > 0),
  category     text not null,
  description  text,
  date         date not null,
  recorded_by  uuid references profiles(id),
  created_at   timestamptz default now()
);

alter table ledger enable row level security;

-- Treasurer and admin read all ledger entries
create policy "ledger: treasurer/admin read" on ledger for select
  using (auth_role() in ('treasurer','admin','super_admin'));

-- Treasurer and admin write ledger entries
create policy "ledger: treasurer/admin write" on ledger for all
  using  (auth_role() in ('treasurer','admin','super_admin'))
  with check (auth_role() in ('treasurer','admin','super_admin'));
