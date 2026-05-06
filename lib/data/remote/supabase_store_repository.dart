import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/store.dart';
import '../repositories/store_repository.dart';

/// Supabase `stores` テーブル。`status` カラムが無い場合は全件選択にフォールバック。
class SupabaseStoreRepository implements StoreRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Store>> listActiveStores() async {
    List<dynamic> rows;
    try {
      rows = await _client
          .from('stores')
          .select('id,chain_id,name,municipality,opening_hours')
          .eq('status', 'active');
    } catch (_) {
      rows = await _client
          .from('stores')
          .select('id,chain_id,name,municipality,opening_hours');
    }
    return rows
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => Store(
            id: m['id'].toString(),
            name: m['name'] as String,
            chainId: (m['chain_id'] as String?) ?? '',
            municipality: m['municipality'] as String?,
            openingHours: m['opening_hours'] as String?,
          ),
        )
        .toList();
  }
}
