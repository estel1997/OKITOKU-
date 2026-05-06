import 'dart:typed_data';

/// 画像・PDF からテキストを取り出す（ML Kit / Vision / 外部 API などに差し替え）
abstract class OcrEngine {
  Future<String> extractTextFromImage(Uint8List imageBytes);

  /// PDF はバイナリのまま。実装側で pdf パッケージ or サーバ任せ。
  Future<String> extractTextFromPdf(Uint8List pdfBytes);
}
