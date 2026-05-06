enum ProductCategory {
  eggs,
  dairy,  bread,
  rice,
  tofu,
  vegetables,
  meat,
  canned,
  beverage,
  dailyGoods,
}

/// DB / API の `category` 文字列（enum 名と一致）から変換。
ProductCategory? tryParseProductCategory(String code) {
  for (final c in ProductCategory.values) {
    if (c.name == code) {
      return c;
    }
  }
  return null;
}

extension ProductCategoryLabel on ProductCategory {  String get jaLabel {
    switch (this) {
      case ProductCategory.eggs:
        return '卵';
      case ProductCategory.dairy:
        return '乳製品';
      case ProductCategory.bread:
        return 'パン';
      case ProductCategory.rice:
        return '米';
      case ProductCategory.tofu:
        return '豆腐';
      case ProductCategory.vegetables:
        return '野菜';
      case ProductCategory.meat:
        return '肉';
      case ProductCategory.canned:
        return '缶詰';
      case ProductCategory.beverage:
        return '飲料';
      case ProductCategory.dailyGoods:
        return '日用品';
    }
  }
}
