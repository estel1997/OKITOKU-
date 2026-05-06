import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/config/app_env.dart';
import '../../core/persistence/onboarding_prefs.dart';
import '../area/area_expansion_screen.dart';
import '../stores/providers/store_providers.dart';

/// 初回: 市区町村と行動圏の店を 1 件以上選んでからホームへ進む。
class OnboardingAreaSetupScreen extends ConsumerWidget {
  const OnboardingAreaSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('行動圏の設定'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'よく行くスーパーを選んでください',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppEnv.hasSupabase
                        ? '沖縄県の市区町村から店を追加します（1 店以上）。あとから「設定」→「行動圏を広げる」でも変更できます。'
                        : 'オフライン・デモ用の店マスタから選びます（1 店以上）。Supabase を有効にするとクラウドの店舗マスタと同期できます。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: AreaSetupBody(bottomPadding: 16)),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () async {
                    try {
                      final stores = await ref.read(activeStoresProvider.future);
                      if (stores.isEmpty) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '行動圏の店を 1 店以上選んでください（市区町村の一覧からチェックできます）',
                            ),
                          ),
                        );
                        return;
                      }
                      await OnboardingPrefs.setCompleted(true);
                      AppLaunch.onboardingCompleted.value = true;
                      if (!context.mounted) {
                        return;
                      }
                      context.go('/home');
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('保存に失敗しました: $e')),
                      );
                    }
                  },
                  child: const Text('この内容ではじめる'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
