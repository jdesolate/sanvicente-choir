import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

export const SUPABASE_URL      = 'https://fsvnmcgywicxrsvcmzuw.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzdm5tY2d5d2ljeHJzdmNtenV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwOTk0ODcsImV4cCI6MjA5NjY3NTQ4N30.B8UVyNrsSizLV0Hg7vJ1bOnYkSBepGWCXVaOsM6ggU0';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
