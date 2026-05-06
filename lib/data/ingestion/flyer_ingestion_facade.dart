import '../../domain/entities/flyer_offer.dart';
import 'parsers/api_json_flyer_parser.dart';
import 'parsers/csv_flyer_parser.dart';
import 'parsers/email_flyer_parser.dart';
import 'parsers/pdf_flyer_parser.dart';

/// チラシ・特売の取り込み入口。CSV / API(JSON) / メール / PDF いずれも **正規化後は同一モデル**。
abstract class FlyerIngestionFacade {
  Future<List<FlyerOffer>> fromCsv(
    String csvText, {
    CsvFlyerColumnMapping? mapping,
  });

  Future<List<FlyerOffer>> fromApiJson(String jsonText);

  Future<List<FlyerOffer>> fromEmail(
    String body, {
    String? subject,
    String? sourceRef,
  });

  Future<List<FlyerOffer>> fromPdfBytes(
    List<int> pdfBytes, {
    String? sourceRef,
  });
}

/// 各パーサを束ねる本番向け実装（バッチ・Edge Function からも利用可）
class CompositeFlyerIngestionFacade implements FlyerIngestionFacade {
  CompositeFlyerIngestionFacade({
    CsvFlyerParser? csv,
    ApiJsonFlyerParser? api,
    EmailFlyerParser? email,
    PdfFlyerParser? pdf,
  })  : _csv = csv ?? CsvFlyerParser(),
        _api = api ?? ApiJsonFlyerParser(),
        _email = email ?? EmailFlyerParser(),
        _pdf = pdf ?? const PdfFlyerParser();

  final CsvFlyerParser _csv;
  final ApiJsonFlyerParser _api;
  final EmailFlyerParser _email;
  final PdfFlyerParser _pdf;

  @override
  Future<List<FlyerOffer>> fromCsv(
    String csvText, {
    CsvFlyerColumnMapping? mapping,
  }) async {
    return _csv.parse(csvText, mapping: mapping);
  }

  @override
  Future<List<FlyerOffer>> fromApiJson(String jsonText) async {
    return _api.parseString(jsonText);
  }

  @override
  Future<List<FlyerOffer>> fromEmail(
    String body, {
    String? subject,
    String? sourceRef,
  }) async {
    return _email.parseBody(body, subject: subject, sourceRef: sourceRef);
  }

  @override
  Future<List<FlyerOffer>> fromPdfBytes(
    List<int> pdfBytes, {
    String? sourceRef,
  }) async {
    final fromOcr = await _pdf.parseBytes(pdfBytes, sourceRef: sourceRef);
    if (fromOcr.isNotEmpty) {
      return fromOcr;
    }
    return const [];
  }
}
