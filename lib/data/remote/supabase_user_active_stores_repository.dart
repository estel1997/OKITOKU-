import 'package:supabase_flutter/supabase_flutter.dart';

/// 匿名ログイン後の `user_active_stores`（行動圏の店 ID 配列）。
class SupabaseUserActiveStoresRepository {
  SupabaseUserActiveStoresRepository(this._client);

  final SupabaseClient _client;

  /// 行が無い場合は `null`。空配列は「クラウド上で明示的に空」。
  Future<List<String>?> fetchStoreIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return null;
    }
    final row = await _client
        .from('user_active_stores')
        .select('store_ids')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    final raw = row['store_ids'];
    if (raw == null) {
      return [];
    }
    return List<String>.from(raw as List<dynamic>);
  }

  Future<void> upsertStoreIds(List<String> ids) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }
    await _client.from('user_active_stores').upsert(
      <String, dynamic>{
        'user_id': uid,
        'store_ids': ids,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
