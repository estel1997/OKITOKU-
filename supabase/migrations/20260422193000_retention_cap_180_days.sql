-- Cap retention days to 180 (about 6 months).
create or replace function public.cleanup_old_price_watch_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  retention_days int := 90;
  raw_value text;
begin
  select value_text
    into raw_value
    from public.app_runtime_settings
   where key = 'price_watch_retention_days';

  if raw_value is not null and raw_value ~ '^[0-9]+$' then
    retention_days := raw_value::int;
  end if;

  -- Keep policy in safe bounds: minimum 1 day, maximum 180 days.
  retention_days := greatest(1, least(retention_days, 180));

  delete from public.product_price_observations
  where observed_at < now() - make_interval(days => retention_days);

  delete from public.flyer_offers
  where coalesce(valid_to, created_at) < now() - make_interval(days => retention_days);
end;
$$;

-- Normalize currently configured value to max 180.
update public.app_runtime_settings
set value_text = least(greatest(value_text::int, 1), 180)::text,
    updated_at = now()
where key = 'price_watch_retention_days'
  and value_text ~ '^[0-9]+$';

-- If value is non-numeric, return to default.
update public.app_runtime_settings
set value_text = '90',
    updated_at = now()
where key = 'price_watch_retention_days'
  and value_text !~ '^[0-9]+$';
