import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('はじめに')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '近くのお店で、いつもの買い物が少しでも安くなるようにお手伝いします。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              '次の画面で、沖縄県の市区町村とよく行くスーパーを選びます。チラシの特売や価格の比較に使われます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            if (!AppEnv.hasSupabase) ...[
              const SizedBox(height: 16),
              Card(
                color: cs.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cloud_off_outlined, color: cs.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'このビルドは Supabase 未設定です。店舗・チラシは端末内のデモデータを使います。本番接続は VS Code の「Flutter + Supabase」起動設定か dart-define を指定してください。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSecondaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/onboarding/setup'),
              child: const Text('地域とお店を選ぶ'),
            ),
          ],
        ),
      ),
    );
  }
}
