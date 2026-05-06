-- 匿名/ログインユーザーごとのウォッチ商品ID一覧（通知基盤の土台）。
create table if not exists public.user_watch_products (
  user_id uuid primary key references auth.users (id) on delete cascade,
  product_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.user_watch_products enable row level security;

drop policy if exists "user_watch_products_select_own" on public.user_watch_products;
create policy "user_watch_products_select_own" on public.user_watch_products
  for select using (auth.uid() = user_id);

drop policy if exists "user_watch_products_insert_own" on public.user_watch_products;
create policy "user_watch_products_insert_own" on public.user_watch_products
  for insert with check (auth.uid() = user_id);

drop policy if exists "user_watch_products_update_own" on public.user_watch_products;
create policy "user_watch_products_update_own" on public.user_watch_products
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_watch_products_delete_own" on public.user_watch_products;
create policy "user_watch_products_delete_own" on public.user_watch_products
  for delete using (auth.uid() = user_id);
