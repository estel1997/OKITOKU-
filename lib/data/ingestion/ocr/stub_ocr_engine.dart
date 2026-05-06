import 'dart:typed_data';

import 'ocr_engine.dart';

/// 本番 OCR 未接続時。**画像の画素は読まず**、常に同じプレースホルダー文言を返す。
/// PNG から実名・実価格を得るには [OcrEngine] の本番実装（ML Kit 等）が必要。
class StubOcrEngine implements OcrEngine {
  const StubOcrEngine();

  @override
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (imageBytes.isEmpty) {
      return '';
    }
    // 実画像の内容とは無関係（バイト長 > 0 なら以下を返すだけ）
    return '''
サンエー 那覇店
2026-04-09
牛乳 1L 198円
卵 10個入 248円
食パン 6枚 128円
''';
  }

  @override
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return '';
  }
}
