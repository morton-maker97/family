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
const SUPABASE_URL = 'https://xpyavbzwknqxxlicsnjm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweWF2Ynp3a25xeHhsaWNzbmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMDA0MTksImV4cCI6MjEwNDU3NjQxOX0.DdQnyZ1HS35uz-_oOXsrkYulQiNvaAYynP71HVYi2fw';
