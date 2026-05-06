import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../data/remote/supabase_store_by_municipality_repository.dart';
import '../../../data/repositories/store_by_municipality_repository.dart';
import '../../../domain/entities/store.dart';

export '../../../data/repositories/store_by_municipality_repository.dart'
    show StoreByMunicipalityRepository;

final storeByMunicipalityRepositoryProvider =
    Provider<StoreByMunicipalityRepository>((ref) {
  if (!AppEnv.hasSupabase) {
    return LocalStoreByMunicipalityRepository();
  }
  return SupabaseStoreByMunicipalityRepository();
});

/// 市区町村名ごとの店舗候補（展開パネル用）。Supabase 時は DB、未設定時はダミーマップ。
final storesInMunicipalityProvider =
    FutureProvider.autoDispose.family<List<Store>, String>(
  (ref, municipalityName) async {
    return ref
        .read(storeByMunicipalityRepositoryProvider)
        .listStoresInMunicipality(municipalityName);
  },
);
