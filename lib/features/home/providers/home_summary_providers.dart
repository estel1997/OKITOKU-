import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../data/dummy/dummy_data.dart';
import '../../../domain/shopping/cheaper_than_last_counter.dart';
import '../../flyers/providers/flyer_offer_providers.dart';
import '../../products/providers/product_providers.dart';

/// ホーム「前回より安い」カード用。チラシ（本日有効）と直近観測を比較。
final homeCheaperThanLastLabelProvider = FutureProvider<String>((ref) async {
  if (!AppEnv.hasSupabase) {
    return '${kHomeSummary.cheaperThanLastCount} 件';
  }
  final flyers = await ref.watch(flyerOffersProvider.future);
  final products = await ref.watch(catalogProductsProvider.future);
  final observations = await ref.watch(priceObservationsRecentProvider.future);
  final n = countCheaperThanLastForHome(
    allFlyers: flyers,
    products: products,
    observations: observations,
    nowLocal: DateTime.now(),
  );
  return '$n 件';
});
