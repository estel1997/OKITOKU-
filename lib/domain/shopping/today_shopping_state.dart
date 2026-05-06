import 'car_fuel_profile.dart';
import 'naha_fuel_reference.dart';
import 'shopping_transport.dart';

/// 「今日の買い物」画面の入力状態（ローカル永続）
class TodayShoppingState {
  const TodayShoppingState({
    this.flyerQtyById = const {},
    this.catalogQtyById = const {},
    this.freeformText = '',
    this.transport = ShoppingTransport.walkOrBike,
    this.carFuelProfile = CarFuelProfile.family105,
    this.minimizeStoreHops = false,
    this.customRoundTripKm,
  });

  /// チラシ行 ID → 個数（0 または未登録は未選択扱い）
  final Map<String, int> flyerQtyById;
  final Map<String, int> catalogQtyById;

  /// メモ帳（自由記述）
  final String freeformText;
  final ShoppingTransport transport;

  /// 自動車選択時の燃費タイプ
  final CarFuelProfile carFuelProfile;

  /// 店舗回数を抑える（1〜2店舗経由の案を出す）
  final bool minimizeStoreHops;

  /// 自動車のガソリン見積もり用・往復距離（km）。null のときは [kDefaultShoppingRoundTripKm]。
  final double? customRoundTripKm;

  static TodayShoppingState initial() => const TodayShoppingState();

  factory TodayShoppingState.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseQtyMap(Object? raw) {
      if (raw == null) {
        return {};
      }
      if (raw is Map<String, dynamic>) {
        final m = <String, int>{};
        raw.forEach((k, v) {
          final n = (v as num).toInt();
          if (n > 0) {
            m[k] = n;
          }
        });
        return m;
      }
      return {};
    }

    var flyerQty = parseQtyMap(json['flyer_qty']);
    if (flyerQty.isEmpty && json['flyer_ids'] != null) {
      for (final id in json['flyer_ids'] as List<dynamic>) {
        flyerQty[id as String] = 1;
      }
    }

    var catalogQty = parseQtyMap(json['catalog_qty']);
    if (catalogQty.isEmpty && json['catalog_ids'] != null) {
      for (final id in json['catalog_ids'] as List<dynamic>) {
        catalogQty[id as String] = 1;
      }
    }

    CarFuelProfile carFuel = CarFuelProfile.family105;
    final cf = json['car_fuel'] as String?;
    if (cf != null) {
      carFuel = CarFuelProfile.values.firstWhere(
        (v) => v.name == cf,
        orElse: () => CarFuelProfile.family105,
      );
    }

    double? customKm;
    final kmRaw = json['round_trip_km'];
    if (kmRaw is num) {
      customKm = kmRaw.toDouble();
    }

    return TodayShoppingState(
      flyerQtyById: flyerQty,
      catalogQtyById: catalogQty,
      freeformText: json['freeform'] as String? ?? '',
      transport: ShoppingTransport.values.firstWhere(
        (v) => v.name == json['transport'],
        orElse: () => ShoppingTransport.walkOrBike,
      ),
      carFuelProfile: carFuel,
      minimizeStoreHops: json['minimize_stores'] as bool? ?? false,
      customRoundTripKm: customKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'flyer_qty': flyerQtyById,
        'catalog_qty': catalogQtyById,
        'freeform': freeformText,
        'transport': transport.name,
        'car_fuel': carFuelProfile.name,
        'minimize_stores': minimizeStoreHops,
        if (customRoundTripKm != null) 'round_trip_km': customRoundTripKm,
      };

  /// ガソリン見積もりに使う往復 km（カスタムがなければデフォルト定数）。
  double get effectiveRoundTripKm =>
      customRoundTripKm ?? kDefaultShoppingRoundTripKm;

  TodayShoppingState copyWith({
    Map<String, int>? flyerQtyById,
    Map<String, int>? catalogQtyById,
    String? freeformText,
    ShoppingTransport? transport,
    CarFuelProfile? carFuelProfile,
    bool? minimizeStoreHops,
    double? customRoundTripKm,
    bool useDefaultRoundTripKm = false,
  }) {
    return TodayShoppingState(
      flyerQtyById: flyerQtyById ?? this.flyerQtyById,
      catalogQtyById: catalogQtyById ?? this.catalogQtyById,
      freeformText: freeformText ?? this.freeformText,
      transport: transport ?? this.transport,
      carFuelProfile: carFuelProfile ?? this.carFuelProfile,
      minimizeStoreHops: minimizeStoreHops ?? this.minimizeStoreHops,
      customRoundTripKm: useDefaultRoundTripKm
          ? null
          : (customRoundTripKm ?? this.customRoundTripKm),
    );
  }
}
