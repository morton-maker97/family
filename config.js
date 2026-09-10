// Supabase project connection details.
//
// Both of these are meant to be public — this is the "anon" key, not the
// secret "service_role" key. It can only ever do what your Row Level
// Security policies in supabase/schema.sql allow (public read, admin-only
// write), so it is safe to commit this file to a public GitHub repo.
//
// NEVER put a "service_role" key in this file or anywhere in this repo.
//
// Get these two values from: Supabase Dashboard → Project Settings → API.
const SUPABASE_URL = 'https://YOUR-PROJECT-REF.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-ANON-PUBLIC-KEY';
