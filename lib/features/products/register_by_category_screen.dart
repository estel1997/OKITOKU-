import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_category.dart';
import '../../domain/entities/catalog_product.dart';
import 'providers/product_providers.dart';

/// レシートなしで、カテゴリー別に商品を選びウォッチへ追加する。
class RegisterByCategoryScreen extends ConsumerWidget {
  const RegisterByCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProductsProvider);
    final watchAsync = ref.watch(watchlistIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリーから登録'),
      ),
      body: catalogAsync.when(
        data: (products) {
          return watchAsync.when(
            data: (watched) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(catalogProductsProvider);
                await ref.read(catalogProductsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'チェックした商品をウォッチに追加します',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  for (final category in ProductCategory.values)
                    _CategoryBlock(
                      category: category,
                      products: products
                          .where((p) => p.categoryCode == category.name)
                          .toList(),
                      watched: watched,
                      onToggle: (id) => ref
                          .read(watchlistIdsProvider.notifier)
                          .toggle(id),
                    ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.category,
    required this.products,
    required this.watched,
    required this.onToggle,
  });

  final ProductCategory category;
  final List<CatalogProduct> products;
  final Set<String> watched;
  final void Function(String productId) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            category.jaLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'このカテゴリーの登録商品はまだありません',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  CheckboxListTile(
                    value: watched.contains(products[i].id),
                    onChanged: (_) => onToggle(products[i].id),
                    title: Text(products[i].name),
                    secondary: const Icon(Icons.shopping_bag_outlined),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
