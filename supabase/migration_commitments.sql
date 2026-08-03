-- Migration: Session 25 — Commitment Reconciliation (Google Forms → Fines)
-- Creates commitments and member_aliases tables with RLS policies.
-- Run this in the Supabase SQL Editor.

-- ── commitments ────────────────────────────────────────────────────────────

create table if not exists commitments (
  id             uuid primary key default gen_random_uuid(),
  member_id      uuid not null references profiles(id) on delete cascade,
  event_id       uuid not null references events(id) on delete cascade,
  source         text not null default 'google_form',
  status         text not null default 'committed'
                 check (status in ('committed', 'cant_attend')),
  reason         text,
  raw_name       text,
  reconciled_at  timestamptz,
  imported_by    uuid references profiles(id),
  created_at     timestamptz default now(),
  unique (member_id, event_id)
);

alter table commitments enable row level security;

-- Member reads their own commitments
create policy "commitments: member read own" on commitments for select
  using (member_id = auth.uid());

-- Treasurer and admin read all commitments
create policy "commitments: treasurer/admin read all" on commitments for select
  using (auth_role() in ('treasurer','admin','super_admin'));

-- Treasurer and admin write commitments
create policy "commitments: treasurer/admin write" on commitments for all
  using  (auth_role() in ('treasurer','admin','super_admin'))
  with check (auth_role() in ('treasurer','admin','super_admin'));

-- ── member_aliases ─────────────────────────────────────────────────────────

create table if not exists member_aliases (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references profiles(id) on delete cascade,
  alias       text not null unique,
  created_by  uuid references profiles(id),
  created_at  timestamptz default now()
);

alter table member_aliases enable row level security;

-- Treasurer and admin read aliases
create policy "member_aliases: treasurer/admin read" on member_aliases for select
  using (auth_role() in ('treasurer','admin','super_admin'));

-- Treasurer and admin write aliases
create policy "member_aliases: treasurer/admin write" on member_aliases for all
  using  (auth_role() in ('treasurer','admin','super_admin'))
  with check (auth_role() in ('treasurer','admin','super_admin'));

-- ── attendance read scope ──────────────────────────────────────────────────
-- REVIEW BEFORE RUNNING: this widens an existing RLS read policy.
-- Reconciliation joins commitments against attendance, so the treasurer must be
-- able to read attendance rows. Read only — the write policy is left untouched.

drop policy if exists "attendance: secretary/admin read all" on attendance;
create policy "attendance: secretary/admin read all" on attendance for select
  using (auth_role() in ('secretary','treasurer','admin','super_admin'));
