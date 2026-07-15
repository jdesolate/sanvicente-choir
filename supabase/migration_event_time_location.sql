-- Migration: Calendar support — add optional time and location to events
-- Run this in the Supabase SQL Editor.

alter table events add column if not exists event_time time;
alter table events add column if not exists location text;
