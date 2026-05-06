/// 商品カタログ。Supabase `products` と対応。
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.categoryCode,
  });

  final String id;
  final String name;

  /// DB / enum 名（例: `dairy`）。UI は [ProductCategory] にマップする。
  final String categoryCode;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id'] as String,
      name: (json['canonical_name'] ?? json['name']) as String,
      categoryCode: (json['category'] as String?) ?? 'dailyGoods',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'canonical_name': name,
        'category': categoryCode,
      };
}
