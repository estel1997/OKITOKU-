import '../entities/flyer_offer.dart';

/// ローカル日付の [day] に、特売の有効期間が重なるか（`valid_*` 未設定は常に重なるとみなす）
bool flyerOfferValidOnLocalDay(FlyerOffer o, DateTime nowLocal) {
  final dayStart = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final vf = o.validFrom;
  final vt = o.validTo;
  if (vf == null && vt == null) {
    return true;
  }
  final effStart = (vf ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal();
  final effEnd = (vt ?? DateTime(2100, 12, 31, 23, 59, 59)).toLocal();
  return effStart.isBefore(dayEnd) && !effEnd.isBefore(dayStart);
}

int countFlyerOffersValidOnLocalDay(List<FlyerOffer> offers, DateTime nowLocal) {
  return offers.where((o) => flyerOfferValidOnLocalDay(o, nowLocal)).length;
}
