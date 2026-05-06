-- 市区町村マスタ（アプリの kOkinawaMunicipalitySections と同一キー）と stores の整合。
-- 適用: Supabase SQL Editor または `supabase db push`

-- ---------------------------------------------------------------------------
-- 市区町村マスタ（41 件）
-- ---------------------------------------------------------------------------
create table if not exists public.municipalities (
  name text primary key,
  region text not null,
  sort_order int not null default 0
);

create index if not exists municipalities_region_sort_idx
  on public.municipalities (region, sort_order);

insert into public.municipalities (name, region, sort_order) values
  ('那覇市', '市', 0),
  ('宜野湾市', '市', 1),
  ('石垣市', '市', 2),
  ('浦添市', '市', 3),
  ('名護市', '市', 4),
  ('糸満市', '市', 5),
  ('沖縄市', '市', 6),
  ('豊見城市', '市', 7),
  ('うるま市', '市', 8),
  ('宮古島市', '市', 9),
  ('南城市', '市', 10),
  ('国頭村', '国頭郡', 11),
  ('大宜味村', '国頭郡', 12),
  ('東村', '国頭郡', 13),
  ('今帰仁村', '国頭郡', 14),
  ('本部町', '国頭郡', 15),
  ('恩納村', '国頭郡', 16),
  ('宜野座村', '国頭郡', 17),
  ('金武町', '国頭郡', 18),
  ('伊江村', '国頭郡', 19),
  ('読谷村', '中頭郡', 20),
  ('嘉手納町', '中頭郡', 21),
  ('北谷町', '中頭郡', 22),
  ('北中城村', '中頭郡', 23),
  ('中城村', '中頭郡', 24),
  ('西原町', '中頭郡', 25),
  ('与那原町', '島尻郡', 26),
  ('南風原町', '島尻郡', 27),
  ('渡嘉敷村', '島尻郡', 28),
  ('座間味村', '島尻郡', 29),
  ('粟国村', '島尻郡', 30),
  ('渡名喜村', '島尻郡', 31),
  ('南大東村', '島尻郡', 32),
  ('北大東村', '島尻郡', 33),
  ('伊平屋村', '島尻郡', 34),
  ('伊是名村', '島尻郡', 35),
  ('久米島町', '島尻郡', 36),
  ('八重瀬町', '島尻郡', 37),
  ('多良間村', '宮古郡', 38),
  ('竹富町', '八重山郡', 39),
  ('与那国町', '八重山郡', 40)
on conflict (name) do update set
  region = excluded.region,
  sort_order = excluded.sort_order;

alter table public.municipalities enable row level security;

drop policy if exists "municipalities_select_all" on public.municipalities;
create policy "municipalities_select_all" on public.municipalities
  for select using (true);

-- ---------------------------------------------------------------------------
-- 既存店舗の市区町村名をアプリと一致（与那原町）
-- ---------------------------------------------------------------------------
update public.stores
set municipality = '与那原町'
where id = 's4';

-- ---------------------------------------------------------------------------
-- 追加店舗（市区町村別マスタと UI ダミーに揃えたシード）
-- ---------------------------------------------------------------------------
insert into public.stores (id, chain_id, name, municipality, status) values
  ('kanehide_naha', 'kanehide', 'かねひで 那覇メインプレイス店', '那覇市', 'active'),
  ('san_ginowan', 'san_a', 'サンエー 宜野湾店', '宜野湾市', 'active'),
  ('aeon_urasoe', 'aeon', 'イオン 浦添ショッピングセンター', '浦添市', 'active'),
  ('the_big_urasoe', 'the_big', 'ザ・ビッグ 浦添店', '浦添市', 'active'),
  ('sg1', 'maxvalu', 'マックスバリュ 糸満店', '糸満市', 'active'),
  ('union_itoman', 'union', 'ユニオン 糸満店', '糸満市', 'active'),
  ('maxvalu_nago', 'maxvalu', 'マックスバリュ 名護店', '名護市', 'active'),
  ('sg2', 'the_big', 'ザ・ビッグ 豊見城店', '豊見城市', 'active')
on conflict (id) do update set
  chain_id = excluded.chain_id,
  name = excluded.name,
  municipality = excluded.municipality,
  status = excluded.status;

-- ---------------------------------------------------------------------------
-- 参照整合: stores.municipality → municipalities.name
-- ---------------------------------------------------------------------------
alter table public.stores
  drop constraint if exists stores_municipality_fkey;

alter table public.stores
  add constraint stores_municipality_fkey
  foreign key (municipality) references public.municipalities(name);
