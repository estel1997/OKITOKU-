import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/store_providers.dart';

/// 「頻繁にお買い物をするお店」から外す（店舗タブなどから）。
class RemoveStoresScreen extends ConsumerWidget {
  const RemoveStoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeStoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('頻繁にお買い物をするお店を削除')),
      body: async.when(
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(child: Text('登録されている店がありません'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = stores[i];
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('チェーン: ${s.chainId}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '一覧から削除',
                    onPressed: () async {
                      await ref.read(activeStoresProvider.notifier).removeStore(s.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('「${s.name}」を削除しました')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
