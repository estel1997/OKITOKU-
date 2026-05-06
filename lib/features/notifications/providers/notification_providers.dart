import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../domain/entities/catalog_product.dart';
import '../../../domain/entities/flyer_offer.dart';
import '../../../domain/entities/price_observation.dart';
import '../../../domain/flyer/flyer_offer_valid_today.dart';
import '../../../domain/shopping/cheaper_than_last_counter.dart';
import '../../flyers/providers/flyer_offer_providers.dart';
import '../../products/providers/product_providers.dart';

final cheaperThanLastNotificationHitsProvider =
    FutureProvider<List<CheaperThanLastHit>>((ref) async {
  if (AppEnv.hasSupabase) {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'list-cheaper-than-last-notifications',
        method: HttpMethod.post,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final rawHits = data['hits'];
        if (rawHits is List) {
          return rawHits
              .whereType<Map>()
              .map((m) => _hitFromServer(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (_) {
      // Edge Function 未デプロイ時などは既存のクライアント計算へフォールバック。
    }
  }
  final flyers = await ref.watch(flyerOffersProvider.future);
  final products = await ref.watch(catalogProductsProvider.future);
  final observations = await ref.watch(priceObservationsRecentProvider.future);
  final now = DateTime.now();
  return cheaperThanLastHits(
    flyersValidToday: flyers.where((o) => flyerOfferValidOnLocalDay(o, now)).toList(),
    products: products,
    observations: observations,
  );
});

CheaperThanLastHit _hitFromServer(Map<String, dynamic> m) {
  final p = Map<String, dynamic>.from(m['product'] as Map);
  final o = Map<String, dynamic>.from(m['offer'] as Map);
  final last = Map<String, dynamic>.from(m['last_observation'] as Map);
  final nestedStore = last['stores'];
  if (nestedStore is Map) {
    last['stores'] = Map<String, dynamic>.from(nestedStore);
  }
  return CheaperThanLastHit(
    product: CatalogProduct(
      id: p['id'] as String,
      name: p['canonical_name'] as String,
      categoryCode: 'unknown',
    ),
    offer: FlyerOffer.fromSupabaseRow(o),
    lastObservation: PriceObservation.fromSupabaseRow(last),
  );
}
