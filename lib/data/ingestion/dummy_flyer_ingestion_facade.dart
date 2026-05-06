import '../../domain/entities/flyer_offer.dart';
import 'flyer_dummy_seed.dart';
import 'flyer_ingestion_facade.dart';
import 'parsers/csv_flyer_parser.dart';

/// 本格始動まで [kDummyFlyerOffers] を返す。パーサの動作確認時は [CompositeFlyerIngestionFacade] を使う。
class DummyFlyerIngestionFacade implements FlyerIngestionFacade {
  const DummyFlyerIngestionFacade();

  @override
  Future<List<FlyerOffer>> fromCsv(
    String csvText, {
    CsvFlyerColumnMapping? mapping,
  }) async {
    return List<FlyerOffer>.from(kDummyFlyerOffers);
  }

  @override
  Future<List<FlyerOffer>> fromApiJson(String jsonText) async {
    return List<FlyerOffer>.from(kDummyFlyerOffers);
  }

  @override
  Future<List<FlyerOffer>> fromEmail(
    String body, {
    String? subject,
    String? sourceRef,
  }) async {
    return List<FlyerOffer>.from(kDummyFlyerOffers);
  }

  @override
  Future<List<FlyerOffer>> fromPdfBytes(
    List<int> pdfBytes, {
    String? sourceRef,
  }) async {
    return List<FlyerOffer>.from(kDummyFlyerOffers);
  }
}
