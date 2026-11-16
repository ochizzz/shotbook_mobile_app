-- The catalog is Unsplash-only: the earlier Flickr/Openverse photos are
-- hidden (kept, so saved links don't break; set is_hidden = false to restore).
update public.photos set is_hidden = true
where source_type = 'curated' and unsplash_id is null;
