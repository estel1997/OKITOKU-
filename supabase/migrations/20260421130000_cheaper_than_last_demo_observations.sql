-- ホーム「前回より安い」デモ用: 直近観測をチラシより高くする行を追加。
-- 既存シード: チラシ 牛乳 178 円・卵 248 円。ここで p1 直近 198、p2 直近 268 とし、いずれもチラシの方が安い件数になる想定。
insert into public.product_price_observations (product_id, store_id, price_yen, observed_at, source) values
  ('p1', 's1', 198, '2026-04-21T12:00:00+09', 'manual'),
  ('p2', 's1', 268, '2026-04-22T10:00:00+09', 'manual');
