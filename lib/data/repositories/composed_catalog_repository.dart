import '../../domain/entities/catalog_product.dart';
import '../local/prefs_catalog_cache.dart';
import 'catalog_product_repository.dart';

class ComposedCatalogRepository implements CatalogProductRepository {
  ComposedCatalogRepository({
    required CatalogProductRepository local,
    required CatalogProductRepository remote,
    required PrefsCatalogCache cache,
  })  : _local = local,
        _remote = remote,
        _cache = cache;

  final CatalogProductRepository _local;
  final CatalogProductRepository _remote;
  final PrefsCatalogCache _cache;

  @override
  Future<List<CatalogProduct>> listProducts() async {
    // まずキャッシュ（あれば）を返し、裏でリモート更新（SWR）。
    // これにより UI が即座に描画でき、通信失敗時も前回キャッシュを維持できる。
    final cached = await _cache.read();
    if (cached != null && cached.isNotEmpty) {
      () async {
        try {
          final fresh = await _remote.listProducts();
          await _cache.write(fresh);
        } catch (_) {
          // Keep cache.
        }
      }();
      return cached;
    }

    // キャッシュが無ければリモート優先。失敗時はローカルシード。
    try {
      final fresh = await _remote.listProducts();
      await _cache.write(fresh);
      return fresh;
    } catch (_) {
      return _local.listProducts();
    }
  }
}
