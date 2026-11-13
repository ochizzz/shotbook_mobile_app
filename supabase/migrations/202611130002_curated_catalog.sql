-- The curated catalog: 100 Creative Commons photos from Flickr (via Openverse)
-- with smartphone recipes in Russian and English. The rows live in
-- supabase/seed/curated_catalog.json (same data as the app's bundled
-- seed_photo_references.dart) and are fetched with the http extension.
-- Re-running is safe: rows are matched by legacy_id and updated in place.

create extension if not exists http with schema extensions;

with source as (
  select content::jsonb as rows
    from extensions.http_get(
      'https://raw.githubusercontent.com/ochizzz/shotbook_mobile_app/claude/inspiring-ptolemy-isdugq/supabase/seed/curated_catalog.json'
    )
),
catalog as (
  select r.*
    from source,
         jsonb_to_recordset(source.rows) as r(
           legacy_id text, title text, description text, image_url text,
           thumb_url text, source_page text, credit text, creator_url text,
           license text, license_url text, category text, source_type text,
           device_id text, device text, camera text, focal_length text,
           iso text, shutter_speed text, aperture text, white_balance text,
           exposure_compensation text, pose_data jsonb, editing_data jsonb,
           aspect_ratio real, translations jsonb, sort_order integer
         )
),
retired as (
  -- The old Wikimedia catalog (paintings, archive photos) is retired.
  delete from public.photos p
   where p.source_type = 'curated'
     and (p.legacy_id is null
          or p.legacy_id not in (select legacy_id from catalog))
)
insert into public.photos (
  legacy_id, title, description, image_url, thumb_url, source_page, credit,
  creator_url, license, license_url, category, source_type, device_id, device,
  camera, focal_length, iso, shutter_speed, aperture, white_balance,
  exposure_compensation, pose_data, editing_data, aspect_ratio, translations,
  sort_order
)
select
  legacy_id, title, description, image_url, thumb_url, source_page, credit,
  creator_url, license, license_url, category, 'curated', device_id, device,
  camera, focal_length, iso, shutter_speed, aperture, white_balance,
  exposure_compensation, pose_data, editing_data, aspect_ratio, translations,
  sort_order
from catalog
on conflict (legacy_id) do update set
  title = excluded.title, description = excluded.description,
  image_url = excluded.image_url, thumb_url = excluded.thumb_url,
  source_page = excluded.source_page, credit = excluded.credit,
  creator_url = excluded.creator_url, license = excluded.license,
  license_url = excluded.license_url, category = excluded.category,
  device_id = excluded.device_id, device = excluded.device,
  camera = excluded.camera, focal_length = excluded.focal_length,
  iso = excluded.iso, shutter_speed = excluded.shutter_speed,
  aperture = excluded.aperture, white_balance = excluded.white_balance,
  exposure_compensation = excluded.exposure_compensation,
  pose_data = excluded.pose_data, editing_data = excluded.editing_data,
  aspect_ratio = excluded.aspect_ratio, translations = excluded.translations,
  sort_order = excluded.sort_order;
