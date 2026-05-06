import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/domain/entities/price_observation.dart';

void main() {
  test('PriceObservation.fromSupabaseRow parses nested stores', () {
    final o = PriceObservation.fromSupabaseRow({
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'product_id': 'p1',
      'store_id': 's1',
      'price_yen': 178,
      'observed_at': '2026-04-18T00:00:00+00:00',
      'source': 'flyer',
      'stores': {'name': 'サンエー 那覇店'},
    });
    expect(o.storeName, 'サンエー 那覇店');
    expect(o.priceYen, 178);
  });
}
