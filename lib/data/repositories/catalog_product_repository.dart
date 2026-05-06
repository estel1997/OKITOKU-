import '../../domain/entities/catalog_product.dart';

abstract class CatalogProductRepository {
  Future<List<CatalogProduct>> listProducts();
}
