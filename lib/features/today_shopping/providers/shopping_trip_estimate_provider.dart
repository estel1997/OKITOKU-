import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/shopping/shopping_trip_estimate.dart';
import '../../../domain/shopping/shopping_trip_estimator.dart';
import '../../flyers/providers/flyer_offer_providers.dart';
import '../../products/providers/product_providers.dart';
import 'today_shopping_provider.dart';

final shoppingTripEstimateProvider = Provider<ShoppingTripEstimate?>((ref) {
  final shop = ref.watch(todayShoppingProvider);
  final flyers = ref.watch(flyerOffersProvider);
  final cats = ref.watch(catalogProductsProvider);

  return shop.maybeWhen(
    data: (s) {
      return flyers.maybeWhen(
        data: (fl) {
          return cats.maybeWhen(
            data: (cat) => ShoppingTripEstimator().estimate(
              state: s,
              flyerOffers: fl,
              catalogProducts: cat,
              nowLocal: DateTime.now(),
            ),
            orElse: () => null,
          );
        },
        orElse: () => null,
      );
    },
    orElse: () => null,
  );
});
