import '../../domain/entities/store.dart';
import '../local/store_local_cache.dart';
import 'store_repository.dart';

/// リモート成功時はキャッシュ更新。失敗時はキャッシュ → ローカルシード。
class ComposedStoreRepository implements StoreRepository {
  ComposedStoreRepository({
    required StoreRepository local,
    required StoreRepository remote,
    required StoreLocalCache cache,
  })  : _local = local,
        _remote = remote,
        _cache = cache;

  final StoreRepository _local;
  final StoreRepository _remote;
  final StoreLocalCache _cache;

  @override
  Future<List<Store>> listActiveStores() async {
    try {
      final fresh = await _remote.listActiveStores();
      await _cache.write(fresh);
      return fresh;
    } catch (_) {
      final cached = await _cache.read();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      return _local.listActiveStores();
    }
  }
}
