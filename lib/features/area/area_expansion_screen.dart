import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/dismissed_suggested_store_prefs.dart';
import '../../data/okinawa/okinawa_municipalities.dart';
import '../../domain/entities/store.dart';
import '../products/providers/product_providers.dart';
import '../stores/providers/store_municipality_providers.dart';
import '../stores/providers/store_providers.dart';
import 'providers/municipality_selection_provider.dart';

class AreaExpansionScreen extends ConsumerWidget {
  const AreaExpansionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('行動圏を広げる')),
      body: const AreaSetupBody(bottomPadding: 24),
    );
  }
}

/// 市区町村・候補店・行動圏チェックの共通スクロール（初回オンボーディングと [AreaExpansionScreen] で共有）。
class AreaSetupBody extends ConsumerWidget {
  const AreaSetupBody({
    super.key,
    this.bottomPadding = 24,
  });

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onRefresh() async {
      ref.invalidate(suggestedStoresProvider);
      ref.invalidate(selectedMunicipalitiesProvider);
      ref.invalidate(activeStoresProvider);
      ref.invalidate(storesInMunicipalityProvider);
      await Future.wait([
        ref.read(suggestedStoresProvider.future),
        ref.read(selectedMunicipalitiesProvider.future),
        ref.read(activeStoresProvider.future),
      ]);
    }

    final suggestedAsync = ref.watch(suggestedStoresProvider);
    final municipalitiesAsync = ref.watch(selectedMunicipalitiesProvider);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomPadding),
        children: [
          _MunicipalityChipsHeader(
            onEdit: () => _openMunicipalityEditor(context, ref),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '周辺の候補店',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '「行動圏に追加」すると、価格の比較や通知の対象店として使われます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...suggestedAsync.when(
            data: (stores) {
              if (stores.isEmpty) {
                return [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('候補店がありません')),
                  ),
                ];
              }
              return stores
                  .map((s) => _SuggestedStoreCard(store: s))
                  .toList();
            },
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '市区町村を選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...municipalitiesAsync.when(
            data: (selected) => [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => ref
                            .read(selectedMunicipalitiesProvider.notifier)
                            .clearAll(),
                    child: const Text('すべて解除'),
                  ),
                ),
              ),
              for (final section in kOkinawaMunicipalitySections)
                ExpansionTile(
                  title: Text(section.header),
                  subtitle: Text('${section.names.length} 市区町村'),
                  children: [
                    for (final name in section.names)
                      _MunicipalityStoreRow(
                        municipalityName: name,
                        municipalitySelected: selected.contains(name),
                      ),
                  ],
                ),
            ],
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('読み込みエラー: $e'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openMunicipalityEditor(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '市区町村を選択',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final async = ref.watch(selectedMunicipalitiesProvider);
                        return async.when(
                          data: (selected) => TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () => ref
                                    .read(selectedMunicipalitiesProvider.notifier)
                                    .clearAll(),
                            child: const Text('すべて解除'),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _MunicipalitySheetList(scrollController: scrollController),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ボトムシート内の市区町村一覧（メイン画面と同じ行 UI）。
class _MunicipalitySheetList extends ConsumerWidget {
  const _MunicipalitySheetList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selectedMunicipalitiesProvider);

    return async.when(
      data: (selected) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          children: [
            for (final section in kOkinawaMunicipalitySections)
              ExpansionTile(
                title: Text(section.header),
                subtitle: Text('${section.names.length} 市区町村'),
                children: [
                  for (final name in section.names)
                    _MunicipalityStoreRow(
                      municipalityName: name,
                      municipalitySelected: selected.contains(name),
                    ),
                ],
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

/// 上部: 選択中市区町村をタグ表示。「市区町村を編集」でボトムシート。
class _MunicipalityChipsHeader extends ConsumerWidget {
  const _MunicipalityChipsHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selectedMunicipalitiesProvider);
    final total = kAllOkinawaMunicipalityNames.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: async.when(
        data: (selected) {
          final sorted = selected.toList()..sort();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '手動で行動圏の追加',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('市区町村を編集'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '沖縄県の市区町村（全 $total 件・選択中 ${selected.length} 件）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (sorted.isEmpty)
                    Text(
                      '未選択です。「市区町村を編集」または下の一覧から選べます。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in sorted)
                          InputChip(
                            label: Text(name),
                            onDeleted: () => ref
                                .read(selectedMunicipalitiesProvider.notifier)
                                .toggle(name),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('読み込みエラー: $e'),
          ),
        ),
      ),
    );
  }
}

/// 左: 市区町村チェック / 右端: 展開して市内スーパーをチェック。
class _MunicipalityStoreRow extends ConsumerStatefulWidget {
  const _MunicipalityStoreRow({
    required this.municipalityName,
    required this.municipalitySelected,
  });

  final String municipalityName;
  final bool municipalitySelected;

  @override
  ConsumerState<_MunicipalityStoreRow> createState() =>
      _MunicipalityStoreRowState();
}

class _MunicipalityStoreRowState extends ConsumerState<_MunicipalityStoreRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: widget.municipalitySelected,
                onChanged: (_) => ref
                    .read(selectedMunicipalitiesProvider.notifier)
                    .toggle(widget.municipalityName),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(selectedMunicipalitiesProvider.notifier)
                      .toggle(widget.municipalityName),
                  child: Text(
                    widget.municipalityName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'この市区町村のスーパー',
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
        ),
        if (_expanded)
          ref.watch(storesInMunicipalityProvider(widget.municipalityName)).when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(left: 48, bottom: 12),
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                  child: Text(
                    '読み込みに失敗しました: $e',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
                data: (stores) {
                  final activeAsync = ref.watch(activeStoresProvider);
                  return activeAsync.when(
                    data: (active) {
                      final ids = active.map((e) => e.id).toSet();
                      if (stores.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 48,
                            right: 16,
                            bottom: 8,
                          ),
                          child: Text(
                            'この市区町村のスーパー候補は準備中です。',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 40, right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final store in stores)
                              CheckboxListTile(
                                dense: true,
                                value: ids.contains(store.id),
                                title: Text(store.name),
                                subtitle: Text('チェーン: ${store.chainId}'),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (v) async {
                                  if (v == true) {
                                    await ref
                                        .read(activeStoresProvider.notifier)
                                        .addStore(store);
                                  } else {
                                    await ref
                                        .read(activeStoresProvider.notifier)
                                        .removeStore(store.id);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
      ],
    );
  }
}

class _SuggestedStoreCard extends ConsumerWidget {
  const _SuggestedStoreCard({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeStoresProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(store.name),
              subtitle: Text('チェーン: ${store.chainId} · 周辺候補'),
              isThreeLine: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: activeAsync.when(
                data: (active) {
                  final inArea = active.any((x) => x.id == store.id);
                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: inArea
                              ? null
                              : () async {
                                  await ref
                                      .read(activeStoresProvider.notifier)
                                      .addStore(store);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '「${store.name}」を行動圏に追加しました',
                                      ),
                                    ),
                                  );
                                },
                          child: Text(inArea ? '行動圏に追加済み' : '行動圏に追加'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await DismissedSuggestedStorePrefs.addId(store.id);
                          ref.invalidate(suggestedStoresProvider);
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('「${store.name}」を候補から外しました'),
                            ),
                          );
                        },
                        child: const Text('非表示'),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
