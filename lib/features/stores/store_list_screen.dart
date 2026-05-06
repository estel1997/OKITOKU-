import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';
import '../../domain/entities/store.dart';
import 'providers/store_providers.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  bool _frequentSectionExpanded = true;
  bool _catalogSectionExpanded = true;

  static String _subtitle(Store s) {
    final m = s.municipality;
    if (m != null && m.isNotEmpty) {
      return '$m ・ ${s.chainId}';
    }
    return 'チェーン: ${s.chainId}';
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeStoresProvider);
    final catalogAsync = ref.watch(catalogStoresProvider);

    return Scaffold(
      primary: false,
      appBar: AppBar(title: const Text('店舗')),
      body: activeAsync.when(
        data: (active) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeStoresProvider);
              ref.invalidate(catalogStoresProvider);
              await Future.wait([
                ref.read(activeStoresProvider.future),
                ref.read(catalogStoresProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
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
                              'チラシ特売を確認',
                              style: Theme.of(context).textTheme.titleSmall,
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
                const SizedBox(height: 12),
                _CollapsibleSectionHeader(
                  title: '頻繁にお買い物をするお店',
                  expanded: _frequentSectionExpanded,
                  onToggle: () => setState(
                    () => _frequentSectionExpanded = !_frequentSectionExpanded,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/area-expansion'),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('頻繁にお買い物をするお店の追加'),
                  ),
                ),
                if (_frequentSectionExpanded) ...[
                  const SizedBox(height: 4),
                  if (active.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'まだありません。上の「追加」から市区町村や候補店を選べます。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  else
                    ...active.map(
                      (s) => Card(
                        child: ListTile(
                          title: Text(s.name),
                          subtitle: Text(_subtitle(s)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/stores/${s.id}'),
                        ),
                      ),
                    ),
                ],
                if (AppEnv.hasSupabase) ...[
                  const SizedBox(height: 16),
                  _CollapsibleSectionHeader(
                    title: '掲載店マスタ（Supabase）',
                    expanded: _catalogSectionExpanded,
                    onToggle: () => setState(
                      () => _catalogSectionExpanded = !_catalogSectionExpanded,
                    ),
                  ),
                  if (_catalogSectionExpanded) ...[
                    const SizedBox(height: 8),
                    catalogAsync.when(
                      data: (catalog) {
                        if (catalog.isEmpty) {
                          return Text(
                            '店舗マスタが空です',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return Column(
                          children: catalog
                              .map(
                                (s) => Card(
                                  child: ListTile(
                                    title: Text(s.name),
                                    subtitle: Text(_subtitle(s)),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push('/stores/${s.id}'),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('マスタの読み込みに失敗: $e'),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('読み込みに失敗しました: $e'),
          ),
        ),
      ),
    );
  }
}

/// 大見出しの開閉（▼ / 右向きチーズの回転）。
class _CollapsibleSectionHeader extends StatelessWidget {
  const _CollapsibleSectionHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: kThemeChangeDuration,
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
