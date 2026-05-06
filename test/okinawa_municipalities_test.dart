import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/data/okinawa/okinawa_municipalities.dart';

void main() {
  test('沖縄県は41市区町村', () {
    expect(kAllOkinawaMunicipalityNames.length, 41);
    expect(kAllOkinawaMunicipalityNames.toSet().length, 41);
  });
}
