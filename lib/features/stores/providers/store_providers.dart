import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../data/dummy/dummy_data.dart';
import '../../../data/local/local_store_repository.dart';
import '../../../data/local/prefs_store_cache.dart';
import '../../../data/remote/supabase_store_repository.dart';
import '../../../data/remote/supabase_user_active_stores_repository.dart';
import '../../../data/repositories/composed_store_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../domain/entities/nearby_deal.dart';
import '../../../domain/entities/store.dart';
import '../../products/providers/product_providers.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final local = LocalStoreRepository();
  if (!AppEnv.hasSupabase) {
    return local;
  }
  return ComposedStoreRepository(
    local: local,
    remote: SupabaseStoreRepository(),
    cache: PrefsStoreCache(),
  );
});

List<Store> _hydrateStoresInOrder(List<String> ids, List<Store> catalog) {
  final byId = {for (final s in catalog) s.id: s};
  return [for (final id in ids) byId[id]].whereType<Store>().toList();
}

/// 行動圏に保存された [primary] に、マスタ行の欠けた表示用フィールドを補う。
Store _overlayCatalogFields(Store primary, Store catalogRow) {
  return Store(
    id: primary.id,
    name: primary.name,
    chainId: primary.chainId,
    municipality: primary.municipality ?? catalogRow.municipality,
    openingHours: primary.openingHours ?? catalogRow.openingHours,
  );
}

/// 「頻繁にお買い物をするお店」（ローカル永続）。Supabase 有効時は匿名ユーザーの `user_active_stores` と同期。
final activeStoresProvider =
    AsyncNotifierProvider<ActiveStoresNotifier, List<Store>>(ActiveStoresNotifier.new);

/// 店舗が関係する周辺安値（`product_nearby_deals`）。
final storeNearbyDealsProvider =
    FutureProvider.family<List<NearbyDeal>, String>((ref, storeId) async {
  return ref.read(nearbyDealRepositoryProvider).forStore(storeId);
});

/// マスタの全店（ローカルシード or Supabase `stores`）。店舗タブの「掲載店マスタ」など。
final catalogStoresProvider = FutureProvider.autoDispose<List<Store>>((ref) async {
  return ref.read(storeRepositoryProvider).listActiveStores();
});

/// 行動圏 → なければマスタから ID 解決（深リンク・マスタのみの店用）
final storeByIdProvider =
    FutureProvider.autoDispose.family<Store?, String>((ref, id) async {
  final catalog = await ref.watch(catalogStoresProvider.future);
  Store? catalogMatch;
  for (final s in catalog) {
    if (s.id == id) {
      catalogMatch = s;
      break;
    }
  }

  final active = await ref.watch(activeStoresProvider.future);
  for (final s in active) {
    if (s.id == id) {
      return catalogMatch != null
          ? _overlayCatalogFields(s, catalogMatch)
          : s;
    }
  }
  return catalogMatch;
});

class ActiveStoresNotifier extends AsyncNotifier<List<Store>> {
  static const _key = 'active_stores_v1';

  @override
  Future<List<Store>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    late List<Store> local;
    if (raw == null || raw.isEmpty) {
      // Supabase 利用時は初回を空にし、オンボーディングで選んだ店だけを同期する。
      // ローカル・デモのみのときは従来どおりシード店を入れてすぐ試せるようにする。
      if (AppEnv.hasSupabase) {
        local = [];
      } else {
        local = kDummyStores
            .map(
              (d) => Store(
                id: d.id,
                name: d.name,
                chainId: d.chainId,
                openingHours: d.openingHours,
              ),
            )
            .toList();
      }
      await _persist(prefs, local);
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      local = decoded
          .map((e) => Store.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (!AppEnv.hasSupabase) {
      return local;
    }

    try {
      final cloud = SupabaseUserActiveStoresRepository(Supabase.instance.client);
      final remoteIds = await cloud.fetchStoreIds();
      final catalog = await ref.read(catalogStoresProvider.future);
      if (remoteIds != null) {
        final hydrated = _hydrateStoresInOrder(remoteIds, catalog);
        await _persist(prefs, hydrated);
        return hydrated;
      }
      await cloud.upsertStoreIds(local.map((e) => e.id).toList());
    } catch (_) {}
    return local;
  }

  Future<void> _persist(SharedPreferences prefs, List<Store> stores) async {
    await prefs.setString(
      _key,
      jsonEncode(stores.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> _save(List<Store> stores) async {
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, stores);
    state = AsyncData(stores);
    if (AppEnv.hasSupabase) {
      try {
        await SupabaseUserActiveStoresRepository(Supabase.instance.client)
            .upsertStoreIds(stores.map((e) => e.id).toList());
      } catch (_) {}
    }
  }

  Future<void> removeStore(String id) async {
    final current = await future;
    await _save(current.where((s) => s.id != id).toList());
  }

  Future<void> addStore(Store s) async {
    final current = await future;
    if (current.any((x) => x.id == s.id)) {
      return;
    }
    await _save([...current, s]);
  }
}
