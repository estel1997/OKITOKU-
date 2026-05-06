import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Android / iOS を主ターゲットとしたメインシェル（ボトムナビ + セーフエリア）。
class MobileShellScaffold extends StatelessWidget {
  const MobileShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavSpec(
      label: 'ホーム',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavSpec(
      label: '買い物',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart_rounded,
    ),
    _NavSpec(
      label: 'レシート登録',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavSpec(
      label: 'ウォッチ',
      icon: Icons.visibility_outlined,
      selectedIcon: Icons.visibility_rounded,
    ),
    _NavSpec(
      label: '店舗',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
    ),
    _NavSpec(
      label: '設定',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
