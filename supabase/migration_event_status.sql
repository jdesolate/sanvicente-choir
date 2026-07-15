-- Migration: Calendar support — allow events to be marked cancelled instead of deleted
-- Run this in the Supabase SQL Editor (after migration_event_time_location.sql).

alter table events add column if not exists status text not null default 'scheduled'
  check (status in ('scheduled','cancelled'));
