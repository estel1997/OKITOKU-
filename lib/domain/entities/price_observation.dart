/// 店舗・日時付きの観測価格（履歴行）。
class PriceObservation {
  const PriceObservation({
    required this.id,
    required this.productId,
    this.storeId,
    this.storeName,
    required this.priceYen,
    required this.observedAt,
    required this.source,
  });

  factory PriceObservation.fromSupabaseRow(Map<String, dynamic> m) {
    String? storeName;
    final nested = m['stores'];
    if (nested is Map) {
      storeName = nested['name'] as String?;
    }
    return PriceObservation(
      id: m['id'].toString(),
      productId: m['product_id'] as String,
      storeId: m['store_id'] as String?,
      storeName: storeName,
      priceYen: (m['price_yen'] as num).toInt(),
      observedAt: DateTime.parse(m['observed_at'].toString()),
      source: m['source'] as String? ?? 'unknown',
    );
  }

  final String id;
  final String productId;
  final String? storeId;

  /// `stores` ジョイン時のみ。無いときは [storeId] を UI で表示。
  final String? storeName;
  final int priceYen;
  final DateTime observedAt;
  final String source;
}
