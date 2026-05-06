import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/shopping/car_fuel_profile.dart';
import '../../../domain/shopping/shopping_transport.dart';
import '../../../domain/shopping/today_shopping_state.dart';

final todayShoppingProvider =
    AsyncNotifierProvider<TodayShoppingNotifier, TodayShoppingState>(
  TodayShoppingNotifier.new,
);

class TodayShoppingNotifier extends AsyncNotifier<TodayShoppingState> {
  static const _keyV2 = 'today_shopping_v2';
  static const _keyV1 = 'today_shopping_v1';

  @override
  Future<TodayShoppingState> build() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_keyV2);
    var fromV1 = false;
    if (raw == null || raw.isEmpty) {
      raw = prefs.getString(_keyV1);
      fromV1 = raw != null && raw.isNotEmpty;
    }
    if (raw == null || raw.isEmpty) {
      return TodayShoppingState.initial();
    }
    try {
      final parsed = TodayShoppingState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (fromV1) {
        await prefs.setString(_keyV2, jsonEncode(parsed.toJson()));
        await prefs.remove(_keyV1);
      }
      return parsed;
    } catch (_) {
      return TodayShoppingState.initial();
    }
  }

  Future<void> _persist(TodayShoppingState next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyV2, jsonEncode(next.toJson()));
    state = AsyncData(next);
  }

  Future<void> setFreeformText(String text) async {
    final cur = await future;
    await _persist(cur.copyWith(freeformText: text));
  }

  Future<void> setTransport(ShoppingTransport t) async {
    final cur = await future;
    await _persist(cur.copyWith(transport: t));
  }

  Future<void> setCarFuelProfile(CarFuelProfile p) async {
    final cur = await future;
    await _persist(cur.copyWith(carFuelProfile: p));
  }

  Future<void> setMinimizeStoreHops(bool v) async {
    final cur = await future;
    await _persist(cur.copyWith(minimizeStoreHops: v));
  }

  /// [km] が null のときはデフォルト距離に戻す。範囲外は無視。
  Future<void> setCustomRoundTripKm(double? km) async {
    final cur = await future;
    if (km == null) {
      await _persist(cur.copyWith(useDefaultRoundTripKm: true));
      return;
    }
    if (km < 0.5 || km > 500) {
      return;
    }
    await _persist(cur.copyWith(customRoundTripKm: km));
  }

  Future<void> toggleFlyerOffer(String id) async {
    final cur = await future;
    final m = Map<String, int>.from(cur.flyerQtyById);
    if ((m[id] ?? 0) > 0) {
      m.remove(id);
    } else {
      m[id] = 1;
    }
    await _persist(cur.copyWith(flyerQtyById: m));
  }

  Future<void> setFlyerQty(String id, int qty) async {
    final cur = await future;
    final m = Map<String, int>.from(cur.flyerQtyById);
    if (qty <= 0) {
      m.remove(id);
    } else {
      m[id] = qty;
    }
    await _persist(cur.copyWith(flyerQtyById: m));
  }

  Future<void> toggleCatalogProduct(String id) async {
    final cur = await future;
    final m = Map<String, int>.from(cur.catalogQtyById);
    if ((m[id] ?? 0) > 0) {
      m.remove(id);
    } else {
      m[id] = 1;
    }
    await _persist(cur.copyWith(catalogQtyById: m));
  }

  Future<void> setCatalogQty(String id, int qty) async {
    final cur = await future;
    final m = Map<String, int>.from(cur.catalogQtyById);
    if (qty <= 0) {
      m.remove(id);
    } else {
      m[id] = qty;
    }
    await _persist(cur.copyWith(catalogQtyById: m));
  }

  Future<void> clearSelections() async {
    final cur = await future;
    await _persist(
      cur.copyWith(
        flyerQtyById: {},
        catalogQtyById: {},
        freeformText: '',
        minimizeStoreHops: false,
        transport: ShoppingTransport.walkOrBike,
        carFuelProfile: CarFuelProfile.family105,
        useDefaultRoundTripKm: true,
      ),
    );
  }
}
