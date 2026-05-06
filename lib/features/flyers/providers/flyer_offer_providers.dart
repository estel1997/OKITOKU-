import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../data/local/local_flyer_offer_repository.dart';
import '../../../data/remote/supabase_flyer_offer_repository.dart';
import '../../../data/repositories/flyer_offer_read_repository.dart';
import '../../../domain/entities/flyer_offer.dart';
import '../../../domain/flyer/flyer_offer_valid_today.dart';

final flyerOfferReadRepositoryProvider = Provider<FlyerOfferReadRepository>((ref) {
  if (!AppEnv.hasSupabase) {
    return LocalFlyerOfferRepository();
  }
  return SupabaseFlyerOfferRepository();
});

/// チラシ特売一覧（Supabase `flyer_offers` またはローカルダミー）
final flyerOffersProvider = FutureProvider<List<FlyerOffer>>((ref) async {
  return ref.read(flyerOfferReadRepositoryProvider).listRecent(limit: 50);
});

/// 本日（端末ローカル日付）に有効な特売件数（`valid_from` / `valid_to` 未設定は全日有効）
final flyerOffersValidTodayCountLabelProvider = Provider<String>((ref) {
  final async = ref.watch(flyerOffersProvider);
  return async.when(
    data: (list) =>
        '${countFlyerOffersValidOnLocalDay(list, DateTime.now())} 件',
    loading: () => '…',
    error: (_, __) => '—',
  );
});
