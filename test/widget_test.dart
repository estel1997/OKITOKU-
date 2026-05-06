import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shopping_price_watch/app/app.dart';

void main() {
  testWidgets('オンボーディング画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShoppingPriceWatchApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('はじめに'), findsOneWidget);
  });
}
