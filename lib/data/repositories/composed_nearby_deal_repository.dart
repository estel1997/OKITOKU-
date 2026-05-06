import '../../domain/entities/nearby_deal.dart';
import 'nearby_deal_repository.dart';

/// リモート優先。失敗時または空のときはローカルシードにフォールバック（オフライン開発用）。
class ComposedNearbyDealRepository implements NearbyDealRepository {
  ComposedNearbyDealRepository({
    required NearbyDealRepository remote,
    required NearbyDealRepository local,
  })  : _remote = remote,
        _local = local;

  final NearbyDealRepository _remote;
  final NearbyDealRepository _local;

  @override
  Future<List<NearbyDeal>> forProduct(String productId) async {
    try {
      final r = await _remote.forProduct(productId);
      if (r.isNotEmpty) {
        return r;
      }
    } catch (_) {}
    return _local.forProduct(productId);
  }

  @override
  Future<List<NearbyDeal>> forStore(String storeId) async {
    try {
      final r = await _remote.forStore(storeId);
      if (r.isNotEmpty) {
        return r;
      }
    } catch (_) {}
    return _local.forStore(storeId);
  }
}
