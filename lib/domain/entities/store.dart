/// 店舗（行動圏・一覧）。Supabase `stores` と対応させる。
class Store {
  const Store({
    required this.id,
    required this.name,
    required this.chainId,
    this.municipality,
    this.openingHours,
  });

  final String id;
  final String name;
  final String chainId;

  /// Supabase `stores.municipality`（ローカル永続のシードには無いことがある）
  final String? municipality;

  /// Supabase `stores.opening_hours`（改行を含む表示用テキスト）
  final String? openingHours;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      chainId: (json['chain_id'] ?? json['chainId']) as String,
      municipality: json['municipality'] as String?,
      openingHours:
          json['opening_hours'] as String? ?? json['openingHours'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chain_id': chainId,
        if (municipality != null) 'municipality': municipality,
        if (openingHours != null) 'opening_hours': openingHours,
      };
}