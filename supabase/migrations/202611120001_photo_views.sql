-- View counter instead of likes: every open of a photo's detail page counts.
alter table public.photos
  add column if not exists views_count integer not null default 0;

-- Authors may update their own photos, but must not be able to edit the
-- counter directly. Only record_photo_view() may change it.
create or replace function public.guard_photo_views_count()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.views_count is distinct from old.views_count
     and coalesce(current_setting('shotbook.view_bump', true), '') <> 'on' then
    new.views_count := old.views_count;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_photo_views_count on public.photos;
create trigger guard_photo_views_count
  before update on public.photos
  for each row execute function public.guard_photo_views_count();

create or replace function public.record_photo_view(target_photo uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  result integer;
begin
  perform set_config('shotbook.view_bump', 'on', true);
  update public.photos
     set views_count = views_count + 1
   where id = target_photo
  returning views_count into result;
  perform set_config('shotbook.view_bump', 'off', true);
  return coalesce(result, 0);
end;
$$;

revoke all on function public.record_photo_view(uuid) from public;
grant execute on function public.record_photo_view(uuid) to anon, authenticated;
