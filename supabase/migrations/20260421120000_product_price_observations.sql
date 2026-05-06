-- 商品の観測価格（店舗・日時）。将来「前回より安い」検知・ウォッチ通知の土台。
create table if not exists public.product_price_observations (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products (id) on delete cascade,
  store_id text references public.stores (id),
  price_yen int not null check (price_yen >= 0),
  observed_at timestamptz not null default now(),
  source text not null default 'manual'
);

create index if not exists product_price_observations_product_observed_idx
  on public.product_price_observations (product_id, observed_at desc);

alter table public.product_price_observations enable row level security;

drop policy if exists "product_price_observations_select_all" on public.product_price_observations;
create policy "product_price_observations_select_all" on public.product_price_observations
  for select using (true);

-- デモ用（マイグレーション適用後すぐ UI で確認可能）
insert into public.product_price_observations (product_id, store_id, price_yen, observed_at, source) values
  ('p1', 's1', 198, '2026-04-01T10:00:00+09', 'flyer'),
  ('p1', 's1', 188, '2026-04-08T15:00:00+09', 'flyer'),
  ('p1', 's2', 178, '2026-04-18T09:00:00+09', 'flyer'),
  ('p2', 's1', 268, '2026-04-05T10:00:00+09', 'flyer'),
  ('p2', 's4', 248, '2026-04-17T11:00:00+09', 'flyer'),
  ('p3', 's2', 158, '2026-04-10T12:00:00+09', 'flyer'),
  ('p3', 's2', 148, '2026-04-19T08:00:00+09', 'flyer');
