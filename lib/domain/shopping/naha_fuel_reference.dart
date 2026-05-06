/// 那覇市周辺のレギュラーガソリン参考単価（円/L）。
/// 実勢は変動するため、運用時は定期更新または外部API連携を想定。
const int kNahaRegularGasolineYenPerLiter = 172;

/// 仮の往復走行距離（km）。GPS 連携までの MVP 用。
const double kDefaultShoppingRoundTripKm = 18;

/// 仮の燃費（L/100km）。コンパクトカー目安。
const double kDefaultFuelConsumptionLPer100km = 8;
