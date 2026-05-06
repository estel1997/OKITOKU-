import '../entities/point_ledger_entry.dart';

abstract class PointLedgerRepository {
  Future<PointLedgerEntry?> findByIdempotencyKey(String idempotencyKey);

  Future<PointLedgerEntry?> findByRewardableEventId(String rewardableEventId);

  Future<void> append(PointLedgerEntry entry);

  Future<List<PointLedgerEntry>> listByUserId(String userId);
}
