-- Photos from the Unsplash API: attribution and download tracking
-- follow the Unsplash API guidelines (images are hotlinked, never copied).
alter table public.photos add column if not exists unsplash_id text unique;

-- The photos read policy checks blocks; signed-out visitors need SELECT on
-- it for the catalog to load. RLS (auth.uid() = blocker_id) shows them nothing.
grant select on public.blocks to anon;
