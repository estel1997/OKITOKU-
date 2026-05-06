import '../entities/flyer_offer.dart';
import 'today_shopping_state.dart';

/// 「店舗移動を少なく」設定に応じたルート案テキスト（MVP・ルールベース）
String buildShoppingRouteHint({
  required TodayShoppingState state,
  required List<FlyerOffer> todayFlyers,
}) {
  if (!state.minimizeStoreHops) {
    return '店舗回数を抑えない設定です。チラシの掲載順や近い店から回るとよいです。'
        'お買い得でない商品が混ざると合計は上がることがあります。';
  }

  final ids = state.flyerQtyById.entries.where((e) => e.value > 0).map((e) => e.key).toSet();
  if (ids.isEmpty) {
    return 'チラシ商品が未選択です。チェックと個数を入れてから登録してください。';
  }

  final offers = todayFlyers.where((o) => ids.contains(o.id)).toList();
  final chains = offers.map((o) => o.chainId).whereType<String>().where((c) => c.isNotEmpty).toSet();

  if (chains.isEmpty) {
    return '選択したチラシ行にチェーン情報がありません。店舗の絞り込み案は出せませんが、'
        '近い店の順に回ると移動は抑えやすいです。';
  }
  if (chains.length == 1) {
    return '1店舗（同一チェーン中心）に集約できる候補です。待ち時間と移動を抑えやすく、'
        '一部お買い得でない商品をまとめると少し高くなる場合があります。';
  }
  if (chains.length == 2) {
    final a = chains.elementAt(0);
    final b = chains.elementAt(1);
    return '2店舗経由の候補です（例: $a → $b）。一括購入より時間は短くなる一方、'
        '合計がやや高くなることがあります。';
  }
  return '${chains.length} チェーンにまたがります。回数を減らすには、'
      'チラシの一部を別日に分けるか、近い店舗のチラシに寄せるとよいです。';
}
