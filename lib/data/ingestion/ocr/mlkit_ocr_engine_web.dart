import 'dart:typed_data';

import 'ocr_engine.dart';

/// Web ビルド用スタブ（`dart:html` 環境では ML Kit を読み込まない）。
class MlKitOcrEngine implements OcrEngine {
  @override
  Future<String> extractTextFromImage(Uint8List imageBytes) async => '';

  @override
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async => '';
}
