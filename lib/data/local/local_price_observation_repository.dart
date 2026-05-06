import '../../domain/entities/price_observation.dart';
import '../repositories/price_observation_repository.dart';

/// dart-define なし／リモート失敗時のシード（`kDummyProducts` と id 整合）。
class LocalPriceObservationRepository implements PriceObservationRepository {
  static final List<PriceObservation> _p1 = [
    PriceObservation(
      id: 'local-p1-1',
      productId: 'p1',
      storeId: 's1',
      storeName: 'サンエー 那覇店',
      priceYen: 198,
      observedAt: DateTime.utc(2026, 4, 1, 1, 0),
      source: 'flyer',
    ),
    PriceObservation(
      id: 'local-p1-2',
      productId: 'p1',
      storeId: 's1',
      storeName: 'サンエー 那覇店',
      priceYen: 188,
      observedAt: DateTime.utc(2026, 4, 8, 6, 0),
      source: 'flyer',
    ),
    PriceObservation(
      id: 'local-p1-3',
      productId: 'p1',
      storeId: 's2',
      storeName: 'イオン 浦添店',
      priceYen: 178,
      observedAt: DateTime.utc(2026, 4, 18, 0, 0),
      source: 'flyer',
    ),
  ];

  static final List<PriceObservation> _p2 = [
    PriceObservation(
      id: 'local-p2-1',
      productId: 'p2',
      storeId: 's1',
      storeName: 'サンエー 那覇店',
      priceYen: 268,
      observedAt: DateTime.utc(2026, 4, 5, 1, 0),
      source: 'flyer',
    ),
    PriceObservation(
      id: 'local-p2-2',
      productId: 'p2',
      storeId: 's4',
      storeName: 'ユニオン 与那原店',
      priceYen: 248,
      observedAt: DateTime.utc(2026, 4, 17, 2, 0),
      source: 'flyer',
    ),
  ];

  static final List<PriceObservation> _p3 = [
    PriceObservation(
      id: 'local-p3-1',
      productId: 'p3',
      storeId: 's2',
      storeName: 'イオン 浦添店',
      priceYen: 158,
      observedAt: DateTime.utc(2026, 4, 10, 3, 0),
      source: 'flyer',
    ),
    PriceObservation(
      id: 'local-p3-2',
      productId: 'p3',
      storeId: 's2',
      storeName: 'イオン 浦添店',
      priceYen: 148,
      observedAt: DateTime.utc(2026, 4, 19, 23, 0),
      source: 'flyer',
    ),
  ];

  static final Map<String, List<PriceObservation>> _map = {
    'p1': _p1,
    'p2': _p2,
    'p3': _p3,
  };

  @override
  Future<List<PriceObservation>> listForProduct(String productId) async {
    await Future<void>.delayed(Duration.zero);
    final list = _map[productId];
    if (list == null) {
      return [];
    }
    return List<PriceObservation>.from(list)
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  }

  @override
  Future<List<PriceObservation>> listRecent({int limit = 500}) async {
    await Future<void>.delayed(Duration.zero);
    final all = <PriceObservation>[..._p1, ..._p2, ..._p3]
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    if (all.length > limit) {
      return all.take(limit).toList();
    }
    return all;
  }
}
