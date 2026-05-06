/// リワード広告とアプリ内ポイントの関係をコード上で明示する。
///
/// - リワード広告の視聴完了を現金・円・換金可能価値と直接対応付けない。
/// - 広告由来の付与は別の [reasonCode] / イベント種別で扱い、レシート確定系と混ぜない。
///
/// 実装（広告 SDK 連携）は MVP 外。ここでは方針のみ保持。
abstract final class RewardedAdMonetizationPolicy {
  static const engagementReasonPrefix = 'rewarded_ad_engagement_';

  /// 現金相当のレールに載せないことを表すフラグ（ドキュメント用）。
  static const neverMapsToCashEquivalent = true;
}
