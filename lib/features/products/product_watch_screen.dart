import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product_category.dart';
import '../../domain/entities/catalog_product.dart';
import '../flyers/providers/flyer_offer_providers.dart';
import 'providers/product_providers.dart';

class ProductWatchScreen extends ConsumerStatefulWidget {
  const ProductWatchScreen({super.key});

  @override
  ConsumerState<ProductWatchScreen> createState() =>
      _ProductWatchScreenState();
}

class _ProductWatchScreenState extends ConsumerState<ProductWatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(catalogProductsProvider);
    final watchAsync = ref.watch(watchlistIdsProvider);
    final flyersAsync = ref.watch(flyerOffersProvider);

    return Scaffold(
      primary: false,
      appBar: AppBar(
        title: const Text('ウォッチ'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: 'ウォッチ中'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: () => context.push('/flyers'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'チラシ特売',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          flyersAsync.when(
                            data: (offers) => Text(
                              '${offers.length} 件（取り込み済み）',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            loading: () => Text(
                              '読み込み中…',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            error: (e, _) => Text(
                              '取得できません',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/flyers'),
                      child: const Text('見る'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                productsAsync.when(
                  data: (products) => _ProductList(products: products, ref: ref),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                ),
                productsAsync.when(
                  data: (products) {
                    final watchedIds = watchAsync.maybeWhen(
                      data: (s) => s,
                      orElse: () => <String>{},
                    );
                    final filtered = products
                        .where((p) => watchedIds.contains(p.id))
                        .toList();
                    if (watchAsync.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (filtered.isEmpty) {
                      return const Center(child: Text('ウォッチ中の商品がありません'));
                    }
                    return _ProductList(products: filtered, ref: ref);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.ref});

  final List<CatalogProduct> products;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(catalogProductsProvider);
        ref.invalidate(flyerOffersProvider);
        await Future.wait([
          ref.read(catalogProductsProvider.future),
          ref.read(flyerOffersProvider.future),
        ]);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          final p = products[i];
          final category = tryParseProductCategory(p.categoryCode);
          final label = category?.jaLabel ?? p.categoryCode;
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/products/${p.id}'),
            ),
          );
        },
      ),
    );
  }
}
