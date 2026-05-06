/// 報酬ルールの差し込み口。レシート確定は [eventType] = [RewardableEventType.receiptConfirmed]。
class RewardableEvent {
  const RewardableEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    this.sourceReceiptId,
    required this.payload,
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String eventType;
  final String? sourceReceiptId;
  final Map<String, Object?> payload;
  final String idempotencyKey;
  final DateTime createdAt;
}

/// イベント種別（DB / API と同じ文字列を使う）。
abstract final class RewardableEventType {
  static const receiptConfirmed = 'receipt_confirmed';
}
