-- フェーズ2: 最小スキーマ（店舗・商品）。匿名 read 用ポリシー付き。
-- Supabase SQL Editor から実行するか、`supabase db push` で適用。

create table if not exists public.stores (
  id text primary key,
  chain_id text not null,
  name text not null,
  municipality text,
  status text not null default 'active'
);

create table if not exists public.products (
  id text primary key,
  canonical_name text not null,
  category text not null
);

alter table public.stores enable row level security;
alter table public.products enable row level security;

drop policy if exists "stores_select_all" on public.stores;
create policy "stores_select_all" on public.stores
  for select using (true);

drop policy if exists "products_select_all" on public.products;
create policy "products_select_all" on public.products
  for select using (true);

insert into public.stores (id, chain_id, name, municipality, status) values
  ('s1', 'san_a', 'サンエー 那覇店', '那覇市', 'active'),
  ('s2', 'aeon', 'イオン 浦添店', '浦添市', 'active'),
  ('s3', 'kanehide', 'かねひで 具志川店', 'うるま市', 'active'),
  ('s4', 'union', 'ユニオン 与那原店', '島尻郡与那原町', 'active')
on conflict (id) do update set
  chain_id = excluded.chain_id,
  name = excluded.name,
  municipality = excluded.municipality,
  status = excluded.status;

insert into public.products (id, canonical_name, category) values
  ('p1', '牛乳 1L', 'dairy'),
  ('p2', '卵 10個入', 'eggs'),
  ('p3', '食パン 6枚', 'bread')
on conflict (id) do update set
  canonical_name = excluded.canonical_name,
  category = excluded.category;
