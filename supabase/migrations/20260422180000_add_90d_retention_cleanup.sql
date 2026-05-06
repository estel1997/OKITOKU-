-- Keep ingestion history for 90 days, then auto-delete daily.
create extension if not exists pg_cron;

create or replace function public.cleanup_old_price_watch_data(retention_days int default 90)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
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
    $$select public.cleanup_old_price_watch_data(90);$$
  );
end $cron$;

-- Run once at migration time to enforce policy immediately.
select public.cleanup_old_price_watch_data(90);
