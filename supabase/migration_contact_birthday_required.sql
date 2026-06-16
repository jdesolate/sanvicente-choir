-- Migration: make contact_number and birthday required, drop age column
-- Run this in the Supabase SQL Editor.

-- 1. Backfill any existing NULLs before adding NOT NULL constraints
--    (safe to run even if there are no rows)
UPDATE profiles SET contact_number = '' WHERE contact_number IS NULL;
UPDATE profiles SET birthday = '2000-01-01' WHERE birthday IS NULL;

-- 2. Add NOT NULL constraints
ALTER TABLE profiles ALTER COLUMN contact_number SET NOT NULL;
ALTER TABLE profiles ALTER COLUMN birthday SET NOT NULL;

-- 3. Drop the age column (now derived from birthday where needed)
ALTER TABLE profiles DROP COLUMN IF EXISTS age;
