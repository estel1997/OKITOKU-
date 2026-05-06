/// 残高は [delta] の集計で定義する。ユーザー行にポイントを直書きしない。
class PointLedgerEntry {
  const PointLedgerEntry({
    required this.id,
    required this.userId,
    required this.delta,
    required this.reasonCode,
    this.rewardableEventId,
    this.referenceType,
    this.referenceId,
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int delta;
  final String reasonCode;
  final String? rewardableEventId;
  final String? referenceType;
  final String? referenceId;
  final String idempotencyKey;
  final DateTime createdAt;
}

/// レシート確定に伴う付与など、ビジネス上の理由コード。
abstract final class PointReasonCode {
  static const receiptConfirmedGrant = 'receipt_confirmed_grant';
}
