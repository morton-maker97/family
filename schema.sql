-- ════════════════════════════════════════════════════════════
-- Family Archive — Supabase schema
--
-- Run this ONCE in your Supabase project's SQL editor
-- (Dashboard → SQL Editor → New query → paste → Run).
--
-- Security model:
--   - Every table is readable by anyone (the site is public to view).
--   - Only rows in `admins` can write to content tables. There is no
--     public sign-up: you create your one admin login by hand in the
--     Auth dashboard, then add their user id to `admins` (see README).
--   - `messages` is the exception: anyone can INSERT (contact /
--     contribution forms) but only an admin can read or delete them.
-- ════════════════════════════════════════════════════════════

-- ── People ──
create table if not exists people (
  id           text primary key,
  name         text not null default 'Unnamed',
  rel          text not null default '',
  icon         text not null default '👤',
  photo_url    text,
  description  text not null default '',
  generation   int not null default 1,   -- 0 = root, 1 = parents, 2 = grandparents, 3 = great-grandparents
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now()
);

-- ── Parent → child edges (drives the connector lines + breadcrumb) ──
create table if not exists connections (
  id         bigint generated always as identity primary key,
  parent_id  text not null references people(id) on delete cascade,
  child_id   text not null references people(id) on delete cascade,
  unique (parent_id, child_id)
);

