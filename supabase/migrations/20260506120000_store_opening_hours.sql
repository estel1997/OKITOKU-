-- 店舗の営業時間（表示用テキスト。改行可）。アプリの店舗詳細で利用。

alter table public.stores
  add column if not exists opening_hours text;

comment on column public.stores.opening_hours is
  '営業時間・定休日などの自由記述。公式サイトの表記に合わせて運用で更新してください。';

-- シード: デモ用（実店舗の公式情報ではありません）
update public.stores
set opening_hours = e'月〜日 9:00–22:00\n※デモデータです。実際の営業・定休は店舗公式情報をご確認ください。'
where id in (
  's1',
  's2',
  's3',
  's4',
  'kanehide_naha',
  'san_ginowan',
  'aeon_urasoe',
  'the_big_urasoe',
  'sg1',
  'union_itoman',
  'maxvalu_nago',
  'sg2'
);
