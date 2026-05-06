import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/store.dart';
import 'store_local_cache.dart';

const _kStoresJson = 'phase2_cache_stores_v1';

class PrefsStoreCache implements StoreLocalCache {
  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kStoresJson);
  }

  @override
  Future<List<Store>?> read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStoresJson);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Store.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> write(List<Store> stores) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stores.map((e) => e.toJson()).toList());
    await p.setString(_kStoresJson, encoded);
  }
}
