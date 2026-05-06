import '../../domain/entities/store.dart';

/// 行動圏の active 店舗一覧。フェーズ2で Supabase + ローカルキャッシュ実装に差し替える。
abstract class StoreRepository {
  Future<List<Store>> listActiveStores();
}
