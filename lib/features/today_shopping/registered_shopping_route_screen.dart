import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/registered_shopping_route_provider.dart';
import 'widgets/shopping_estimate_card.dart';

/// ホームから開く「登録したお買い物ルート」詳細
class RegisteredShoppingRouteScreen extends ConsumerWidget {
  const RegisteredShoppingRouteScreen({super.key});

  static String _formatRegisteredAt(DateTime t) {
    return '${t.year}/${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登録を削除'),
        content: const Text(
          '登録したお買い物ルートを削除しますか？\n'
          '「今日の買い物」のリスト自体は残ります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    await ref.read(registeredShoppingRouteProvider.notifier).clearRegistration();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('登録したルートを削除しました')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(registeredShoppingRouteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('登録したお買い物ルート'),
      ),
      body: async.when(
        data: (registered) {
          if (registered == null) {
            return const Center(child: Text('データがありません'));
          }
          final estimate = registered.toEstimate();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '登録日時: ${_formatRegisteredAt(registered.completedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '※ 登録完了時点の内容です。商品を変えたあと内容を更新するには、'
                '「今日の買い物」で「お買い物登録完了」をもう一度押してください。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                '最良のお買い物ルート（案）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                estimate.routeHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ShoppingEstimateCard(estimate: estimate),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/today-shopping'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('商品・リストを編集する'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('この登録を削除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
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
