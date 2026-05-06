-- Expose safe RPCs for retention days (1..180 clamp).
create or replace function public.get_price_watch_retention_days()
returns int
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (
      select least(greatest(value_text::int, 1), 180)
      from public.app_runtime_settings
      where key = 'price_watch_retention_days'
        and value_text ~ '^[0-9]+$'
      limit 1
    ),
    90
  );
$$;

create or replace function public.set_price_watch_retention_days(p_days int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized int;
begin
  normalized := least(greatest(coalesce(p_days, 90), 1), 180);

  insert into public.app_runtime_settings (key, value_text)
  values ('price_watch_retention_days', normalized::text)
  on conflict (key) do update
  set value_text = excluded.value_text,
      updated_at = now();

  return normalized;
end;
$$;

grant execute on function public.get_price_watch_retention_days() to anon, authenticated;
grant execute on function public.set_price_watch_retention_days(int) to anon, authenticated;
