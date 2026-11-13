-- 1. Catalog fields: fast thumbnails, stable layout, phone recipes, bilingual text.
alter table public.photos
  add column if not exists thumb_url text,
  add column if not exists aspect_ratio real,
  add column if not exists device_id text,
  add column if not exists creator_url text,
  add column if not exists license_url text,
  add column if not exists translations jsonb not null default '{}'::jsonb,
  add column if not exists sort_order integer,
  add column if not exists is_hidden boolean not null default false;

create index if not exists photos_catalog_idx
  on public.photos (source_type, sort_order, created_at desc);
create index if not exists photos_community_feed_idx
  on public.photos (created_at desc) where source_type = 'community';

-- 2. Blocking: a user never sees content from people they blocked.
create table if not exists public.blocks (
  blocker_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
alter table public.blocks enable row level security;

drop policy if exists "Users read their own blocks" on public.blocks;
create policy "Users read their own blocks" on public.blocks
  for select using (auth.uid() = blocker_id);
drop policy if exists "Users block as themselves" on public.blocks;
create policy "Users block as themselves" on public.blocks
  for insert with check (auth.uid() = blocker_id);
drop policy if exists "Users unblock as themselves" on public.blocks;
create policy "Users unblock as themselves" on public.blocks
  for delete using (auth.uid() = blocker_id);

-- 3. Reports on photos or users. The owner reviews them in the dashboard.
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  photo_id uuid references public.photos (id) on delete cascade,
  reported_user_id uuid references public.profiles (id) on delete cascade,
  reason text not null check (
    reason in ('spam', 'nudity', 'violence', 'harassment', 'hate',
               'copyright', 'other')
  ),
  details text check (char_length(details) <= 500),
  status text not null default 'open'
    check (status in ('open', 'removed', 'dismissed')),
  created_at timestamptz not null default now(),
  check (photo_id is not null or reported_user_id is not null)
);
create unique index if not exists reports_one_per_photo
  on public.reports (reporter_id, photo_id) where photo_id is not null;
create unique index if not exists reports_one_per_user
  on public.reports (reporter_id, reported_user_id)
  where photo_id is null and reported_user_id is not null;
create index if not exists reports_open_idx
  on public.reports (status, created_at desc);
alter table public.reports enable row level security;

drop policy if exists "Users file reports as themselves" on public.reports;
create policy "Users file reports as themselves" on public.reports
  for insert with check (auth.uid() = reporter_id);
drop policy if exists "Users read their own reports" on public.reports;
create policy "Users read their own reports" on public.reports
  for select using (auth.uid() = reporter_id);

-- A community photo is hidden automatically after 3 different people report
-- it, until a moderator reviews it.
create or replace function public.hide_reported_photo()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.photo_id is not null and (
    select count(distinct reporter_id)
      from public.reports
     where photo_id = new.photo_id and status = 'open'
  ) >= 3 then
    update public.photos
       set is_hidden = true
     where id = new.photo_id and source_type = 'community';
  end if;
  return new;
end;
$$;

drop trigger if exists hide_reported_photo on public.reports;
create trigger hide_reported_photo
  after insert on public.reports
  for each row execute function public.hide_reported_photo();

-- Readers never get hidden photos or photos by people they blocked.
-- Authors still see their own hidden posts.
drop policy if exists "Public photos are readable" on public.photos;
create policy "Public photos are readable" on public.photos
  for select using (
    source_type in ('curated', 'community')
    and (not is_hidden or author_id = auth.uid())
    and not exists (
      select 1 from public.blocks b
       where b.blocker_id = auth.uid() and b.blocked_id = photos.author_id
    )
  );

-- Authors must not unhide their own moderated posts.
create or replace function public.guard_photo_moderation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_hidden is distinct from old.is_hidden
     and auth.role() <> 'service_role'
     and current_user not in ('postgres', 'supabase_admin') then
    new.is_hidden := old.is_hidden;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_photo_moderation on public.photos;
create trigger guard_photo_moderation
  before update on public.photos
  for each row execute function public.guard_photo_moderation();

-- 4. Account deletion from inside the app (Google Play requirement).
-- The app removes the user's storage files first, then calls this.
-- Profiles, posts, saves, likes, blocks and reports go with it by cascade.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 5. Privileges, matching the rest of the schema.
revoke all on table public.blocks, public.reports
  from public, anon, authenticated;
grant select, insert, delete on table public.blocks to authenticated;
grant select, insert on table public.reports to authenticated;
grant all on table public.blocks, public.reports to service_role;
