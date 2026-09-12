# Family Archive

A family tree site: any visitor can browse it, only you can edit it.

## How the security works

- **Storage & auth:** [Supabase](https://supabase.com) (a hosted Postgres database with built-in login). It's free for a site this size.
- **The page never decides who can edit.** The "Edit" buttons only *hide* for visitors — that's just UI polish. The real rule lives in the database itself, as Row Level Security (RLS) policies (see `supabase/schema.sql`): every write to `people`, `sources`, or `site_content` is checked against a Postgres function, `is_admin()`, that looks up the currently logged-in user in an `admins` table. If you're not logged in as the one admin account, the database itself refuses the write — no amount of editing the page's JavaScript in dev tools can get around that.
- **There is no public sign-up.** You create exactly one login (yourself) by hand in the Supabase dashboard. Nobody else can ever create an account through the site.
- **The API key in `config.js` is safe to publish.** It's Supabase's "anon" (public) key, which is designed to be embedded in client-side code — it can only do what your RLS policies allow. The dangerous key is the separate "service_role" key, which bypasses RLS entirely: **that one must never appear anywhere in this repo, this file, or the browser.** You won't need it for anything described here.
- **Contact/contribution messages:** anyone can submit one (it's a public form), but only the admin account can ever read them back — enforced the same way, via RLS.

## One-time setup

### 1. Create a Supabase project
Go to [supabase.com](https://supabase.com), sign up, and create a new project. Note its **Project URL** and give it a database password (store that password somewhere safe — you won't need it for this site, but Supabase requires it).

### 2. Run the schema
In your Supabase project: **SQL Editor → New query**, paste the entire contents of [`supabase/schema.sql`](supabase/schema.sql), and click **Run**. This creates all the tables, security policies, and the placeholder family tree data.

### 3. Create your admin login
Go to **Authentication → Users → Add user**, and create a user with your email and a strong password. Untick "Auto Confirm" only if you want to verify by email first — for a single admin account it's simplest to leave it checked.

Copy that user's **User UID** (shown in the users list).

Back in **SQL Editor**, run:
```sql
insert into admins (user_id) values ('paste-the-uid-here');
```
That one row is what makes that login an admin. To add a second admin later (e.g. a spouse), create another user the same way and insert their UID too. To revoke admin access, `delete from admins where user_id = '...'`.

### 4. Connect the frontend
Go to **Project Settings → API**. Copy the **Project URL** and the **anon public** key (not `service_role`) into [`config.js`](config.js):
```js
const SUPABASE_URL = 'https://your-project-ref.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-public-key';
```

### 5. Publish via GitHub Pages
Push this folder to a GitHub repo, then in the repo: **Settings → Pages → Deploy from a branch → main / (root)**. No build step is needed — it's a static site. Your family tree will be live at `https://<username>.github.io/<repo>/`.

### 6. Sign in
Open the site, click **Admin** in the top-right, and sign in with the email/password you created in step 3. You'll see Edit buttons appear on every person, the About page, the root quote, and a new **Messages** button in the nav for reading contact-form submissions.

## What's editable, and what isn't (yet)

Admins can edit, from the page itself: each person's name, relationship label, photo (uploaded from your computer, pasted as a URL, drag-to-reposition/zoom cropped, and adjusted with filter presets or brightness/contrast/saturation/grayscale/sepia sliders), emoji icon, description (any `https://` URL you type becomes clickable automatically, and if you paste in text that already has a hyperlink on part of it — e.g. copying "I love the **Cat**" where "Cat" links to a shelter — that link is preserved and shows up as a real link once saved), and sources (each with an optional link — when set, the citation's "[n]" number becomes a clickable link, and existing sources can be edited in place, not just deleted and re-added); the About page text; the root quote; and the feedback/contribution form intros.

Admins can also **add and remove people** directly from a person's panel:
- **Add descendant** creates a new person connected one generation below whoever's panel is open (e.g. open "Father" and add a "Grandmother" below him). There's no limit on how many generations deep the tree can go — the layout expands automatically.
- **Delete person** removes that person. If they have anyone connected below them, it warns you and deletes that whole branch too (their sources and connections go with them) — there's no undo, so double-check before confirming.

Rewiring an *existing* person to a different parent, or giving someone a second parent connection (for blended families), isn't built into the page UI — for that, edit the `connections` table directly in **Supabase → Table Editor** (a full spreadsheet-style admin GUI Supabase gives you for free).

## Mobile

On narrow screens (≤680px), the site switches to a completely different browsing layout instead of shrinking the desktop tree diagram: the root's photo goes full-width with their name overlaid in the corner, followed by each generation as its own horizontally-scrollable row of cards (tap any card to open the same profile panel as desktop). This kicks in and reverts automatically as the browser is resized or a device is rotated — no separate URL or setting.

## robots.txt

`robots.txt` blocks known AI training/scraping crawlers (GPTBot, CCBot, ClaudeBot, etc.) by name, since this site has real people's photos and personal stories, while leaving normal search engines alone so the site stays discoverable. Add or remove `User-agent` blocks there if you want to change that policy.

## Local development

This is a plain static site — no build step, no `node_modules`. Just open `index.html` in a browser, or serve the folder with any static file server:
```bash
python3 -m http.server 8000
```
