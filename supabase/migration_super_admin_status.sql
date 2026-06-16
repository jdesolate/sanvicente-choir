-- Migration: ensure the super_admin service account is excluded from member lists
-- The tracker and attendance summary filter by status IN ('active','associate'),
-- so setting status to 'inactive' prevents the account from appearing there.

update profiles
set status = 'inactive'
where role = 'super_admin';