-- ── Sources / citations, one row per citation, per person ──
create table if not exists sources (
  id          bigint generated always as identity primary key,
  person_id   text not null references people(id) on delete cascade,
  text        text not null,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

-- ── Site-wide text: about page, root quote, contact-form intros ──
-- Single row, id is always 1.
create table if not exists site_content (
  id              int primary key default 1,
  about_text      text not null default '',
  root_quote      text not null default '"Add a quote or note…"',
  feedback_intro  text not null default '',
  contrib_intro   text not null default '',
  constraint site_content_singleton check (id = 1)
);
insert into site_content (id) values (1) on conflict (id) do nothing;

-- ── Contact / contribution submissions ──
create table if not exists messages (
  id           bigint generated always as identity primary key,
  type         text not null check (type in ('feedback', 'contribution')),
  name         text,
  email        text,
  branch_name  text,
  body         text not null,
  created_at   timestamptz not null default now()
);

-- ── Admin allow-list: user_id rows here can write; everyone else cannot ──
create table if not exists admins (
  user_id  uuid primary key references auth.users(id) on delete cascade
);

-- Lets the frontend ask "am I an admin?" without ever being able to read
-- the admins table itself (it stays locked down below).
create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (select 1 from admins where user_id = auth.uid());
$$;
grant execute on function is_admin() to anon, authenticated;

-- ════════════════════════════════════════════════════════════
-- Row Level Security
-- ════════════════════════════════════════════════════════════
alter table people        enable row level security;
alter table connections   enable row level security;
alter table sources       enable row level security;
alter table site_content  enable row level security;
alter table messages      enable row level security;
alter table admins        enable row level security;

-- Public read access (the tree is meant to be viewed by anyone)
drop policy if exists "public can read people"       on people;
drop policy if exists "public can read connections"  on connections;
drop policy if exists "public can read sources"      on sources;
drop policy if exists "public can read site_content" on site_content;
create policy "public can read people"       on people        for select using (true);
create policy "public can read connections"  on connections   for select using (true);
create policy "public can read sources"      on sources       for select using (true);
create policy "public can read site_content" on site_content  for select using (true);

-- Admin-only writes, enforced server-side — the UI hiding edit buttons
-- for visitors is a nicety; THIS is what actually stops them.
drop policy if exists "admin can write people"       on people;
drop policy if exists "admin can write connections"  on connections;
drop policy if exists "admin can write sources"      on sources;
drop policy if exists "admin can write site_content" on site_content;
create policy "admin can write people" on people
  for all using (is_admin()) with check (is_admin());
create policy "admin can write connections" on connections
  for all using (is_admin()) with check (is_admin());
create policy "admin can write sources" on sources
  for all using (is_admin()) with check (is_admin());
create policy "admin can write site_content" on site_content
  for all using (is_admin()) with check (is_admin());

-- Messages: anyone can submit, only the admin can ever read them back
drop policy if exists "anyone can submit a message" on messages;
drop policy if exists "admin can read messages"      on messages;
drop policy if exists "admin can delete messages"    on messages;
create policy "anyone can submit a message" on messages
  for insert with check (true);
create policy "admin can read messages" on messages
  for select using (is_admin());
create policy "admin can delete messages" on messages
  for delete using (is_admin());

-- admins table: never exposed to the client directly, not even to admins
-- (membership is only ever checked via is_admin(), never listed)
drop policy if exists "no direct access to admins" on admins;
create policy "no direct access to admins" on admins
  for all using (false) with check (false);

-- ════════════════════════════════════════════════════════════
-- Seed data — the same placeholder tree the original page shipped
-- with, so the site works immediately. Edit or delete freely once
-- you're signed in as admin.
-- ════════════════════════════════════════════════════════════
insert into people (id, name, rel, icon, generation, sort_order) values
  ('root','Your Name','You','👤',0,0),
  ('p1','Father','Father','👨',1,0),
  ('p2','Mother','Mother','👩',1,1),
  ('p3','Stepfather','Stepfather','👨',1,2),
  ('p4','Stepmother','Stepmother','👩',1,3),
  ('p5','Guardian','Guardian','🧑',1,4),
  ('p6','Adoptive Father','Adoptive Father','👨',1,5),
  ('p7','Adoptive Mother','Adoptive Mother','👩',1,6),
  ('p8','Foster Parent','Foster Parent','🧑',1,7),
  ('gp1','Grandfather','Paternal Grandfather','👴',2,0),
  ('gp2','Grandmother','Paternal Grandmother','👵',2,1),
  ('gp3','Grandfather','Maternal Grandfather','👴',2,2),
  ('gp4','Grandmother','Maternal Grandmother','👵',2,3),
  ('gp5','Grandfather','Step-Grandfather','👴',2,4),
  ('gp6','Grandmother','Step-Grandmother','👵',2,5),
  ('gg1','Great-Grandfather','Pat. Great-Grandfather','👴',3,0),
  ('gg2','Great-Grandmother','Pat. Great-Grandmother','👵',3,1),
  ('gg3','Great-Grandfather','Mat. Great-Grandfather','👴',3,2),
  ('gg4','Great-Grandmother','Mat. Great-Grandmother','👵',3,3),
  ('gg5','Great-Grandfather','Step Great-Grandfather','👴',3,4),
  ('gg6','Great-Grandmother','Step Great-Grandmother','👵',3,5)
on conflict (id) do nothing;

insert into connections (parent_id, child_id) values
  ('root','p1'), ('root','p2'), ('root','p3'), ('root','p4'),
  ('root','p5'), ('root','p6'), ('root','p7'), ('root','p8'),
  ('p1','gp1'),  ('p1','gp2'),
  ('p2','gp3'),  ('p2','gp4'),
  ('p3','gp5'),  ('p3','gp6'),
  ('gp1','gg1'), ('gp1','gg2'),
  ('gp3','gg3'), ('gp3','gg4'),
  ('gp5','gg5'), ('gp5','gg6')
on conflict do nothing;

update site_content set
  about_text = 'This is a family archive website. Click any photo in the tree to view profiles, add descriptions, and cite sources.

Scroll left and right on the tree to see all branches. Use the zoom controls to navigate generations, or switch to grid view for a complete overview.',
  feedback_intro = 'Send us your thoughts or corrections about this archive.',
  contrib_intro = 'Submit a new branch to the tree.

Have records, photos, or information about a family member not yet included? Share them here and we''ll review your contribution.'
where id = 1;
