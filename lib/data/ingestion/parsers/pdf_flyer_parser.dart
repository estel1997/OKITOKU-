import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../../../domain/entities/flyer_offer.dart';
import 'email_flyer_parser.dart';

/// PDF バイナリ → [FlyerOffer]。**テキストレイヤ付き PDF** は Pdfium で抽出し
/// [EmailFlyerParser] と共有ルールへ流す。画像のみの PDF は空（OCR は別経路）。
///
/// 想定フロー: Storage に PDF アップロード → Edge Function が
/// 同様の抽出 or LLM → [FlyerOffer] へ。
class PdfFlyerParser {
  const PdfFlyerParser();

  /// [pdfBytes] を開き、全ページのプレーンテキストを連結してパースする。
  Future<List<FlyerOffer>> parseBytes(List<int> pdfBytes, {String? sourceRef}) async {
    if (pdfBytes.isEmpty) {
      return const [];
    }
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openData(
        Uint8List.fromList(pdfBytes),
        sourceName: sourceRef ?? 'memory:flyer.pdf',
      );
      final buffer = StringBuffer();
      for (final page in doc.pages) {
        final raw = await page.loadText();
        if (raw != null && raw.fullText.trim().isNotEmpty) {
          buffer.writeln(raw.fullText);
        }
      }
      return parseExtractedText(buffer.toString(), sourceRef: sourceRef);
    } catch (_) {
      return const [];
    } finally {
      await doc?.dispose();
    }
  }

  /// 抽出済みテキストを [FlyerIngestionSource.pdf] としてパースする。
  List<FlyerOffer> parseExtractedText(String text, {String? sourceRef}) {
    return EmailFlyerParser().parseBody(
      text,
      sourceRef: sourceRef,
      source: FlyerIngestionSource.pdf,
    );
  }
}
