import '../../domain/entities/flyer_offer.dart';
import '../ingestion/flyer_dummy_seed.dart';
import '../repositories/flyer_offer_read_repository.dart';

class LocalFlyerOfferRepository implements FlyerOfferReadRepository {
  @override
  Future<List<FlyerOffer>> listRecent({int limit = 50}) async {
    await Future<void>.delayed(Duration.zero);
    return kDummyFlyerOffers.take(limit).toList();
  }
}
