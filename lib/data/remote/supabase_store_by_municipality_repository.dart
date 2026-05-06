import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/store.dart';
import '../repositories/store_by_municipality_repository.dart';

/// Supabase `stores` を `municipality` で絞り込み。
class SupabaseStoreByMunicipalityRepository implements StoreByMunicipalityRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Store>> listStoresInMunicipality(String municipalityName) async {
    List<dynamic> rows;
    try {
      rows = await _client
          .from('stores')
          .select('id,chain_id,name,municipality,opening_hours')
          .eq('municipality', municipalityName)
          .eq('status', 'active');
    } catch (_) {
      rows = await _client
          .from('stores')
          .select('id,chain_id,name,municipality,opening_hours')
          .eq('municipality', municipalityName);
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
