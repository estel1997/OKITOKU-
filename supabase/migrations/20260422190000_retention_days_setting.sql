-- Make retention days configurable without editing function code.
create table if not exists public.app_runtime_settings (
  key text primary key,
  value_text text not null,
  updated_at timestamptz not null default now()
);

insert into public.app_runtime_settings (key, value_text)
values ('price_watch_retention_days', '90')
on conflict (key) do nothing;

-- Remove old overload with default argument to avoid ambiguous calls.
drop function if exists public.cleanup_old_price_watch_data(int);

create or replace function public.cleanup_old_price_watch_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  retention_days int := 90;
begin
  select coalesce(nullif(value_text, '')::int, 90)
    into retention_days
    from public.app_runtime_settings
   where key = 'price_watch_retention_days';

  delete from public.product_price_observations
  where observed_at < now() - make_interval(days => retention_days);

  delete from public.flyer_offers
  where coalesce(valid_to, created_at) < now() - make_interval(days => retention_days);
end;
$$;

do $cron$
declare
  existing_job_id bigint;
begin
  select jobid
    into existing_job_id
    from cron.job
   where jobname = 'cleanup_old_price_watch_data_daily'
   limit 1;

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;

  perform cron.schedule(
    'cleanup_old_price_watch_data_daily',
    '15 3 * * *',
    $$select public.cleanup_old_price_watch_data();$$
  );
end $cron$;

-- Run once at migration time using current configured days.
select public.cleanup_old_price_watch_data();
