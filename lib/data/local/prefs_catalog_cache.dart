import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/catalog_product.dart';

const _kCatalogJson = 'phase2_cache_products_v1';
const _kCatalogUpdatedAt = 'phase2_cache_products_updated_at_v1';

class PrefsCatalogCache {
  Future<List<CatalogProduct>?> read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCatalogJson);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) =>
            CatalogProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DateTime?> readUpdatedAt() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCatalogUpdatedAt);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> write(List<CatalogProduct> products) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(products.map((e) => e.toJson()).toList());
    await p.setString(_kCatalogJson, encoded);
    await p.setString(_kCatalogUpdatedAt, DateTime.now().toUtc().toIso8601String());
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCatalogJson);
    await p.remove(_kCatalogUpdatedAt);
  }
}
