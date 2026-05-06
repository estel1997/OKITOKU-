import 'package:uuid/uuid.dart';

import '../../core/reward_idempotency.dart';
import '../entities/point_ledger_entry.dart';
import '../entities/rewardable_event.dart';
import '../policies/receipt_point_grant_policy.dart';
import '../repositories/point_ledger_repository.dart';
import '../repositories/receipt_confirm_repository.dart';
import '../repositories/rewardable_event_repository.dart';

/// レシート確定を [RewardableEvent] として記録し、ポリシーに応じて台帳へ付与する。
class ConfirmReceiptUseCase {
  ConfirmReceiptUseCase({
    required ReceiptConfirmRepository receiptConfirmRepository,
    required RewardableEventRepository rewardableEventRepository,
    required PointLedgerRepository pointLedgerRepository,
    ReceiptPointGrantPolicy policy = const ReceiptPointGrantPolicy(),
    Uuid? uuid,
  })  : _receipt = receiptConfirmRepository,
        _events = rewardableEventRepository,
        _ledger = pointLedgerRepository,
        _policy = policy,
        _uuid = uuid ?? const Uuid();

  final ReceiptConfirmRepository _receipt;
  final RewardableEventRepository _events;
  final PointLedgerRepository _ledger;
  final ReceiptPointGrantPolicy _policy;
  final Uuid _uuid;

  Future<ConfirmReceiptOutcome> execute({
    required String userId,
    required String draftReceiptId,
  }) async {
    final receiptId = await _receipt.confirmReceipt(
      userId: userId,
      draftReceiptId: draftReceiptId,
    );

    final idempotencyKey = rewardableEventIdempotencyKey(
      userId: userId,
      receiptId: receiptId,
      eventType: RewardableEventType.receiptConfirmed,
    );

    final existing = await _events.findByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      final ledger = await _ledger.findByRewardableEventId(existing.id);
      return ConfirmReceiptOutcome(
        receiptId: receiptId,
        rewardableEvent: existing,
        ledgerEntry: ledger,
      );
    }

    final eventId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final event = RewardableEvent(
      id: eventId,
      userId: userId,
      eventType: RewardableEventType.receiptConfirmed,
      sourceReceiptId: receiptId,
      payload: const <String, Object?>{},
      idempotencyKey: idempotencyKey,
      createdAt: now,
    );
    await _events.save(event);

    PointLedgerEntry? ledgerEntry;
    if (_policy.grantPointsOnReceiptConfirm && _policy.pointsPerReceiptConfirm > 0) {
      final ledgerKey = ledgerIdempotencyKeyFromEvent(
        rewardableEventId: eventId,
        reasonCode: PointReasonCode.receiptConfirmedGrant,
      );
      final dup = await _ledger.findByIdempotencyKey(ledgerKey);
      if (dup == null) {
        ledgerEntry = PointLedgerEntry(
          id: _uuid.v4(),
          userId: userId,
          delta: _policy.pointsPerReceiptConfirm,
          reasonCode: PointReasonCode.receiptConfirmedGrant,
          rewardableEventId: eventId,
          idempotencyKey: ledgerKey,
          createdAt: now,
        );
        await _ledger.append(ledgerEntry);
      } else {
        ledgerEntry = dup;
      }
    }

    return ConfirmReceiptOutcome(
      receiptId: receiptId,
      rewardableEvent: event,
      ledgerEntry: ledgerEntry,
    );
  }
}

class ConfirmReceiptOutcome {
  const ConfirmReceiptOutcome({
    required this.receiptId,
    required this.rewardableEvent,
    this.ledgerEntry,
  });

  final String receiptId;
  final RewardableEvent rewardableEvent;
  final PointLedgerEntry? ledgerEntry;
}
