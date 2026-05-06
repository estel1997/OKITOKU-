import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/domain/entities/catalog_product.dart';
import 'package:shopping_price_watch/domain/entities/flyer_offer.dart';
import 'package:shopping_price_watch/domain/entities/price_observation.dart';
import 'package:shopping_price_watch/domain/shopping/cheaper_than_last_counter.dart';

void main() {
  test('matchCatalogProductForFlyer prefers longer canonical name', () {
    final products = [
      const CatalogProduct(id: 'p1', name: '牛乳', categoryCode: 'dairy'),
      const CatalogProduct(id: 'p1b', name: '牛乳 1L', categoryCode: 'dairy'),
    ];
    final offer = FlyerOffer(
      id: 'f1',
      productNameOrSku: '牛乳 1L（チラシ）',
      priceYen: 178,
      ingestionSource: FlyerIngestionSource.dummy,
    );
    final m = matchCatalogProductForFlyer(offer, products);
    expect(m?.name, '牛乳 1L');
  });

  test('countCheaperThanLastObservation counts flyer cheaper than latest observation', () {
    final flyers = [
      FlyerOffer(
        id: 'f1',
        productNameOrSku: '牛乳 1L（チラシ）',
        priceYen: 178,
        ingestionSource: FlyerIngestionSource.dummy,
      ),
    ];
    final products = [
      const CatalogProduct(id: 'p1', name: '牛乳 1L', categoryCode: 'dairy'),
    ];
    final observations = [
      PriceObservation(
        id: 'o1',
        productId: 'p1',
        priceYen: 198,
        observedAt: DateTime.utc(2026, 4, 21),
        source: 'manual',
      ),
    ];
    expect(
      countCheaperThanLastObservation(
        flyersValidToday: flyers,
        products: products,
        observations: observations,
      ),
      1,
    );
  });

  test('equal price does not count', () {
    final flyers = [
      FlyerOffer(
        id: 'f1',
        productNameOrSku: '牛乳 1L',
        priceYen: 198,
        ingestionSource: FlyerIngestionSource.dummy,
      ),
    ];
    final products = [
      const CatalogProduct(id: 'p1', name: '牛乳 1L', categoryCode: 'dairy'),
    ];
    final observations = [
      PriceObservation(
        id: 'o1',
        productId: 'p1',
        priceYen: 198,
        observedAt: DateTime.utc(2026, 4, 21),
        source: 'manual',
      ),
    ];
    expect(
      countCheaperThanLastObservation(
        flyersValidToday: flyers,
        products: products,
        observations: observations,
      ),
      0,
    );
  });

  test('cheaperThanLastHits keeps best saving per product', () {
    final flyers = [
      FlyerOffer(
        id: 'f1',
        productNameOrSku: '牛乳 1L（朝）',
        priceYen: 188,
        ingestionSource: FlyerIngestionSource.dummy,
      ),
      FlyerOffer(
        id: 'f2',
        productNameOrSku: '牛乳 1L（夕）',
        priceYen: 178,
        ingestionSource: FlyerIngestionSource.dummy,
      ),
    ];
    final products = [
      const CatalogProduct(id: 'p1', name: '牛乳 1L', categoryCode: 'dairy'),
    ];
    final observations = [
      PriceObservation(
        id: 'o1',
        productId: 'p1',
        priceYen: 198,
        observedAt: DateTime.utc(2026, 4, 21),
        source: 'manual',
      ),
    ];
    final hits = cheaperThanLastHits(
      flyersValidToday: flyers,
      products: products,
      observations: observations,
    );
    expect(hits, hasLength(1));
    expect(hits.single.offer.id, 'f2');
    expect(hits.single.savingsYen, 20);
  });
}
