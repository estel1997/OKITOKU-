import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/price_observation.dart';
import '../repositories/price_observation_repository.dart';

/// Supabase `product_price_observations`（店名は `stores` 外部キー参照）。
class SupabasePriceObservationRepository implements PriceObservationRepository {
  SupabasePriceObservationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PriceObservation>> listForProduct(String productId) async {
    final rows = await _client
        .from('product_price_observations')
        .select('id, product_id, store_id, price_yen, observed_at, source, stores(name)')
        .eq('product_id', productId)
        .order('observed_at', ascending: false) as List<dynamic>;
    return rows
        .map((e) => PriceObservation.fromSupabaseRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<PriceObservation>> listRecent({int limit = 500}) async {
    final rows = await _client
        .from('product_price_observations')
        .select('id, product_id, store_id, price_yen, observed_at, source, stores(name)')
        .order('observed_at', ascending: false)
        .limit(limit) as List<dynamic>;
    return rows
        .map((e) => PriceObservation.fromSupabaseRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
