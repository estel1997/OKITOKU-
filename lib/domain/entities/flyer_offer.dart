/// チラシ由来の特売1行（正規化後）。各チャネルはここへ収束させる。
class FlyerOffer {
  const FlyerOffer({
    required this.id,
    required this.productNameOrSku,
    this.chainId,
    this.storeId,
    this.priceYen,
    this.validFrom,
    this.validTo,
    required this.ingestionSource,
    this.sourceRef,
  });

  factory FlyerOffer.fromSupabaseRow(Map<String, dynamic> m) {
    return FlyerOffer(
      id: m['id'].toString(),
      productNameOrSku: m['product_name'] as String,
      chainId: m['chain_id'] as String?,
      storeId: m['store_id'] as String?,
      priceYen: m['price_yen'] as int?,
      validFrom: _ts(m['valid_from']),
      validTo: _ts(m['valid_to']),
      ingestionSource: flyerIngestionSourceFromStorage(m['ingestion_source'] as String?),
      sourceRef: m['source_ref'] as String?,
    );
  }

  final String id;
  final String productNameOrSku;
  final String? chainId;
  final String? storeId;
  final int? priceYen;
  final DateTime? validFrom;
  final DateTime? validTo;

  /// 取り込み経路（監査・再処理用）
  final FlyerIngestionSource ingestionSource;

  /// 元ファイル名・メール Message-ID・API リクエストキーなど
  final String? sourceRef;
}

DateTime? _ts(Object? v) {
  if (v == null) {
    return null;
  }
  return DateTime.tryParse(v.toString());
}

/// 提供形態（どのアダプタ経由か）
enum FlyerIngestionSource {
  dummy,
  csv,
  apiJson,
  email,
  pdf,
  manual,
  receiptImage,
}

FlyerIngestionSource flyerIngestionSourceFromStorage(String? raw) {
  if (raw == null || raw.isEmpty) {
    return FlyerIngestionSource.apiJson;
  }
  for (final v in FlyerIngestionSource.values) {
    if (v.name == raw) {
      return v;
    }
  }
  return FlyerIngestionSource.apiJson;
}
