import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/nearby_deal.dart';
import '../repositories/nearby_deal_repository.dart';

/// Supabase `product_nearby_deals`。
class SupabaseNearbyDealRepository implements NearbyDealRepository {
  SupabaseNearbyDealRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<NearbyDeal>> forProduct(String productId) async {
    final rows = await _client
        .from('product_nearby_deals')
        .select(
          'product_id,suggested_store_name,suggested_price,base_store_name,base_price,distance_km',
        )
        .eq('product_id', productId) as List<dynamic>;
    return rows
        .map((e) => NearbyDeal.fromSupabaseRow(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  @override
  Future<List<NearbyDeal>> forStore(String storeId) async {
    final rows = await _client
        .from('product_nearby_deals')
        .select(
          'product_id,suggested_store_name,suggested_price,base_store_name,base_price,distance_km',
        )
        .or('suggested_store_id.eq.$storeId,base_store_id.eq.$storeId') as List<dynamic>;
    return rows
        .map((e) => NearbyDeal.fromSupabaseRow(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }
}
