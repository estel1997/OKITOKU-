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
    try {
      final fresh = await _remote.listProducts();
      await _cache.write(fresh);
      return fresh;
    } catch (_) {
      final cached = await _cache.read();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      return _local.listProducts();
    }
  }
}
