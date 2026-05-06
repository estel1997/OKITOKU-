import '../../domain/entities/store.dart';
import '../models/product_category.dart';

export '../models/product_category.dart';

/// MVP 用ダミー。後から Supabase へ差し替え。
/// 行動圏の店舗数は [StoreRepository] と一致させる（ホームの件数と一覧をズラさない）。
class HomeSummaryDummy {
  const HomeSummaryDummy({
    required this.dealCountToday,
    required this.cheaperThanLastCount,
  });

  final int dealCountToday;
  final int cheaperThanLastCount;
}

const HomeSummaryDummy kHomeSummary = HomeSummaryDummy(
  dealCountToday: 3,
  cheaperThanLastCount: 1,
);

/// ローカルシード店の営業時間（Supabase 未接続時の表示用デモ）。
const String kLocalDemoOpeningHours =
    '月〜日 9:00–22:00\n※ローカルデモ用の代表表記です。実店舗の公式情報ではありません。';

class DummyProduct {
  const DummyProduct({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final ProductCategory category;
}

const List<DummyProduct> kDummyProducts = [
  DummyProduct(id: 'p1', name: '牛乳 1L', category: ProductCategory.dairy),
  DummyProduct(id: 'p2', name: '卵 10個入', category: ProductCategory.eggs),
  DummyProduct(id: 'p3', name: '食パン 6枚', category: ProductCategory.bread),
];

class DummyStore {
  const DummyStore({
    required this.id,
    required this.name,
    required this.chainId,
    this.openingHours = kLocalDemoOpeningHours,
  });

  final String id;
  final String name;
  final String chainId;
  final String? openingHours;
}

/// 仕様の初期チェーンに合わせたシード（4 店 = ホーム「行動圏の店」と一致）。
const List<DummyStore> kDummyStores = [
  DummyStore(id: 's1', name: 'サンエー 那覇店', chainId: 'san_a'),
  DummyStore(id: 's2', name: 'イオン 浦添店', chainId: 'aeon'),
  DummyStore(id: 's3', name: 'かねひで 具志川店', chainId: 'kanehide'),
  DummyStore(id: 's4', name: 'ユニオン 与那原店', chainId: 'union'),
];

/// 市区町村ごとのスーパー候補（行動圏の店にチェックで追加）。未登録の市区町村は空。
const Map<String, List<Store>> kStoresByMunicipality = {
  '那覇市': [
    Store(
      id: 's1',
      name: 'サンエー 那覇店',
      chainId: 'san_a',
      openingHours: kLocalDemoOpeningHours,
    ),
    Store(
      id: 'kanehide_naha',
      name: 'かねひで 那覇メインプレイス店',
      chainId: 'kanehide',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '宜野湾市': [
    Store(
      id: 'san_ginowan',
      name: 'サンエー 宜野湾店',
      chainId: 'san_a',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '浦添市': [
    Store(
      id: 's2',
      name: 'イオン 浦添店',
      chainId: 'aeon',
      openingHours: kLocalDemoOpeningHours,
    ),
    Store(
      id: 'aeon_urasoe',
      name: 'イオン 浦添ショッピングセンター',
      chainId: 'aeon',
      openingHours: kLocalDemoOpeningHours,
    ),
    Store(
      id: 'the_big_urasoe',
      name: 'ザ・ビッグ 浦添店',
      chainId: 'the_big',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  'うるま市': [
    Store(
      id: 's3',
      name: 'かねひで 具志川店',
      chainId: 'kanehide',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '与那原町': [
    Store(
      id: 's4',
      name: 'ユニオン 与那原店',
      chainId: 'union',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '糸満市': [
    Store(
      id: 'sg1',
      name: 'マックスバリュ 糸満店',
      chainId: 'maxvalu',
      openingHours: kLocalDemoOpeningHours,
    ),
    Store(
      id: 'union_itoman',
      name: 'ユニオン 糸満店',
      chainId: 'union',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '名護市': [
    Store(
      id: 'maxvalu_nago',
      name: 'マックスバリュ 名護店',
      chainId: 'maxvalu',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
  '豊見城市': [
    Store(
      id: 'sg2',
      name: 'ザ・ビッグ 豊見城店',
      chainId: 'the_big',
      openingHours: kLocalDemoOpeningHours,
    ),
  ],
};

List<Store> storesForMunicipality(String municipalityName) {
  return kStoresByMunicipality[municipalityName] ?? const [];
}
