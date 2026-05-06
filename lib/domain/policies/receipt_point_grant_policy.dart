/// レシート確定イベントからポイント付与を行うか。MVP では false でも [RewardableEvent] は記録する。
class ReceiptPointGrantPolicy {
  const ReceiptPointGrantPolicy({
    this.grantPointsOnReceiptConfirm = false,
    this.pointsPerReceiptConfirm = 0,
  });

  final bool grantPointsOnReceiptConfirm;
  final int pointsPerReceiptConfirm;
}
