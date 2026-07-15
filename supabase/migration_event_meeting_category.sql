-- Migration: widen event_category beyond service/practice
-- Adds: meeting (officer-only attendance), assembly (all-member general
-- assembly), activity (voluntary recreational / seminar / outreach).
-- Run this in the Supabase SQL Editor.
-- event_category was added without a committed migration; the drop is defensive
-- in case a check constraint exists under the default name.

alter table events drop constraint if exists events_event_category_check;
alter table events add constraint events_event_category_check
  check (event_category in ('service','practice','meeting','assembly','activity'));
