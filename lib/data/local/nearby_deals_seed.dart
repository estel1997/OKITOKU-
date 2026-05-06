import '../../domain/entities/nearby_deal.dart';

/// フェーズ2: 将来は `GET /products/{id}/nearby-deals` / Supabase ビューに差し替え。
List<NearbyDeal> seededNearbyDealsFor(String productId) {
  switch (productId) {
    case 'p1':
      return const [
        NearbyDeal(
          productId: 'p1',
          suggestedStoreName: 'マックスバリュ 糸満店',
          suggestedPrice: 178,
          baseStoreName: 'サンエー 那覇店',
          basePrice: 198,
          distanceKm: 3.2,
        ),
      ];
    case 'p2':
      return const [
        NearbyDeal(
          productId: 'p2',
          suggestedStoreName: 'ユニオン 与那原店',
          suggestedPrice: 248,
          baseStoreName: 'イオン 浦添店',
          basePrice: 268,
          distanceKm: 4.1,
        ),
      ];
    default:
      return const [];
  }
}
