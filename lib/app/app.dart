import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

/// 価格ウォッチ（主ターゲット: Android / iOS。`core/config/app_target.dart` 参照）。
class ShoppingPriceWatchApp extends StatelessWidget {
  const ShoppingPriceWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '価格ウォッチ',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
