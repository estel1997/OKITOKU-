import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/flyer_offer.dart';
import '../repositories/flyer_offer_read_repository.dart';

class SupabaseFlyerOfferRepository implements FlyerOfferReadRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<FlyerOffer>> listRecent({int limit = 50}) async {
    final rows = await _client
        .from('flyer_offers')
        .select(
          'id,product_name,chain_id,store_id,price_yen,valid_from,valid_to,ingestion_source,source_ref',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    final list = rows as List<dynamic>;
    return list
        .map((e) => FlyerOffer.fromSupabaseRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
