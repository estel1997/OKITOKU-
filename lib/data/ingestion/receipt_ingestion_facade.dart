import 'dart:typed_data';

import '../../domain/entities/receipt_parse_result.dart';
import 'ocr/ocr_engine.dart';
import 'parsers/receipt_item_normalizer.dart';
import 'parsers/receipt_text_parser.dart';

/// レシート画像 → 解析結果（OCR + ルールパーサ）
abstract class ReceiptIngestionFacade {
  Future<ReceiptParseResult> fromImageBytes(Uint8List bytes, {String? debugLabel});
}

class CompositeReceiptIngestionFacade implements ReceiptIngestionFacade {
  CompositeReceiptIngestionFacade({
    required OcrEngine ocr,
    ReceiptTextParser? parser,
    ReceiptItemNormalizer? normalizer,
  })  : _ocr = ocr,
        _parser = parser ?? ReceiptTextParser(),
        _normalizer = normalizer ?? ReceiptItemNormalizer();

  final OcrEngine _ocr;
  final ReceiptTextParser _parser;
  final ReceiptItemNormalizer _normalizer;

  @override
  Future<ReceiptParseResult> fromImageBytes(
    Uint8List bytes, {
    String? debugLabel,
  }) async {
    final text = await _ocr.extractTextFromImage(bytes);
    final parsed = _parser.parse(text);
    if (parsed.lines.isEmpty && text.trim().isEmpty) {
      return ReceiptParseResult(
        lines: const [
          ReceiptLineItem(productName: '（画像からテキストを取得できませんでした）', priceYen: null),
        ],
        ocrRawPreview: debugLabel,
        usedDummyFallback: true,
      );
    }
    final normalizedLines = parsed.lines.map(_normalizer.normalize).toList();
    return ReceiptParseResult(
      inferredStoreName: parsed.inferredStoreName,
      purchaseDate: parsed.purchaseDate,
      lines: normalizedLines,
      ocrRawPreview: parsed.ocrRawPreview,
      usedDummyFallback: parsed.usedDummyFallback,
    );
  }
}

/// 画像なしフロー用の固定結果
class DummyReceiptIngestionFacade implements ReceiptIngestionFacade {
  const DummyReceiptIngestionFacade();

  @override
  Future<ReceiptParseResult> fromImageBytes(
    Uint8List bytes, {
    String? debugLabel,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ReceiptParseResult(
      inferredStoreName: 'サンエー 那覇店',
      purchaseDate: DateTime(2026, 4, 2),
      lines: const [
        ReceiptLineItem(productName: '牛乳 1L', priceYen: 198, categoryHint: '乳製品'),
        ReceiptLineItem(productName: '卵 10個入', priceYen: 248, categoryHint: '卵'),
        ReceiptLineItem(productName: '食パン 6枚', priceYen: 128, categoryHint: 'パン'),
      ],
      usedDummyFallback: true,
    );
  }
}
