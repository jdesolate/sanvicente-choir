-- Migration: add super_admin role + delete_member RPC
-- Run this in the Supabase SQL Editor.

-- 1. Extend the role check constraint to include super_admin
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('member','secretary','admin','super_admin'));

-- 2. Assign super_admin to the President account
update profiles
set role = 'super_admin'
where id = (
  select id from auth.users where email = 'admin@svc.com'
);

-- 3. Update RLS policies to grant super_admin the same access as admin
drop policy if exists "profiles: admin insert any"          on profiles;
drop policy if exists "profiles: admin update any"          on profiles;
drop policy if exists "profiles: admin delete any"          on profiles;
drop policy if exists "profiles: secretary/admin read all"  on profiles;
drop policy if exists "custom_fields: admin write"          on custom_field_definitions;
drop policy if exists "events: admin write"                 on events;
drop policy if exists "attendance: secretary/admin read all" on attendance;
drop policy if exists "attendance: secretary/admin write"   on attendance;
drop policy if exists "absence_requests: secretary/admin read all" on absence_requests;
drop policy if exists "absence_requests: secretary/admin update"   on absence_requests;
drop policy if exists "songs: admin write"                  on songs;

create policy "profiles: secretary/admin read all"  on profiles for select
  using (auth_role() in ('secretary','admin','super_admin'));
create policy "profiles: admin insert any"          on profiles for insert
  with check (auth_role() in ('admin','super_admin'));
create policy "profiles: admin update any"          on profiles for update
  using (auth_role() in ('admin','super_admin'));
create policy "profiles: admin delete any"          on profiles for delete
  using (auth_role() in ('admin','super_admin'));
create policy "custom_fields: admin write"          on custom_field_definitions for all
  using (auth_role() in ('admin','super_admin'))
  with check (auth_role() in ('admin','super_admin'));
create policy "events: admin write"                 on events for all
  using (auth_role() in ('admin','super_admin'))
  with check (auth_role() in ('admin','super_admin'));
create policy "attendance: secretary/admin read all" on attendance for select
  using (auth_role() in ('secretary','admin','super_admin'));
create policy "attendance: secretary/admin write"   on attendance for all
  using (auth_role() in ('secretary','admin','super_admin'))
  with check (auth_role() in ('secretary','admin','super_admin'));
create policy "absence_requests: secretary/admin read all" on absence_requests for select
  using (auth_role() in ('secretary','admin','super_admin'));
create policy "absence_requests: secretary/admin update"   on absence_requests for update
  using (auth_role() in ('secretary','admin','super_admin'))
  with check (auth_role() in ('secretary','admin','super_admin'));
create policy "songs: admin write"                  on songs for all
  using (auth_role() in ('admin','super_admin'))
  with check (auth_role() in ('admin','super_admin'));

-- 4. Create (or replace) the delete_member RPC — super_admin only
create or replace function delete_member(member_id uuid)
returns void language plpgsql security definer as $$
begin
  if (select role from profiles where id = auth.uid()) != 'super_admin' then
    raise exception 'Unauthorized: only the President account can delete members';
  end if;

  -- Deleting the auth user cascades to profiles automatically
  delete from auth.users where id = member_id;
end;
$$;
