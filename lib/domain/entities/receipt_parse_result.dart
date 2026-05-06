/// レシート画像（OCR 後テキスト）から得た解析結果。
class ReceiptParseResult {
  const ReceiptParseResult({
    this.inferredStoreName,
    this.purchaseDate,
    required this.lines,
    this.ocrRawPreview,
    this.usedDummyFallback = false,
  });

  final String? inferredStoreName;
  final DateTime? purchaseDate;
  final List<ReceiptLineItem> lines;

  /// デバッグ用（先頭数百文字）
  final String? ocrRawPreview;

  /// 画像なし等で固定ダミーを返した場合
  final bool usedDummyFallback;
}

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.productName,
    this.priceYen,
    this.categoryHint,
    this.originalProductName,
    this.normalizationNote,
    this.normalizationCandidates = const [],
  });

  final String productName;
  final int? priceYen;
  final String? categoryHint;
  final String? originalProductName;
  final String? normalizationNote;
  final List<String> normalizationCandidates;
}
