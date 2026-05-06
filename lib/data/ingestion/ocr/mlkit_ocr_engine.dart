import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_env.dart';
import 'ocr_engine.dart';
import 'ocr_image_preprocessor.dart';

/// Google ML Kit テキスト認識（日本語スクリプト）。Android / iOS のみ想定。
///
/// ギャラリー由来の JPEG/PNG バイト列を一時ファイルに書き込み `InputImage.fromFilePath` で処理。
class MlKitOcrEngine implements OcrEngine {
  @override
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return '';
    }
    final bytesForRecognition = AppEnv.useOcrPreprocess
        ? (preprocessForOcr(imageBytes) ?? imageBytes)
        : imageBytes;
    final dir = await getTemporaryDirectory();
    final ext = _guessImageExtension(bytesForRecognition);
    final file = File(
      p.join(
        dir.path,
        'mlkit_ocr_${DateTime.now().millisecondsSinceEpoch}.$ext',
      ),
    );
    TextRecognizer? recognizer;
    try {
      await file.writeAsBytes(bytesForRecognition);
      final inputImage = InputImage.fromFilePath(file.path);
      recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer?.close();
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    return '';
  }

  /// PNG / JPEG のマジックナンバーで拡張子を推定
  String _guessImageExtension(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'jpg';
  }
}
