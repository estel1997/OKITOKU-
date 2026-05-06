import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'mobile_shell_scaffold.dart';
import '../features/area/area_expansion_screen.dart';
import '../features/flyers/flyer_offers_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notification_list_screen.dart';
import '../features/onboarding/onboarding_area_setup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_watch_screen.dart';
import '../features/products/register_by_category_screen.dart';
import '../features/receipt/receipt_capture_screen.dart';
import '../features/receipt/receipt_processing_screen.dart';
import '../domain/entities/receipt_parse_result.dart';
import '../features/receipt/receipt_review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today_shopping/registered_shopping_route_screen.dart';
import '../features/today_shopping/today_shopping_screen.dart';
import '../features/stores/remove_stores_screen.dart';
import '../features/stores/store_detail_screen.dart';
import '../features/stores/store_list_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  refreshListenable: AppLaunch.onboardingCompleted,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/products/watch') {
      return '/watch';
    }
    final done = AppLaunch.onboardingCompleted.value;
    if (!done && !path.startsWith('/onboarding')) {
      return '/onboarding';
    }
    if (done && path.startsWith('/onboarding')) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingAreaSetupScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MobileShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today-shopping',
              builder: (context, state) => const TodayShoppingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/receipt',
              builder: (context, state) => const ReceiptCaptureScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/watch',
              builder: (context, state) => const ProductWatchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stores',
              builder: (context, state) => const StoreListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/receipt/capture',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) => '/receipt',
    ),
    GoRoute(
      path: '/receipt/processing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        return ReceiptProcessingScreen(
          imageBytes: extra is Uint8List ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/receipt/review',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        return ReceiptReviewScreen(
          parseResult: extra is ReceiptParseResult ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/products/register-by-category',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterByCategoryScreen(),
    ),
    GoRoute(
      path: '/products/:productId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['productId']!;
        return ProductDetailScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/stores/:storeId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['storeId']!;
        return StoreDetailScreen(storeId: id);
      },
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationListScreen(),
    ),
    GoRoute(
      path: '/area-expansion',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AreaExpansionScreen(),
    ),
    GoRoute(
      path: '/remove-stores',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemoveStoresScreen(),
    ),
    GoRoute(
      path: '/flyers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FlyerOffersScreen(),
    ),
    GoRoute(
      path: '/registered-shopping-route',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisteredShoppingRouteScreen(),
    ),
  ],
);
