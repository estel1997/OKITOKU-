import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../products/providers/product_providers.dart';
import 'providers/store_providers.dart';

class StoreDetailScreen extends ConsumerWidget {
  const StoreDetailScreen({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeByIdProvider(storeId));
    final dealsAsync = ref.watch(storeNearbyDealsProvider(storeId));
    final catalogAsync = ref.watch(catalogProductsProvider);

    return async.when(
      data: (found) {
        if (found == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('店舗')),
            body: const Center(child: Text('店舗が見つかりません')),
          );
        }
        final m = found.municipality;
        return Scaffold(
          appBar: AppBar(title: Text(found.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'チェーン ID',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        found.chainId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (m != null && m.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '市区町村',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '営業時間',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (found.openingHours != null &&
                          found.openingHours!.trim().isNotEmpty)
                        SelectableText(
                          found.openingHours!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      else
                        Text(
                          AppEnv.hasSupabase
                              ? 'マスタに営業時間が登録されていません。Supabase の stores.opening_hours を更新してください。'
                              : 'ローカルデモに営業時間がありません。',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '価格比較（商品マスタの近隣データ）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              dealsAsync.when(
                data: (deals) {
                  if (deals.isEmpty) {
                    return Text(
                      AppEnv.hasSupabase
                          ? 'この店を起点とした比較データはありません。'
                          : 'Supabase 接続時に周辺安値を表示できます。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    );
                  }
                  return Column(
                    children: [
                      for (final d in deals)
                        Builder(
                          builder: (context) {
                            final productName = catalogAsync.maybeWhen(
                              data: (products) {
                                for (final p in products) {
                                  if (p.id == d.productId) {
                                    return p.name;
                                  }
                                }
                                return '商品 ${d.productId}';
                              },
                              orElse: () => '商品 ${d.productId}',
                            );
                            return Card(
                              child: ListTile(
                                leading:
                                    const Icon(Icons.compare_arrows_outlined),
                                title: Text(
                                  '${d.suggestedStoreName} が '
                                  '${d.baseStoreName} より '
                                  '¥${d.savings} 安い',
                                ),
                                subtitle: Text(
                                  '$productName\n'
                                  '${d.baseStoreName}: ¥${d.basePrice} → '
                                  '${d.suggestedStoreName}: ¥${d.suggestedPrice} / '
                                  '距離 ${d.distanceKm.toStringAsFixed(1)} km',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  '読み込みエラー: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('店舗')),
        body: Center(child: Text('$e')),
      ),
    );
  }
}
