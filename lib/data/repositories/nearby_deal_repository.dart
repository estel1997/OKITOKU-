import '../../domain/entities/nearby_deal.dart';
import '../local/nearby_deals_seed.dart';

abstract class NearbyDealRepository {
  Future<List<NearbyDeal>> forProduct(String productId);

  /// 当該店が「より安い候補」または「比較元」になっている行。
  Future<List<NearbyDeal>> forStore(String storeId);
}

class LocalNearbyDealRepository implements NearbyDealRepository {
  @override
  Future<List<NearbyDeal>> forProduct(String productId) async {
    await Future<void>.delayed(Duration.zero);
    return seededNearbyDealsFor(productId);
  }

  @override
  Future<List<NearbyDeal>> forStore(String storeId) async {
    await Future<void>.delayed(Duration.zero);
    return const [];
  }
}
