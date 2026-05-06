-- Push通知基盤（FCM/APNs 送信前の土台）。
-- 1) ユーザーごとの端末トークン保存
-- 2) 「前回より安い」通知イベントのキュー（重複防止付き）

create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null,
  token text not null unique,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists user_push_tokens_user_platform_token_uidx
  on public.user_push_tokens (user_id, platform, token);

alter table public.user_push_tokens enable row level security;

drop policy if exists "user_push_tokens_select_own" on public.user_push_tokens;
create policy "user_push_tokens_select_own" on public.user_push_tokens
  for select using (auth.uid() = user_id);

drop policy if exists "user_push_tokens_insert_own" on public.user_push_tokens;
create policy "user_push_tokens_insert_own" on public.user_push_tokens
  for insert with check (auth.uid() = user_id);

drop policy if exists "user_push_tokens_update_own" on public.user_push_tokens;
create policy "user_push_tokens_update_own" on public.user_push_tokens
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_push_tokens_delete_own" on public.user_push_tokens;
create policy "user_push_tokens_delete_own" on public.user_push_tokens
  for delete using (auth.uid() = user_id);

create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id text not null references public.products (id) on delete cascade,
  flyer_offer_id uuid references public.flyer_offers (id) on delete set null,
  observation_id uuid references public.product_price_observations (id) on delete set null,
  savings_yen int not null check (savings_yen > 0),
  status text not null default 'queued',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  delivered_at timestamptz
);

create index if not exists notification_events_user_created_idx
  on public.notification_events (user_id, created_at desc);

create unique index if not exists notification_events_dedup_uidx
  on public.notification_events (user_id, product_id, flyer_offer_id, observation_id);

alter table public.notification_events enable row level security;

drop policy if exists "notification_events_select_own" on public.notification_events;
create policy "notification_events_select_own" on public.notification_events
  for select using (auth.uid() = user_id);
