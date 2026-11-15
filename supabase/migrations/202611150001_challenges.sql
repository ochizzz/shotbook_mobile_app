-- Weekly challenges. The challenges themselves are defined in the app
-- (lib/features/challenges/domain/challenge.dart); a community photo joins
-- one by carrying its key. Participants = photos with that key.
-- Additive only: existing rows keep challenge_key = null.
alter table public.photos
  add column if not exists challenge_key text
    check (challenge_key is null or challenge_key ~ '^[a-z0-9-]{1,40}$');

create index if not exists photos_challenge_key_idx
  on public.photos (challenge_key, created_at desc)
  where challenge_key is not null;
