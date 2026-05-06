import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/shopping/registered_shopping_route.dart';
import '../../../domain/shopping/shopping_trip_estimate.dart';

final registeredShoppingRouteProvider = AsyncNotifierProvider<
    RegisteredShoppingRouteNotifier,
    RegisteredShoppingRoute?>(
  RegisteredShoppingRouteNotifier.new,
);

class RegisteredShoppingRouteNotifier
    extends AsyncNotifier<RegisteredShoppingRoute?> {
  static const _key = 'registered_shopping_route_v1';

  @override
  Future<RegisteredShoppingRoute?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return RegisteredShoppingRoute.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFromEstimate(ShoppingTripEstimate estimate) async {
    final prefs = await SharedPreferences.getInstance();
    final route =
        RegisteredShoppingRoute.fromEstimate(estimate, DateTime.now());
    await prefs.setString(_key, jsonEncode(route.toJson()));
    state = AsyncData(route);
  }

  /// ホームに表示している「登録したお買い物ルート」を削除
  Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData(null);
  }
}
