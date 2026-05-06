import '../entities/catalog_product.dart';
import '../entities/flyer_offer.dart';
import '../entities/price_observation.dart';
import '../flyer/flyer_offer_valid_today.dart';

class CheaperThanLastHit {
  const CheaperThanLastHit({
    required this.product,
    required this.offer,
    required this.lastObservation,
  });

  final CatalogProduct product;
  final FlyerOffer offer;
  final PriceObservation lastObservation;

  int get savingsYen => lastObservation.priceYen - (offer.priceYen ?? 0);
}

/// チラシ行の商品名とカタログを突き合わせ（長い名前を優先）。
CatalogProduct? matchCatalogProductForFlyer(
  FlyerOffer offer,
  List<CatalogProduct> products,
) {
  CatalogProduct? best;
  for (final p in products) {
    if (!offer.productNameOrSku.contains(p.name)) {
      continue;
    }
    if (best == null || p.name.length > best.name.length) {
      best = p;
    }
  }
  return best;
}

/// 商品 ID ごとの「直近観測」（[observed_at] が最も新しい行）。
Map<String, PriceObservation> latestObservationByProductId(
  List<PriceObservation> observations,
) {
  final map = <String, PriceObservation>{};
  for (final o in observations) {
    final existing = map[o.productId];
    if (existing == null || o.observedAt.isAfter(existing.observedAt)) {
      map[o.productId] = o;
    }
  }
  return map;
}

/// 本日有効なチラシから、商品ごとに最もお得な「前回より安い」候補を返す。
List<CheaperThanLastHit> cheaperThanLastHits({
  required List<FlyerOffer> flyersValidToday,
  required List<CatalogProduct> products,
  required List<PriceObservation> observations,
}) {
  if (flyersValidToday.isEmpty || products.isEmpty || observations.isEmpty) {
    return const [];
  }
  final latestByProduct = latestObservationByProductId(observations);
  final bestByProductId = <String, CheaperThanLastHit>{};

  for (final offer in flyersValidToday) {
    final price = offer.priceYen;
    if (price == null) {
      continue;
    }
    final product = matchCatalogProductForFlyer(offer, products);
    if (product == null) {
      continue;
    }
    final last = latestByProduct[product.id];
    if (last == null || price >= last.priceYen) {
      continue;
    }
    final candidate = CheaperThanLastHit(
      product: product,
      offer: offer,
      lastObservation: last,
    );
    final existing = bestByProductId[product.id];
    if (existing == null || candidate.savingsYen > existing.savingsYen) {
      bestByProductId[product.id] = candidate;
    }
  }
  final hits = bestByProductId.values.toList()
    ..sort((a, b) => b.savingsYen.compareTo(a.savingsYen));
  return hits;
}

/// 本日有効なチラシのうち、**直近観測価格より安い**行数。
///
/// [flyers] は事前に「本日有効」で絞って渡す。
int countCheaperThanLastObservation({
  required List<FlyerOffer> flyersValidToday,
  required List<CatalogProduct> products,
  required List<PriceObservation> observations,
}) {
  if (flyersValidToday.isEmpty || products.isEmpty || observations.isEmpty) {
    return 0;
  }
  return cheaperThanLastHits(
    flyersValidToday: flyersValidToday,
    products: products,
    observations: observations,
  ).length;
}

/// [nowLocal] 基準で本日有効なチラシに絞り、上記と同じ件数を返す。
int countCheaperThanLastForHome({
  required List<FlyerOffer> allFlyers,
  required List<CatalogProduct> products,
  required List<PriceObservation> observations,
  required DateTime nowLocal,
}) {
  final validToday = allFlyers.where((o) => flyerOfferValidOnLocalDay(o, nowLocal)).toList();
  return countCheaperThanLastObservation(
    flyersValidToday: validToday,
    products: products,
    observations: observations,
  );
}
