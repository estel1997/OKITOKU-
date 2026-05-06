import 'shopping_transport.dart';
import 'shopping_trip_estimate.dart';

/// 「お買い物登録完了」時点の見積もり・ルート案（ホーム表示用スナップショット）
class RegisteredShoppingRoute {
  const RegisteredShoppingRoute({
    required this.completedAt,
    required this.flyerSubtotalYen,
    required this.catalogItemCount,
    required this.catalogQtyUnits,
    required this.transportName,
    required this.transportYen,
    required this.transportNote,
    required this.grandTotalYen,
    required this.homeLocationNote,
    required this.freeformLineCount,
    required this.routeHint,
  });

  final DateTime completedAt;
  final int flyerSubtotalYen;
  final int catalogItemCount;
  final int catalogQtyUnits;
  final String transportName;
  final int transportYen;
  final String transportNote;
  final int grandTotalYen;
  final String homeLocationNote;
  final int freeformLineCount;
  final String routeHint;

  factory RegisteredShoppingRoute.fromEstimate(
    ShoppingTripEstimate estimate,
    DateTime completedAt,
  ) {
    return RegisteredShoppingRoute(
      completedAt: completedAt,
      flyerSubtotalYen: estimate.flyerSubtotalYen,
      catalogItemCount: estimate.catalogItemCount,
      catalogQtyUnits: estimate.catalogQtyUnits,
      transportName: estimate.transport.name,
      transportYen: estimate.transportYen,
      transportNote: estimate.transportNote,
      grandTotalYen: estimate.grandTotalYen,
      homeLocationNote: estimate.homeLocationNote,
      freeformLineCount: estimate.freeformLineCount,
      routeHint: estimate.routeHint,
    );
  }

  factory RegisteredShoppingRoute.fromJson(Map<String, dynamic> json) {
    return RegisteredShoppingRoute(
      completedAt: DateTime.parse(json['completed_at'] as String),
      flyerSubtotalYen: (json['flyer_subtotal_yen'] as num).toInt(),
      catalogItemCount: (json['catalog_item_count'] as num).toInt(),
      catalogQtyUnits: (json['catalog_qty_units'] as num).toInt(),
      transportName: json['transport'] as String,
      transportYen: (json['transport_yen'] as num).toInt(),
      transportNote: json['transport_note'] as String,
      grandTotalYen: (json['grand_total_yen'] as num).toInt(),
      homeLocationNote: json['home_location_note'] as String,
      freeformLineCount: (json['freeform_line_count'] as num).toInt(),
      routeHint: json['route_hint'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed_at': completedAt.toIso8601String(),
        'flyer_subtotal_yen': flyerSubtotalYen,
        'catalog_item_count': catalogItemCount,
        'catalog_qty_units': catalogQtyUnits,
        'transport': transportName,
        'transport_yen': transportYen,
        'transport_note': transportNote,
        'grand_total_yen': grandTotalYen,
        'home_location_note': homeLocationNote,
        'freeform_line_count': freeformLineCount,
        'route_hint': routeHint,
      };

  /// UI 共通用に [ShoppingTripEstimate] へ戻す
  ShoppingTripEstimate toEstimate() {
    final transport = ShoppingTransport.values.firstWhere(
      (t) => t.name == transportName,
      orElse: () => ShoppingTransport.walkOrBike,
    );
    return ShoppingTripEstimate(
      flyerSubtotalYen: flyerSubtotalYen,
      catalogItemCount: catalogItemCount,
      catalogQtyUnits: catalogQtyUnits,
      transport: transport,
      transportYen: transportYen,
      transportNote: transportNote,
      grandTotalYen: grandTotalYen,
      homeLocationNote: homeLocationNote,
      freeformLineCount: freeformLineCount,
      routeHint: routeHint,
    );
  }
}
