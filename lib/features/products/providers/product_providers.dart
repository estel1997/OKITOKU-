import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../data/local/local_catalog_repository.dart';
import '../../../data/local/local_price_observation_repository.dart';
import '../../../data/local/prefs_catalog_cache.dart';
import '../../../data/remote/supabase_catalog_repository.dart';
import '../../../data/remote/supabase_nearby_deal_repository.dart';
import '../../../data/remote/supabase_price_observation_repository.dart';
import '../../../data/remote/supabase_user_watch_products_repository.dart';
import '../../../data/repositories/catalog_product_repository.dart';
import '../../../data/repositories/composed_catalog_repository.dart';
import '../../../data/repositories/composed_nearby_deal_repository.dart';
import '../../../data/repositories/composed_price_observation_repository.dart';
import '../../../data/repositories/filtering_suggested_store_repository.dart';
import '../../../data/repositories/nearby_deal_repository.dart';
import '../../../data/repositories/price_observation_repository.dart';
import '../../../data/repositories/suggested_store_repository.dart';
import '../../../domain/entities/catalog_product.dart';
import '../../../domain/entities/nearby_deal.dart';
import '../../../domain/entities/price_observation.dart';
import '../../../domain/entities/store.dart';

final catalogProductRepositoryProvider = Provider<CatalogProductRepository>((ref) {
  final local = LocalCatalogRepository();
  if (!AppEnv.hasSupabase) {
    return local;
  }
  return ComposedCatalogRepository(
    local: local,
    remote: SupabaseCatalogRepository(),
    cache: PrefsCatalogCache(),
  );
});

final catalogProductsProvider = FutureProvider<List<CatalogProduct>>((ref) async {
  return ref.read(catalogProductRepositoryProvider).listProducts();
});

final catalogProductProvider =
    FutureProvider.family<CatalogProduct?, String>((ref, productId) async {
  final list = await ref.watch(catalogProductsProvider.future);
  for (final p in list) {
    if (p.id == productId) {
      return p;
    }
  }
  return null;
});

final nearbyDealRepositoryProvider = Provider<NearbyDealRepository>((ref) {
  final local = LocalNearbyDealRepository();
  if (!AppEnv.hasSupabase) {
    return local;
  }
  return ComposedNearbyDealRepository(
    remote: SupabaseNearbyDealRepository(Supabase.instance.client),
    local: local,
  );
});

final nearbyDealsProvider =
    FutureProvider.family<List<NearbyDeal>, String>((ref, productId) async {
  return ref.read(nearbyDealRepositoryProvider).forProduct(productId);
});

final priceObservationRepositoryProvider = Provider<PriceObservationRepository>((ref) {
  final local = LocalPriceObservationRepository();
  if (!AppEnv.hasSupabase) {
    return local;
  }
  return ComposedPriceObservationRepository(
    remote: SupabasePriceObservationRepository(Supabase.instance.client),
    local: local,
  );
});

final priceObservationsForProductProvider =
    FutureProvider.family<List<PriceObservation>, String>((ref, productId) async {
  return ref.read(priceObservationRepositoryProvider).listForProduct(productId);
});

/// ホーム「前回より安い」などの集計用。
final priceObservationsRecentProvider = FutureProvider<List<PriceObservation>>((ref) async {
  return ref.read(priceObservationRepositoryProvider).listRecent(limit: 500);
});

final suggestedStoreRepositoryProvider = Provider<SuggestedStoreRepository>((ref) {
  return FilteringSuggestedStoreRepository(LocalSuggestedStoreRepository());
});

final suggestedStoresProvider = FutureProvider<List<Store>>((ref) async {
  return ref.read(suggestedStoreRepositoryProvider).listSuggestions();
});

class WatchlistNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'watch_product_ids_v1';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final local = raw == null || raw.isEmpty
        ? <String>{}
        : (jsonDecode(raw) as List<dynamic>).map((e) => e as String).toSet();
    if (!AppEnv.hasSupabase) {
      return local;
    }
    try {
      final cloud = SupabaseUserWatchProductsRepository(Supabase.instance.client);
      final remoteIds = await cloud.fetchProductIds();
      if (remoteIds != null) {
        final remote = remoteIds.toSet();
        await _persist(prefs, remote);
        return remote;
      }
      await cloud.upsertProductIds(local.toList());
    } catch (_) {}
    return local;
  }

  /// トグル後、その商品がウォッチに含まれるか。
  Future<bool> toggle(String productId) async {
    final current = await future;
    final next = Set<String>.from(current);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    await _save(next);
    return next.contains(productId);
  }

  Future<void> _persist(SharedPreferences prefs, Set<String> ids) async {
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  Future<void> _save(Set<String> ids) async {
    state = AsyncData(ids);
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, ids);
    if (!AppEnv.hasSupabase) {
      return;
    }
    try {
      await SupabaseUserWatchProductsRepository(Supabase.instance.client)
          .upsertProductIds(ids.toList());
    } catch (_) {}
  }
}

final watchlistIdsProvider =
    AsyncNotifierProvider<WatchlistNotifier, Set<String>>(WatchlistNotifier.new);
