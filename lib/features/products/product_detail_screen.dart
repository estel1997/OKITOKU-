import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/local_notifications_service.dart';
import '../../data/models/product_category.dart';
import 'providers/product_providers.dart';
import 'widgets/nearby_deal_section.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Future<void> _onWatchToggled({
    required bool wasWatched,
    required String name,
  }) async {
    final nowWatched =
        await ref.read(watchlistIdsProvider.notifier).toggle(widget.productId);
    if (!mounted) {
      return;
    }
    if (!wasWatched && nowWatched) {
      await LocalNotificationsService.showWatchListAdded(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(catalogProductProvider(widget.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('商品')),
            body: const Center(child: Text('商品が見つかりません')),
          );
        }
        final category = tryParseProductCategory(product.categoryCode);
        final categoryLabel = category?.jaLabel ?? product.categoryCode;

        final watchAsync = ref.watch(watchlistIdsProvider);
        final watched = watchAsync.maybeWhen(
          data: (ids) => ids.contains(widget.productId),
          orElse: () => false,
        );
        final watchLoading = watchAsync.isLoading;

        return Scaffold(
          appBar: AppBar(title: Text(product.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                categoryLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('価格ウォッチ'),
                subtitle: const Text('ウォッチ中の一覧は端末に保存。安値のプッシュはバックエンド連携後に拡張'),
                value: watched,
                onChanged: watchLoading
                    ? null
                    : (_) => _onWatchToggled(wasWatched: watched, name: product.name),
              ),
              const Divider(height: 32),
              Text(
                '価格履歴（観測）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _PriceObservationList(productId: widget.productId),
              const SizedBox(height: 24),
              NearbyDealSection(productId: widget.productId),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('商品')),
        body: Center(child: Text('$e')),
      ),
    );
  }
}

String _priceSourceJa(String code) {
  return switch (code) {
    'flyer' => 'チラシ',
    'receipt' => 'レシート',
    'manual' => '手入力',
    'seed' => 'シード',
    _ => code,
  };
}

String _formatObservationDate(DateTime d) {
  final x = d.toLocal();
  final m = x.month.toString().padLeft(2, '0');
  final day = x.day.toString().padLeft(2, '0');
  final h = x.hour.toString().padLeft(2, '0');
  final min = x.minute.toString().padLeft(2, '0');
  return '${x.year}/$m/$day $h:$min';
}

class _PriceObservationList extends ConsumerWidget {
  const _PriceObservationList({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(priceObservationsForProductProvider(productId));
    return async.when(
      data: (rows) {
        if (rows.isEmpty) {
          return Text(
            'まだ観測がありません（マイグレーション適用後に Supabase へ蓄積）。',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final o in rows)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('¥${o.priceYen}'),
                  subtitle: Text(
                    '${o.storeName ?? o.storeId ?? '店舗不明'} · '
                    '${_priceSourceJa(o.source)} · ${_formatObservationDate(o.observedAt)}',
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(
        '履歴を読み込めません: $e',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
