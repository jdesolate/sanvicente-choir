-- Migration: Sinking Fund
-- Creates sinking_fund_contributions table with RLS policies.
-- Secretary manages contributions; members read their own total.
-- Run this in the Supabase SQL Editor.

create table if not exists sinking_fund_contributions (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references profiles(id) on delete cascade,
  amount       numeric not null check (amount > 0),
  date         date not null default current_date,
  notes        text,
  recorded_by  uuid references profiles(id),
  created_at   timestamptz default now()
);

alter table sinking_fund_contributions enable row level security;

-- Member reads their own contributions
create policy "sinking_fund: member read own" on sinking_fund_contributions for select
  using (member_id = auth.uid());

-- Secretary and admin read all
create policy "sinking_fund: secretary/admin read all" on sinking_fund_contributions for select
  using (auth_role() in ('secretary','admin','super_admin'));

-- Secretary and admin write all
create policy "sinking_fund: secretary/admin write" on sinking_fund_contributions for all
  using  (auth_role() in ('secretary','admin','super_admin'))
  with check (auth_role() in ('secretary','admin','super_admin'));
