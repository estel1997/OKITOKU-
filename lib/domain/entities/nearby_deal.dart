/// 周辺店の安値提案（商品詳細用）。
class NearbyDeal {
  const NearbyDeal({
    required this.productId,
    required this.suggestedStoreName,
    required this.suggestedPrice,
    required this.baseStoreName,
    required this.basePrice,
    required this.distanceKm,
  });

  final String productId;
  final String suggestedStoreName;
  final int suggestedPrice;
  final String baseStoreName;
  final int basePrice;
  final double distanceKm;

  int get savings => basePrice - suggestedPrice;

  factory NearbyDeal.fromSupabaseRow(Map<String, dynamic> m) {
    return NearbyDeal(
      productId: m['product_id'] as String,
      suggestedStoreName: m['suggested_store_name'] as String,
      suggestedPrice: (m['suggested_price'] as num).toInt(),
      baseStoreName: m['base_store_name'] as String,
      basePrice: (m['base_price'] as num).toInt(),
      distanceKm: (m['distance_km'] as num).toDouble(),
    );
  }
}
