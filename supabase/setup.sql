-- Derby jersey builder: cloud projects.
-- Run once in Supabase → SQL Editor → New query → Run.

create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null default 'Без названия',
  data        jsonb not null,          -- canvas + Team Builder state
  thumb       text,                    -- small JPEG preview (data URL)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists projects_user_updated on public.projects (user_id, updated_at desc);

-- Only the owner can see or change a project
alter table public.projects enable row level security;

drop policy if exists "own projects: read"   on public.projects;
drop policy if exists "own projects: insert" on public.projects;
drop policy if exists "own projects: update" on public.projects;
drop policy if exists "own projects: delete" on public.projects;

create policy "own projects: read"   on public.projects for select using (auth.uid() = user_id);
create policy "own projects: insert" on public.projects for insert with check (auth.uid() = user_id);
create policy "own projects: update" on public.projects for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own projects: delete" on public.projects for delete using (auth.uid() = user_id);

-- Keep updated_at current on every save
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists projects_touch on public.projects;
create trigger projects_touch before update on public.projects
  for each row execute function public.touch_updated_at();
