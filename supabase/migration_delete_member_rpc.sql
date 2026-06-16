-- Migration: admin-only RPC to fully delete a member (profile + auth user)
-- Run this in the Supabase SQL Editor.

create or replace function delete_member(member_id uuid)
returns void language plpgsql security definer as $$
begin
  -- Only super_admin (President) may call this
  if (select role from profiles where id = auth.uid()) != 'super_admin' then
    raise exception 'Unauthorized: only the President account can delete members';
  end if;

  -- Deleting the auth user cascades to profiles (via ON DELETE CASCADE)
  delete from auth.users where id = member_id;
end;
$$;
