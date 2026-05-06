import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/data/ingestion/parsers/email_flyer_parser.dart';
import 'package:shopping_price_watch/domain/entities/flyer_offer.dart';

void main() {
  group('EmailFlyerParser', () {
    test('parses 円 suffix', () {
      const body = '玉ねぎ 198円\n';
      final offers = EmailFlyerParser().parseBody(body);
      expect(offers, hasLength(1));
      expect(offers.first.productNameOrSku, '玉ねぎ');
      expect(offers.first.priceYen, 198);
      expect(offers.first.ingestionSource, FlyerIngestionSource.email);
    });

    test('parses ¥ prefix', () {
      const body = '卵 ¥248\n';
      final offers = EmailFlyerParser().parseBody(body);
      expect(offers, hasLength(1));
      expect(offers.first.productNameOrSku, '卵');
      expect(offers.first.priceYen, 248);
    });

    test('respects FlyerIngestionSource.pdf', () {
      const body = '牛乳 ￥198\n';
      final offers = EmailFlyerParser().parseBody(
        body,
        source: FlyerIngestionSource.pdf,
      );
      expect(offers.single.ingestionSource, FlyerIngestionSource.pdf);
    });
  });
}
