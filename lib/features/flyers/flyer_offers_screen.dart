import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/flyer_offer.dart';
import 'providers/flyer_offer_providers.dart';

/// チラシ由来の特売一覧（`flyerOffersProvider` → ローカルダミー or Supabase）
class FlyerOffersScreen extends ConsumerWidget {
  const FlyerOffersScreen({super.key});

  static String _chainLabel(String? chainId) {
    if (chainId == null || chainId.isEmpty) {
      return 'チェーン未設定';
    }
    return chainId;
  }

  static String _sourceLabel(FlyerIngestionSource s) {
    return switch (s) {
      FlyerIngestionSource.dummy => 'ダミー',
      FlyerIngestionSource.csv => 'CSV',
      FlyerIngestionSource.apiJson => 'API',
      FlyerIngestionSource.email => 'メール',
      FlyerIngestionSource.pdf => 'PDF',
      FlyerIngestionSource.manual => '手入力',
      FlyerIngestionSource.receiptImage => 'レシート画像',
    };
  }

  static String? _validityLine(FlyerOffer o) {
    if (o.validFrom == null && o.validTo == null) {
      return null;
    }
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (o.validFrom != null && o.validTo != null) {
      return '${fmt(o.validFrom!)} 〜 ${fmt(o.validTo!)}';
    }
    if (o.validFrom != null) {
      return '開始 ${fmt(o.validFrom!)}';
    }
    return 'まで ${fmt(o.validTo!)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(flyerOffersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('チラシ特売')),
      body: async.when(
        data: (offers) {
          if (offers.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(flyerOffersProvider);
                await ref.read(flyerOffersProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('表示できる特売がありません')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(flyerOffersProvider);
              await ref.read(flyerOffersProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final o = offers[i];
                final validity = _validityLine(o);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.productNameOrSku,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _chainLabel(o.chainId),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (o.priceYen != null)
                              Text(
                                '¥${o.priceYen}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                          ],
                        ),
                        if (validity != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            validity,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '経路: ${_sourceLabel(o.ingestionSource)}'
                          '${o.sourceRef != null ? '  ·  ${o.sourceRef}' : ''}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('読み込みに失敗しました: $e', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
