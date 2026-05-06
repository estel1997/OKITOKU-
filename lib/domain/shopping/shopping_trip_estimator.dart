import '../entities/catalog_product.dart';
import '../entities/flyer_offer.dart';
import '../flyer/flyer_offer_valid_today.dart';
import 'car_fuel_profile.dart';
import 'naha_fuel_reference.dart' show kNahaRegularGasolineYenPerLiter;
import 'shopping_route_hint.dart';
import 'shopping_transport.dart';
import 'shopping_trip_estimate.dart';
import 'today_shopping_state.dart';

/// チラシ価格合計 + 移動費（ガソリンは那覇レギュラー参考単価）の簡易見積もり
class ShoppingTripEstimator {
  ShoppingTripEstimator({
    this.regularYenPerLiter = kNahaRegularGasolineYenPerLiter,
  });

  final int regularYenPerLiter;

  static const homeLocationNote =
      '拠点: 那覇市周辺（仮・将来は GPS で自宅からの距離に置き換え）';

  ShoppingTripEstimate estimate({
    required TodayShoppingState state,
    required List<FlyerOffer> flyerOffers,
    required List<CatalogProduct> catalogProducts,
    required DateTime nowLocal,
  }) {
    final todayFlyers = flyerOffers
        .where((o) => flyerOfferValidOnLocalDay(o, nowLocal))
        .toList();

    var flyerSum = 0;
    for (final o in todayFlyers) {
      final q = state.flyerQtyById[o.id] ?? 0;
      if (q <= 0) {
        continue;
      }
      final unit = o.priceYen ?? 0;
      flyerSum += unit * q;
    }

    var catalogUnique = 0;
    var catalogUnits = 0;
    for (final p in catalogProducts) {
      final q = state.catalogQtyById[p.id] ?? 0;
      if (q > 0) {
        catalogUnique++;
        catalogUnits += q;
      }
    }

    final freeformLines = state.freeformText
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .length;

    final transport = state.transport;
    int transportYen = 0;
    var transportNote = '';

    switch (transport) {
      case ShoppingTransport.car:
        final kmPerL = state.carFuelProfile.kmPerLiter;
        final km = state.effectiveRoundTripKm;
        final liters = km / kmPerL;
        transportYen = (liters * regularYenPerLiter).round();
        final kmSource =
            state.customRoundTripKm == null ? '仮の往復（那覇周辺目安）' : '入力した往復';
        transportNote =
            'ガソリン（レギュラー $regularYenPerLiter 円/L・那覇市参考）\n'
            '$kmSource ${km.toStringAsFixed(1)} km・${state.carFuelProfile.label}';
      case ShoppingTransport.monorail:
        transportYen = 300;
        transportNote = 'モノレール等の往復目安（固定・要調整）';
      case ShoppingTransport.walkOrBike:
        transportYen = 0;
        transportNote = '移動費なし';
    }

    final grand = flyerSum + transportYen;

    final routeHint = buildShoppingRouteHint(
      state: state,
      todayFlyers: todayFlyers,
    );

    return ShoppingTripEstimate(
      flyerSubtotalYen: flyerSum,
      catalogItemCount: catalogUnique,
      catalogQtyUnits: catalogUnits,
      transport: transport,
      transportYen: transportYen,
      transportNote: transportNote,
      grandTotalYen: grand,
      homeLocationNote: homeLocationNote,
      freeformLineCount: freeformLines,
      routeHint: routeHint,
    );
  }
}
