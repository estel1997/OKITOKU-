import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shopping_price_watch/core/config/app_env.dart';
import 'package:shopping_price_watch/data/ingestion/ocr/mlkit_ocr_engine.dart'
    if (dart.library.html) 'package:shopping_price_watch/data/ingestion/ocr/mlkit_ocr_engine_web.dart';
import 'package:shopping_price_watch/data/ingestion/ocr/ocr_engine.dart';
import 'package:shopping_price_watch/data/ingestion/ocr/stub_ocr_engine.dart';

/// Android / iOS: [MlKitOcrEngine]（日本語）。Web・デスクトップ・`USE_STUB_OCR` はスタブ。
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  if (AppEnv.useStubOcr) {
    return const StubOcrEngine();
  }
  if (kIsWeb) {
    return const StubOcrEngine();
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return MlKitOcrEngine();
  }
  return const StubOcrEngine();
});
