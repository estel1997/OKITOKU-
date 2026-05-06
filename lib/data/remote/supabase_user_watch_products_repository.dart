import 'package:supabase_flutter/supabase_flutter.dart';

/// 匿名ログイン後の `user_watch_products`（ウォッチ商品 ID 配列）。
class SupabaseUserWatchProductsRepository {
  SupabaseUserWatchProductsRepository(this._client);

  final SupabaseClient _client;

  Future<List<String>?> fetchProductIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return null;
    }
    final row = await _client
        .from('user_watch_products')
        .select('product_ids')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    final raw = row['product_ids'];
    if (raw is! List) {
      return const [];
    }
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> upsertProductIds(List<String> ids) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }
    final normalized = ids.toSet().toList()..sort();
    await _client.from('user_watch_products').upsert({
      'user_id': uid,
      'product_ids': normalized,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
