-- チラシ特売の正規化行（アプリ [FlyerOffer] / 取り込みパイプラインと対応）
create table if not exists public.flyer_offers (
  id uuid primary key default gen_random_uuid(),
  product_name text not null,
  chain_id text,
  store_id text,
  price_yen int,
  valid_from timestamptz,
  valid_to timestamptz,
  ingestion_source text not null,
  source_ref text,
  created_at timestamptz not null default now()
);

create index if not exists flyer_offers_created_at_idx on public.flyer_offers (created_at desc);

alter table public.flyer_offers enable row level security;

drop policy if exists "flyer_offers_select_all" on public.flyer_offers;
create policy "flyer_offers_select_all" on public.flyer_offers
  for select using (true);

-- サンプル（許諾前のダミーと同等）
insert into public.flyer_offers (id, product_name, chain_id, price_yen, ingestion_source, source_ref)
values
  ('00000000-0000-4000-8000-000000000001', '牛乳 1L（チラシ）', 'san_a', 178, 'dummy', 'seed://1'),
  ('00000000-0000-4000-8000-000000000002', '卵 10個入（特売）', 'aeon', 248, 'dummy', 'seed://2')
on conflict (id) do update set
  product_name = excluded.product_name,
  chain_id = excluded.chain_id,
  price_yen = excluded.price_yen,
  ingestion_source = excluded.ingestion_source,
  source_ref = excluded.source_ref;
