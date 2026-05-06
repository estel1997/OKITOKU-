import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../flyers/providers/flyer_offer_providers.dart';
import 'providers/home_summary_providers.dart';
import '../stores/providers/store_providers.dart';
import '../today_shopping/providers/registered_shopping_route_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _formatRegisteredAt(DateTime t) {
    return '${t.month}/${t.day} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final flyersAsync = ref.watch(flyerOffersProvider);
    final flyerCountLabel = flyersAsync.when(
      data: (list) => '${list.length} 件',
      loading: () => '…',
      error: (_, __) => '—',
    );
    final todayDealsLabel = ref.watch(flyerOffersValidTodayCountLabelProvider);
    final cheaperThanLastLabel = ref.watch(homeCheaperThanLastLabelProvider).when(
          data: (s) => s,
          loading: () => '…',
          error: (_, __) => '—',
        );
    final registeredAsync = ref.watch(registeredShoppingRouteProvider);
    final activeStoresAsync = ref.watch(activeStoresProvider);

    return Scaffold(
      primary: false,
      appBar: AppBar(title: const Text('ホーム')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          activeStoresAsync.when(
            data: (stores) {
              if (stores.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.push('/area-expansion'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            color: cs.onTertiaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '行動圏の店を追加してください',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: cs.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '価格比較やお得情報に使うお店を 1 店以上選びます。',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onTertiaryContainer
                                            .withValues(alpha: 0.9),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: cs.onTertiaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: '本日の特売',
                  value: todayDealsLabel,
                  color: cs.primaryContainer,
                  onTap: () => context.push('/flyers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: '前回より安い',
                  value: cheaperThanLastLabel,
                  color: cs.secondaryContainer,
                  onTap: () => context.push('/notifications'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'チラシ特売',
            value: flyerCountLabel,
            color: cs.surfaceContainerHighest,
            fullWidth: true,
            onTap: () => context.push('/flyers'),
          ),
          const SizedBox(height: 12),
          Material(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => context.go('/today-shopping'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日の買い物',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '商品の追加・変更、リスト・移動手段・見積もり（案）',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                              color: cs.onPrimaryContainer.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                registeredAsync.when(
                  data: (r) {
                    if (r == null) {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('登録したお買い物ルート'),
                          content: const Text('登録がまだです'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      context.push('/registered-shopping-route');
                    }
                  },
                  loading: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('読み込み中です')),
                    );
                  },
                  error: (_, __) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('読み込みに失敗しました')),
                    );
                  },
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '登録したお買い物ルート',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          registeredAsync.when(
                            data: (r) => Text(
                              r == null
                                  ? '「お買い物登録完了」で保存すると表示されます'
                                  : '登録 ${_formatRegisteredAt(r.completedAt)} ・タップで表示・編集',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            loading: () => Text(
                              '…',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            error: (_, __) => Text(
                              '読み込みエラー',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _CollapsibleQuickActions(),
        ],
      ),
    );
  }
}

class _CollapsibleQuickActions extends StatefulWidget {
  const _CollapsibleQuickActions();

  @override
  State<_CollapsibleQuickActions> createState() =>
      _CollapsibleQuickActionsState();
}

class _CollapsibleQuickActionsState extends State<_CollapsibleQuickActions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'クイックアクション',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('カテゴリーから登録'),
                  subtitle: const Text(
                    'カテゴリー別の商品からウォッチへ追加',
                  ),
                  onTap: () =>
                      context.push('/products/register-by-category'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('ウォッチ商品'),
                  subtitle: const Text('下のタブからも開けます'),
                  onTap: () => context.go('/watch'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: const Text('チラシ特売'),
                  subtitle: const Text('取り込み済みの特売一覧'),
                  onTap: () => context.push('/flyers'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('設定'),
                  subtitle: const Text('下のタブからも開けます'),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: fullWidth
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
        ),
      ),
    );
  }
}
