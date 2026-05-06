-- Ingestion idempotency constraints to prevent duplicate records.
with dedup as (
  select
    ctid,
    row_number() over (
      partition by ingestion_source, source_ref
      order by created_at desc, id desc
    ) as rn
  from public.flyer_offers
  where source_ref is not null
)
delete from public.flyer_offers f
using dedup d
where f.ctid = d.ctid
  and d.rn > 1;

create unique index if not exists flyer_offers_ingestion_source_ref_uniq
  on public.flyer_offers (ingestion_source, source_ref)
  where source_ref is not null;

with dedup as (
  select
    ctid,
    row_number() over (
      partition by product_id, store_id, price_yen, observed_at, source
      order by id desc
    ) as rn
  from public.product_price_observations
)
delete from public.product_price_observations p
using dedup d
where p.ctid = d.ctid
  and d.rn > 1;

create unique index if not exists product_price_observations_dedup_uniq
  on public.product_price_observations (product_id, store_id, price_yen, observed_at, source);
