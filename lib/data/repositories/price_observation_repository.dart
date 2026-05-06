import '../../domain/entities/price_observation.dart';

abstract class PriceObservationRepository {
  Future<List<PriceObservation>> listForProduct(String productId);

  /// ホーム集計など用。新しい観測から最大 [limit] 件。
  Future<List<PriceObservation>> listRecent({int limit = 500});
}
