import '../../domain/entities/price_observation.dart';
import 'price_observation_repository.dart';

/// リモート優先。空または失敗時はローカルシード（オフライン・未マイグレーション用）。
class ComposedPriceObservationRepository implements PriceObservationRepository {
  ComposedPriceObservationRepository({
    required PriceObservationRepository remote,
    required PriceObservationRepository local,
  })  : _remote = remote,
        _local = local;

  final PriceObservationRepository _remote;
  final PriceObservationRepository _local;

  @override
  Future<List<PriceObservation>> listForProduct(String productId) async {
    try {
      final r = await _remote.listForProduct(productId);
      if (r.isNotEmpty) {
        return r;
      }
    } catch (_) {}
    return _local.listForProduct(productId);
  }

  @override
  Future<List<PriceObservation>> listRecent({int limit = 500}) async {
    try {
      final r = await _remote.listRecent(limit: limit);
      if (r.isNotEmpty) {
        return r;
      }
    } catch (_) {}
    return _local.listRecent(limit: limit);
  }
}
