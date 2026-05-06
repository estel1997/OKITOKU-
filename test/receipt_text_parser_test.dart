import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/data/ingestion/parsers/receipt_text_parser.dart';

void main() {
  final parser = ReceiptTextParser();

  test('parses colon-separated name and price', () {
    const text = 'ﾀﾏﾈｷﾞ : 128\nにんじん：198円';
    final r = parser.parse(text);
    expect(r.lines.length, 2);
    expect(r.lines[0].productName, 'ﾀﾏﾈｷﾞ');
    expect(r.lines[0].priceYen, 128);
    expect(r.lines[1].productName, 'にんじん');
    expect(r.lines[1].priceYen, 198);
  });

  test('still parses yen suffix lines', () {
    final r = parser.parse('牛乳 1L 198円');
    expect(r.lines.length, 1);
    expect(r.lines[0].productName, '牛乳 1L');
    expect(r.lines[0].priceYen, 198);
  });
}
