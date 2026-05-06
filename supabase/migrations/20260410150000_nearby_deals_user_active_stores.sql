-- 周辺安値（商品詳細・店舗詳細）と行動圏 ID のクラウド同期（匿名 auth + RLS）

-- 候補店として参照する店（既存 phase2 に無い ID）
insert into public.stores (id, chain_id, name, municipality, status) values
  ('sg1', 'maxvalu', 'マックスバリュ 糸満店', '糸満市', 'active'),
  ('sg2', 'the_big', 'ザ・ビッグ 豊見城店', '豊見城市', 'active')
on conflict (id) do update set
  chain_id = excluded.chain_id,
  name = excluded.name,
  municipality = excluded.municipality,
  status = excluded.status;

create table if not exists public.product_nearby_deals (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products (id) on delete cascade,
  suggested_store_id text references public.stores (id) on delete set null,
  suggested_store_name text not null,
  suggested_price int not null,
  base_store_id text references public.stores (id) on delete set null,
  base_store_name text not null,
  base_price int not null,
  distance_km double precision not null
);

create index if not exists product_nearby_deals_product_id_idx
  on public.product_nearby_deals (product_id);
create index if not exists product_nearby_deals_suggested_store_idx
  on public.product_nearby_deals (suggested_store_id);
create index if not exists product_nearby_deals_base_store_idx
  on public.product_nearby_deals (base_store_id);

alter table public.product_nearby_deals enable row level security;

drop policy if exists "product_nearby_deals_select_all" on public.product_nearby_deals;
create policy "product_nearby_deals_select_all" on public.product_nearby_deals
  for select using (true);

delete from public.product_nearby_deals where product_id in ('p1', 'p2');

insert into public.product_nearby_deals (
  product_id,
  suggested_store_id,
  suggested_store_name,
  suggested_price,
  base_store_id,
  base_store_name,
  base_price,
  distance_km
) values
  ('p1', 'sg1', 'マックスバリュ 糸満店', 178, 's1', 'サンエー 那覇店', 198, 3.2),
  ('p2', 's4', 'ユニオン 与那原店', 248, 's2', 'イオン 浦添店', 268, 4.1);

-- 匿名ユーザーが自分の行だけ upsert/select（アプリは signInAnonymously 後に利用）
create table if not exists public.user_active_stores (
  user_id uuid primary key references auth.users (id) on delete cascade,
  store_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.user_active_stores enable row level security;

drop policy if exists "user_active_stores_select_own" on public.user_active_stores;
create policy "user_active_stores_select_own" on public.user_active_stores
  for select using (auth.uid() = user_id);

drop policy if exists "user_active_stores_insert_own" on public.user_active_stores;
create policy "user_active_stores_insert_own" on public.user_active_stores
  for insert with check (auth.uid() = user_id);

drop policy if exists "user_active_stores_update_own" on public.user_active_stores;
create policy "user_active_stores_update_own" on public.user_active_stores
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "user_active_stores_delete_own" on public.user_active_stores;
create policy "user_active_stores_delete_own" on public.user_active_stores
  for delete using (auth.uid() = user_id);
