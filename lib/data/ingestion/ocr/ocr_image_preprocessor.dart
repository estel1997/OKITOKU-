import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// OCR 用の軽量前処理。失敗時は null を返して元画像へフォールバックする。
Uint8List? preprocessForOcr(Uint8List imageBytes) {
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    return null;
  }

  var work = decoded;
  if (work.width < 1200) {
    work = img.copyResize(
      work,
      width: 1200,
      interpolation: img.Interpolation.cubic,
    );
  }

  work = img.grayscale(work);
  work = img.adjustColor(work, contrast: 1.25, brightness: 1.05);

  return Uint8List.fromList(img.encodeJpg(work, quality: 92));
}
