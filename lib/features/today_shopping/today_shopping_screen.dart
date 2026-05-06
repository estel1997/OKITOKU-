import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product_category.dart';
import '../../domain/entities/catalog_product.dart';
import '../../domain/entities/flyer_offer.dart';
import '../../domain/flyer/flyer_offer_valid_today.dart';
import '../../domain/shopping/car_fuel_profile.dart';
import '../../domain/shopping/naha_fuel_reference.dart';
import '../../domain/shopping/shopping_transport.dart';
import '../../domain/shopping/shopping_trip_estimate.dart';
import '../../domain/shopping/today_shopping_state.dart';
import '../flyers/providers/flyer_offer_providers.dart';
import '../products/providers/product_providers.dart';
import 'providers/registered_shopping_route_provider.dart';
import 'providers/shopping_trip_estimate_provider.dart';
import 'providers/today_shopping_provider.dart';

/// 買い物リスト・移動手段・チラシ合計＋移動費の見積もり（案）
class TodayShoppingScreen extends ConsumerStatefulWidget {
  const TodayShoppingScreen({super.key});

  @override
  ConsumerState<TodayShoppingScreen> createState() =>
      _TodayShoppingScreenState();
}

class _TodayShoppingScreenState extends ConsumerState<TodayShoppingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _memoController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = await ref.read(todayShoppingProvider.future);
      if (mounted) {
        _memoController.text = s.freeformText;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(todayShoppingProvider);
    final estimate = ref.watch(shoppingTripEstimateProvider);
    final flyersAsync = ref.watch(flyerOffersProvider);
    final catalogAsync = ref.watch(catalogProductsProvider);

    return Scaffold(
      primary: false,
      appBar: AppBar(
        title: const Text('今日の買い物'),
        actions: [
          IconButton(
            tooltip: 'チラシ特売',
            onPressed: () => context.push('/flyers'),
            icon: const Icon(Icons.local_offer_outlined),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(todayShoppingProvider.notifier).clearSelections();
              if (mounted) {
                _memoController.clear();
              }
            },
            child: const Text('リストを空に'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '商品'),
            Tab(text: 'メモ帳'),
            Tab(text: '移動手段'),
          ],
        ),
      ),
      body: shopAsync.when(
        data: (state) {
          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProductsTab(
                      state: state,
                      flyersAsync: flyersAsync,
                      catalogAsync: catalogAsync,
                    ),
                    _MemoTab(controller: _memoController),
                    _TransportTab(),
                  ],
                ),
              ),
              _BottomBar(
                estimate: estimate,
                onComplete: () async {
                  final e = ref.read(shoppingTripEstimateProvider);
                  if (e == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('チラシ・カタログの読み込みが完了してからお試しください'),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(registeredShoppingRouteProvider.notifier)
                      .saveFromEstimate(e);
                  if (!context.mounted) {
                    return;
                  }
                  context.go('/home');
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.estimate,
    required this.onComplete,
  });

  final ShoppingTripEstimate? estimate;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (estimate != null) ...[
                Text(
                  'チラシ合計 ¥${estimate!.flyerSubtotalYen} ＋ 移動 ¥${estimate!.transportYen} ＝ ¥${estimate!.grandTotalYen}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ] else
                Text(
                  '見積もりを計算中…',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              FilledButton(
                onPressed: onComplete,
                child: const Text('お買い物登録完了'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({
    required this.state,
    required this.flyersAsync,
    required this.catalogAsync,
  });

  final TodayShoppingState state;
  final AsyncValue<List<FlyerOffer>> flyersAsync;
  final AsyncValue<List<CatalogProduct>> catalogAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/flyers'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '先にチラシ特売を見る',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/flyers'),
                    child: const Text('開く'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'チラシの特売にチェックし、個数を入力します。カタログはカテゴリー別に選べます。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: state.minimizeStoreHops,
          onChanged: (v) {
            if (v != null) {
              ref.read(todayShoppingProvider.notifier).setMinimizeStoreHops(v);
            }
          },
          title: const Text('できるだけ店舗移動を少なく'),
          subtitle: const Text(
            '1店舗または2店舗経由の候補を出します。お買い得でない商品をまとめると、'
            '少し高くなるかもしれませんが、お買い物時間を短縮できる場合があります。',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        _ExpandBlock(
          title: '本日有効チラシ',
          initiallyExpanded: true,
          child: flyersAsync.when(
            data: (all) {
              final today = all
                  .where((o) => flyerOfferValidOnLocalDay(o, DateTime.now()))
                  .toList();
              if (today.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '本日有効なチラシ行がありません（または読み込み中）。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: [
                  for (final o in today)
                    _FlyerQtyRow(
                      offer: o,
                      qty: state.flyerQtyById[o.id] ?? 0,
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
        ),
        const SizedBox(height: 12),
        _ExpandBlock(
          title: 'カタログ商品',
          initiallyExpanded: true,
          child: catalogAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('商品がありません'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in ProductCategory.values)
                    _CatalogCategoryBlock(
                      state: state,
                      category: category,
                      products: products
                          .where((p) => p.categoryCode == category.name)
                          .toList(),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
        ),
      ],
    );
  }
}

class _ExpandBlock extends StatefulWidget {
  const _ExpandBlock({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandBlock> createState() => _ExpandBlockState();
}

class _ExpandBlockState extends State<_ExpandBlock> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: Icon(
              _open ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _open = !_open),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FlyerQtyRow extends ConsumerWidget {
  const _FlyerQtyRow({
    required this.offer,
    required this.qty,
  });

  final FlyerOffer offer;
  final int qty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = qty > 0;
    final effective = selected ? (qty < 1 ? 1 : qty) : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => ref
                .read(todayShoppingProvider.notifier)
                .toggleFlyerOffer(offer.id),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(offer.productNameOrSku),
              subtitle: Text(
                offer.priceYen != null
                    ? '¥${offer.priceYen} ・ ${offer.chainId ?? "—"}'
                    : '価格未設定 ・ ${offer.chainId ?? "—"}',
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: _QtyIntField(
              enabled: selected,
              quantity: selected ? effective : 1,
              onChanged: (n) => ref
                  .read(todayShoppingProvider.notifier)
                  .setFlyerQty(offer.id, n),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCategoryBlock extends StatelessWidget {
  const _CatalogCategoryBlock({
    required this.state,
    required this.category,
    required this.products,
  });

  final TodayShoppingState state;
  final ProductCategory category;
  final List<CatalogProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            category.jaLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final p in products)
          _CatalogQtyRow(
            product: p,
            qty: state.catalogQtyById[p.id] ?? 0,
          ),
      ],
    );
  }
}

class _CatalogQtyRow extends ConsumerWidget {
  const _CatalogQtyRow({
    required this.product,
    required this.qty,
  });

  final CatalogProduct product;
  final int qty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = qty > 0;
    final effective = selected ? (qty < 1 ? 1 : qty) : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => ref
                .read(todayShoppingProvider.notifier)
                .toggleCatalogProduct(product.id),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(product.name),
              subtitle: const Text('価格はチラシ・店頭で確認'),
            ),
          ),
          SizedBox(
            width: 72,
            child: _QtyIntField(
              enabled: selected,
              quantity: selected ? effective : 1,
              onChanged: (n) => ref
                  .read(todayShoppingProvider.notifier)
                  .setCatalogQty(product.id, n),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyIntField extends StatefulWidget {
  const _QtyIntField({
    required this.enabled,
    required this.quantity,
    required this.onChanged,
  });

  final bool enabled;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  State<_QtyIntField> createState() => _QtyIntFieldState();
}

class _QtyIntFieldState extends State<_QtyIntField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  /// 常に数字を表示（「1」を空欄扱いにしない。PC キーボードでも編集しやすい）
  String _textForQuantity(int q) => '${q < 1 ? 1 : q}';

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_syncIfNeeded);
    _controller = TextEditingController(text: _textForQuantity(widget.quantity));
  }

  void _syncIfNeeded() {
    if (!_focus.hasFocus && mounted) {
      final next = _textForQuantity(widget.quantity);
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant _QtyIntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus &&
        (oldWidget.quantity != widget.quantity ||
            oldWidget.enabled != widget.enabled)) {
      final next = _textForQuantity(widget.quantity);
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_syncIfNeeded)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      focusNode: _focus,
      // number だと Windows/Web で挙動が不安定なことがあるため text + 数字のみにする
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: false,
      ),
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (s) {
        final t = s.trim();
        if (t.isEmpty) {
          widget.onChanged(1);
          // フォーカス中は親が quantity=1 のままだと再同期されないため明示的に戻す
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_focus.hasFocus) {
              return;
            }
            if (_controller.text.trim().isEmpty) {
              _controller.value = const TextEditingValue(
                text: '1',
                selection: TextSelection.collapsed(offset: 1),
              );
            }
          });
          return;
        }
        final n = int.tryParse(t);
        if (n != null && n > 0) {
          widget.onChanged(n);
        }
      },
    );
  }
}

class _MemoTab extends ConsumerStatefulWidget {
  const _MemoTab({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_MemoTab> createState() => _MemoTabState();
}

class _MemoTabState extends ConsumerState<_MemoTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '食材以外・自由記述（行ごとにメモ。価格は見積もりに含みません）',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          maxLines: 12,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '例: 洗剤、文房具…',
          ),
          onChanged: (t) {
            ref.read(todayShoppingProvider.notifier).setFreeformText(t);
          },
        ),
      ],
    );
  }
}

