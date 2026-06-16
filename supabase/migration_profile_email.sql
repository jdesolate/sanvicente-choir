-- Migration: add email column to profiles
-- Run this in the Supabase SQL Editor.

alter table profiles add column if not exists email text;

-- Backfill email from auth.users for all existing members
update profiles p
set email = u.email
from auth.users u
where u.id = p.id;
