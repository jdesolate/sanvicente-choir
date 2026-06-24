-- Add joined_choir_date to profiles.
-- Priority order for backfill:
--   1. Existing "Date of Joining Choir" custom field value (if filled in)
--   2. approved_at date
--   3. created_at date
alter table profiles
  add column if not exists joined_choir_date date;

-- Backfill from the "Date of Joining Choir" custom field for members who filled it in
update profiles p
set joined_choir_date = (
  select (p.custom_fields ->> cfd.id::text)::date
  from custom_field_definitions cfd
  where lower(cfd.field_name) = 'date of joining choir'
    and p.custom_fields ? cfd.id::text
    and (p.custom_fields ->> cfd.id::text) <> ''
  limit 1
)
where joined_choir_date is null
  and exists (
    select 1
    from custom_field_definitions cfd
    where lower(cfd.field_name) = 'date of joining choir'
      and p.custom_fields ? cfd.id::text
      and (p.custom_fields ->> cfd.id::text) <> ''
  );

-- For everyone else, fall back to approved_at then created_at
update profiles
set joined_choir_date = coalesce(approved_at::date, created_at::date)
where joined_choir_date is null;
