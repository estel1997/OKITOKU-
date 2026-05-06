import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/notification_providers.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  static String _yenDelta(int savingsYen) => '−¥$savingsYen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cheaperThanLastNotificationHitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: async.when(
        data: (hits) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hits.isEmpty)
              Text(
                '前回より安い通知はまだありません。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            for (final hit in hits)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.local_offer_outlined),
                  ),
                  title: Text(hit.product.name),
                  subtitle: Text(
                    '前回より安い · ${hit.lastObservation.storeName ?? hit.lastObservation.storeId ?? '店舗不明'}',
                  ),
                  trailing: Text(_yenDelta(hit.savingsYen)),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '比較条件: 本日有効チラシの価格が、商品ごとの直近観測価格より安い場合のみ表示。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('通知を取得できません: $e')),
      ),
    );
  }
}
