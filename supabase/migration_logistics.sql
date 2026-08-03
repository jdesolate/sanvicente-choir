-- Migration: logistics role + inventory and borrowing log (Session 24)
-- Run this in the Supabase SQL Editor.

-- 1. Extend the role check constraint
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('member','secretary','officer','treasurer','logistics','admin','super_admin'));

-- 2. Logistics needs to see all members for the borrower dropdown
drop policy if exists "profiles: secretary/admin read all" on profiles;
create policy "profiles: secretary/admin read all" on profiles for select
  using (auth_role() in ('secretary','officer','treasurer','logistics','admin','super_admin'));

-- 3. Inventory items
create table if not exists inventory_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'other'
    check (category in ('instrument','sound','folders','uniform','other')),
  quantity int not null default 1 check (quantity >= 0),
  condition text not null default 'good'
    check (condition in ('good','needs_repair','broken','lost')),
  storage_location text,
  acquired_date date,
  photo_url text,
  notes text,
  is_retired boolean not null default false,
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table inventory_items enable row level security;

-- 4. Borrowing log
create table if not exists borrow_records (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references inventory_items(id) on delete cascade,
  borrower_id uuid references profiles(id),
  borrower_name text, -- free text for non-member borrowers
  borrowed_at date not null default current_date,
  due_note text,
  returned_at date,
  return_condition text
    check (return_condition in ('good','needs_repair','broken','lost')),
  notes text,
  recorded_by uuid references profiles(id),
  created_at timestamptz default now(),
  check (borrower_id is not null or borrower_name is not null)
);
alter table borrow_records enable row level security;

-- 5. RLS: officer-tier and up read; logistics/admin write
create policy "inventory: officer-tier read" on inventory_items for select
  using (auth_role() in ('secretary','officer','treasurer','logistics','admin','super_admin'));
create policy "inventory: logistics write" on inventory_items for all
  using (auth_role() in ('logistics','admin','super_admin'))
  with check (auth_role() in ('logistics','admin','super_admin'));

create policy "borrow: officer-tier read" on borrow_records for select
  using (auth_role() in ('secretary','officer','treasurer','logistics','admin','super_admin'));
create policy "borrow: logistics write" on borrow_records for all
  using (auth_role() in ('logistics','admin','super_admin'))
  with check (auth_role() in ('logistics','admin','super_admin'));
