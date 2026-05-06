import '../../domain/entities/catalog_product.dart';
import '../dummy/dummy_data.dart';
import '../repositories/catalog_product_repository.dart';

class LocalCatalogRepository implements CatalogProductRepository {
  @override
  Future<List<CatalogProduct>> listProducts() async {
    await Future<void>.delayed(Duration.zero);
    return kDummyProducts
        .map(
          (d) => CatalogProduct(
            id: d.id,
            name: d.name,
            categoryCode: d.category.name,
          ),
        )
        .toList();
  }
}
