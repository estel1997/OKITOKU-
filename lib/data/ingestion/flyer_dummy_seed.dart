import '../../domain/entities/flyer_offer.dart';

/// 本番前の UI・結合テスト用（各大手様許諾後は Supabase / 取り込みパイプラインへ置き換え）
const List<FlyerOffer> kDummyFlyerOffers = [
  FlyerOffer(
    id: 'flyer_dummy_1',
    productNameOrSku: '牛乳 1L（チラシ）',
    chainId: 'san_a',
    priceYen: 178,
    ingestionSource: FlyerIngestionSource.dummy,
    sourceRef: 'dummy://seed/1',
  ),
  FlyerOffer(
    id: 'flyer_dummy_2',
    productNameOrSku: '卵 10個入（特売）',
    chainId: 'aeon',
    priceYen: 248,
    ingestionSource: FlyerIngestionSource.dummy,
    sourceRef: 'dummy://seed/2',
  ),
];
