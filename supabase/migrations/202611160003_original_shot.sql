-- Real settings of the original photo (Unsplash EXIF, 35 mm equivalent
-- focal length). The app adapts them to the user's phone.
alter table public.photos add column if not exists original_shot jsonb;
