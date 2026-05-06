import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// リポジトリの [docs/IMPLEMENTATION_ROADMAP.md] を表示（pubspec の assets に登録済みであること）。
class ImplementationRoadmapScreen extends StatelessWidget {
  const ImplementationRoadmapScreen({super.key});

  static const _assetPath = 'docs/IMPLEMENTATION_ROADMAP.md';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('実装の優先順位')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(_assetPath),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'ドキュメントを読み込めませんでした。\n'
                  'pubspec.yaml の assets に $_assetPath があるか確認してください。\n\n'
                  '${snap.error}',
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                snap.data!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
