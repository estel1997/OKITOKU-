import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/catalog_product.dart';

const _kCatalogJson = 'phase2_cache_products_v1';

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

  Future<void> write(List<CatalogProduct> products) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(products.map((e) => e.toJson()).toList());
    await p.setString(_kCatalogJson, encoded);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCatalogJson);
  }
}
