-- Derby jersey builder: fonts saved to the site (made with "Шрифт из картинки").
-- Run once in Supabase → SQL Editor → New query → Run.
-- Every visitor sees these fonts; only admins can add, replace or remove them.

-- Who is an admin
create table if not exists public.site_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table public.site_admins enable row level security;
drop policy if exists "admins: see self" on public.site_admins;
create policy "admins: see self" on public.site_admins for select using (auth.uid() = user_id);

-- The fonts
create table if not exists public.site_fonts (
  family      text primary key,        -- CSS font-family used in designs
  name        text not null,           -- name shown in the menus
  data        text not null,           -- the .otf file, base64
  created_by  uuid default auth.uid(),
  created_at  timestamptz not null default now()
);
alter table public.site_fonts enable row level security;

drop policy if exists "site fonts: read"   on public.site_fonts;
drop policy if exists "site fonts: insert" on public.site_fonts;
drop policy if exists "site fonts: update" on public.site_fonts;
drop policy if exists "site fonts: delete" on public.site_fonts;

create policy "site fonts: read"   on public.site_fonts for select using (true);
create policy "site fonts: insert" on public.site_fonts for insert
  with check (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));
create policy "site fonts: update" on public.site_fonts for update
  using (exists (select 1 from public.site_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));
create policy "site fonts: delete" on public.site_fonts for delete
  using (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));

-- Make yourself an admin: put the e-mail you sign in to the site with, then run
-- insert into public.site_admins select id from auth.users where email = 'YOUR-EMAIL' on conflict do nothing;
