import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/catalog_product.dart';
import '../repositories/catalog_product_repository.dart';

/// Supabase `products` テーブル。
class SupabaseCatalogRepository implements CatalogProductRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<CatalogProduct>> listProducts() async {
    final rows = await _client
        .from('products')
        .select('id,canonical_name,category') as List<dynamic>;
    return rows
        .map((e) => CatalogProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
