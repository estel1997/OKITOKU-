import '../../domain/entities/flyer_offer.dart';

/// チラシ特売一覧の参照（INSERT は Edge Function / 管理画面を想定）
abstract class FlyerOfferReadRepository {
  Future<List<FlyerOffer>> listRecent({int limit = 50});
}
