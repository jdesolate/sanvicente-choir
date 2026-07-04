-- Migration: Song assignment mass part
-- Adds a mass_part column to song_assignments so each assigned song records
-- which part of the mass it fills (Entrance, Kyrie, Gloria, …). This drives the
-- ordered, labeled lineup and full-lyrics copy in the Song Library.
-- Run this in the Supabase SQL Editor.

alter table song_assignments
  add column if not exists mass_part text;
