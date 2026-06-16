-- Migration: add 'inactive' member status
-- Run this in the Supabase SQL Editor.

alter table profiles drop constraint if exists profiles_status_check;
alter table profiles add constraint profiles_status_check
  check (status in ('pending','active','associate','honorary','inactive'));
