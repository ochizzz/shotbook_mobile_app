-- Photos from the Unsplash API: attribution and download tracking
-- follow the Unsplash API guidelines (images are hotlinked, never copied).
alter table public.photos add column if not exists unsplash_id text unique;