class _TransportTab extends ConsumerStatefulWidget {
  const _TransportTab();

  @override
  ConsumerState<_TransportTab> createState() => _TransportTabState();
}

class _TransportTabState extends ConsumerState<_TransportTab> {
  late final TextEditingController _kmController;
  late final FocusNode _kmFocus;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController();
    _kmFocus = FocusNode()..addListener(_onKmFocusChange);
  }

  void _onKmFocusChange() {
    if (!_kmFocus.hasFocus) {
      _commitKmField();
    }
  }

  void _commitKmField() {
    final t = _kmController.text.trim();
    if (t.isEmpty) {
      ref.read(todayShoppingProvider.notifier).setCustomRoundTripKm(null);
      return;
    }
    final normalized = t.replaceAll(',', '.');
    final v = double.tryParse(normalized);
    if (v == null) {
      return;
    }
    ref.read(todayShoppingProvider.notifier).setCustomRoundTripKm(v);
  }

  String _kmDisplayText(TodayShoppingState state) {
    final km = state.customRoundTripKm;
    if (km == null) {
      return '';
    }
    if (km == km.roundToDouble()) {
      return km.round().toString();
    }
    return km.toStringAsFixed(1);
  }

  void _syncKmField(TodayShoppingState state) {
    if (_kmFocus.hasFocus) {
      return;
    }
    final want = _kmDisplayText(state);
    if (_kmController.text != want) {
      _kmController.value = TextEditingValue(
        text: want,
        selection: TextSelection.collapsed(offset: want.length),
      );
    }
  }

  @override
  void dispose() {
    _kmFocus
      ..removeListener(_onKmFocusChange)
      ..dispose();
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(todayShoppingProvider);
    final state = shopAsync.valueOrNull ?? TodayShoppingState.initial();
    _syncKmField(state);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '移動費の目安に使います。自動車は燃費と往復距離（手入力）を使います。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<ShoppingTransport>(
          showSelectedIcon: false,
          segments: [
            for (final t in ShoppingTransport.values)
              ButtonSegment<ShoppingTransport>(
                value: t,
                label: Text(t.shortLabel),
              ),
          ],
          selected: {state.transport},
          onSelectionChanged: (next) {
            if (next.isNotEmpty) {
              ref
                  .read(todayShoppingProvider.notifier)
                  .setTransport(next.first);
            }
          },
        ),
        if (state.transport == ShoppingTransport.car) ...[
          const SizedBox(height: 20),
          Text(
            '往復の走行距離（km）',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            state.customRoundTripKm == null
                ? '未入力のときは ${kDefaultShoppingRoundTripKm.toStringAsFixed(0)} km（那覇周辺の目安）を使います。'
                : '現在の見積もり: ${state.effectiveRoundTripKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _kmController,
            focusNode: _kmFocus,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '往復 km（任意）',
              hintText: '例: 12 または 25.5',
              suffixText: 'km',
            ),
            onSubmitted: (_) => _commitKmField(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                _kmController.clear();
                ref.read(todayShoppingProvider.notifier).setCustomRoundTripKm(null);
              },
              child: Text(
                '目安距離（${kDefaultShoppingRoundTripKm.toStringAsFixed(0)} km）に戻す',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '燃費の目安',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<CarFuelProfile>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<CarFuelProfile>(
                value: CarFuelProfile.family105,
                label: Text('ファミリーカー\n10.5 km/L'),
              ),
              ButtonSegment<CarFuelProfile>(
                value: CarFuelProfile.kei18,
                label: Text('軽自動車\n18 km/L'),
              ),
            ],
            selected: {state.carFuelProfile},
            onSelectionChanged: (next) {
              if (next.isNotEmpty) {
                ref
                    .read(todayShoppingProvider.notifier)
                    .setCarFuelProfile(next.first);
              }
            },
          ),
        ],
      ],
    );
  }
}

