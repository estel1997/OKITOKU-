import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_providers.dart';

class NearbyDealSection extends ConsumerWidget {
  const NearbyDealSection({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyDealsProvider(productId));

    return async.when(
      data: (deals) {
        if (deals.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近くでより安い店',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...deals.map(
              (d) => Card(
                child: ListTile(
                  title: Text(d.suggestedStoreName),
                  subtitle: Text(
                    '${d.baseStoreName} ¥${d.basePrice} → ここ ¥${d.suggestedPrice}（−¥${d.savings}） / ${d.distanceKm.toStringAsFixed(1)} km',
                  ),
                  leading: const Icon(Icons.savings_outlined),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('周辺価格の読み込みに失敗: $e'),
    );
  }
}
