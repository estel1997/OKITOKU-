import 'shopping_transport.dart';

/// 「今日の買い物」の合計見積もり（案）
class ShoppingTripEstimate {
  const ShoppingTripEstimate({
    required this.flyerSubtotalYen,
    required this.catalogItemCount,
    required this.catalogQtyUnits,
    required this.transport,
    required this.transportYen,
    required this.transportNote,
    required this.grandTotalYen,
    required this.homeLocationNote,
    required this.freeformLineCount,
    required this.routeHint,
  });

  final int flyerSubtotalYen;

  /// カタログでチェックした品目数（ユニーク ID）
  final int catalogItemCount;

  /// カタログの合計個数
  final int catalogQtyUnits;
  final ShoppingTransport transport;
  final int transportYen;
  final String transportNote;
  final int grandTotalYen;
  final String homeLocationNote;
  final int freeformLineCount;

  /// 店舗回数を抑える等のルート案（MVP）
  final String routeHint;
}
