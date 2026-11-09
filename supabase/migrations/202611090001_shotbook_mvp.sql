create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null default '',
  avatar_url text,
  bio text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  legacy_id text unique,
  title text not null,
  description text not null default '',
  image_url text not null,
  source_page text,
  credit text,
  license text,
  storage_path text,
  category text not null,
  source_type text not null check (source_type in ('curated', 'community')),
  author_id uuid references public.profiles (id) on delete cascade,
  device text,
  camera text,
  focal_length text,
  iso text,
  shutter_speed text,
  aperture text,
  white_balance text,
  exposure_compensation text,
  pose_data jsonb not null default '{}'::jsonb,
  editing_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint community_photo_author_required
    check (source_type <> 'community' or author_id is not null)
);

create index if not exists photos_created_at_idx on public.photos (created_at desc);
create index if not exists photos_category_idx on public.photos (category);
create index if not exists photos_author_idx on public.photos (author_id) where author_id is not null;

create table if not exists public.saved_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  photo_id uuid not null references public.photos (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, photo_id)
);

create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  photo_id uuid not null references public.photos (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, photo_id)
);

create index if not exists saved_photos_user_idx on public.saved_photos (user_id, created_at desc);
create index if not exists likes_photo_idx on public.likes (photo_id);

create or replace function public.create_shotbook_profile()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  candidate_username text;
begin
  candidate_username := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    'user_' || substr(new.id::text, 1, 8)
  );

  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    candidate_username,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(coalesce(new.email, candidate_username), '@', 1)),
    nullif(new.raw_user_meta_data ->> 'avatar_url', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_shotbook on auth.users;
create trigger on_auth_user_created_shotbook
  after insert on auth.users
  for each row execute procedure public.create_shotbook_profile();

alter table public.profiles enable row level security;
alter table public.photos enable row level security;
alter table public.saved_photos enable row level security;
alter table public.likes enable row level security;

drop policy if exists "Profiles are public to read" on public.profiles;
create policy "Profiles are public to read" on public.profiles
  for select using (true);
drop policy if exists "Users create their own profile" on public.profiles;
create policy "Users create their own profile" on public.profiles
  for insert with check (auth.uid() = id);
drop policy if exists "Users update their own profile" on public.profiles;
create policy "Users update their own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Public photos are readable" on public.photos;
create policy "Public photos are readable" on public.photos
  for select using (source_type in ('curated', 'community'));
drop policy if exists "Users create their own community photos" on public.photos;
create policy "Users create their own community photos" on public.photos
  for insert with check (
    source_type = 'community' and author_id = auth.uid()
  );
drop policy if exists "Users update their own community photos" on public.photos;
create policy "Users update their own community photos" on public.photos
  for update using (source_type = 'community' and author_id = auth.uid())
  with check (source_type = 'community' and author_id = auth.uid());
drop policy if exists "Users delete their own community photos" on public.photos;
create policy "Users delete their own community photos" on public.photos
  for delete using (source_type = 'community' and author_id = auth.uid());

drop policy if exists "Users read their own saved photos" on public.saved_photos;
create policy "Users read their own saved photos" on public.saved_photos
  for select using (auth.uid() = user_id);
drop policy if exists "Users save photos for themselves" on public.saved_photos;
create policy "Users save photos for themselves" on public.saved_photos
  for insert with check (auth.uid() = user_id);
drop policy if exists "Users remove their own saved photos" on public.saved_photos;
create policy "Users remove their own saved photos" on public.saved_photos
  for delete using (auth.uid() = user_id);

drop policy if exists "Users read likes" on public.likes;
create policy "Users read likes" on public.likes
  for select using (true);
drop policy if exists "Users like as themselves" on public.likes;
create policy "Users like as themselves" on public.likes
  for insert with check (auth.uid() = user_id);
drop policy if exists "Users remove their own likes" on public.likes;
create policy "Users remove their own likes" on public.likes
  for delete using (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('photos', 'photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public reads Shotbook images" on storage.objects;
create policy "Public reads Shotbook images" on storage.objects
  for select using (bucket_id in ('photos', 'avatars'));
drop policy if exists "Users upload their own Shotbook images" on storage.objects;
create policy "Users upload their own Shotbook images" on storage.objects
  for insert with check (
    bucket_id in ('photos', 'avatars') and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "Users update their own Shotbook images" on storage.objects;
create policy "Users update their own Shotbook images" on storage.objects
  for update using (
    bucket_id in ('photos', 'avatars') and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id in ('photos', 'avatars') and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "Users delete their own Shotbook images" on storage.objects;
create policy "Users delete their own Shotbook images" on storage.objects
  for delete using (
    bucket_id in ('photos', 'avatars') and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Supabase projects may grant broad table privileges by default. RLS does not
-- constrain TRUNCATE, REFERENCES, or TRIGGER, so remove those grants explicitly.
revoke all on table
  public.profiles,
  public.photos,
  public.saved_photos,
  public.likes
from public, anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;

grant select on table public.profiles to anon, authenticated;
grant insert, update on table public.profiles to authenticated;

grant select on table public.photos to anon, authenticated;
grant insert, update, delete on table public.photos to authenticated;

grant select, insert, delete on table public.saved_photos to authenticated;
grant select on table public.likes to anon, authenticated;
grant insert, delete on table public.likes to authenticated;

grant all on table
  public.profiles,
  public.photos,
  public.saved_photos,
  public.likes
to service_role;

-- New public-schema objects stay inaccessible until a migration explicitly grants access.
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all on functions from anon, authenticated, service_role, public;
alter default privileges for role postgres
  revoke execute on functions from public;

revoke all on function public.create_shotbook_profile()
  from public, anon, authenticated, service_role;
