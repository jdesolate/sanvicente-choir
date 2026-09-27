-- Migration: Monthly Recognitions ("With Gratitude" Hall of Fame)
-- Stores admin-confirmed recognition editions with custom date ranges,
-- member tiers, and editable affirmation messages.
-- Regular members only see records where is_published = true.

create table if not exists monthly_recognitions (
  id                  uuid primary key default gen_random_uuid(),
  title               text not null default 'With Gratitude',
  period_label        text not null,
  start_date          date,
  end_date            date,
  event_count         int not null default 0,
  members_logged      int not null default 0,
  choir_avg_rate      numeric not null default 0,
  steady_servers      jsonb not null default '[]'::jsonb,
  consistent_servers  jsonb not null default '[]'::jsonb,
  section_standings   jsonb not null default '[]'::jsonb,
  affirmation_quote   text default 'Dili ni ranking — pasalamat lang gyud namo sa mga nagpadayon paghatag panahon ug boses alang sa atong ministeryo. Kung dili ka pa nakaserve og daghan, okay ra — padayon ta together.',
  motto               text default 'Better Music is Built on Steadier People',
  is_published        boolean not null default false,
  published_at        timestamptz,
  published_by        uuid references profiles(id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

alter table monthly_recognitions enable row level security;

-- Any authenticated user can read published recognitions
drop policy if exists "recognitions: authenticated read published" on monthly_recognitions;
create policy "recognitions: authenticated read published"
  on monthly_recognitions for select
  using (is_published = true or auth_role() in ('secretary','officer','admin','super_admin'));

-- Leadership can insert, update, delete recognitions
drop policy if exists "recognitions: leadership write" on monthly_recognitions;
create policy "recognitions: leadership write"
  on monthly_recognitions for all
  using (auth_role() in ('secretary','officer','admin','super_admin'))
  with check (auth_role() in ('secretary','officer','admin','super_admin'));
