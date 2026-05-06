import '../../domain/entities/point_ledger_entry.dart';
import '../../domain/repositories/point_ledger_repository.dart';

class InMemoryPointLedgerRepository implements PointLedgerRepository {
  final Map<String, PointLedgerEntry> _byIdempotency = {};
  final Map<String, PointLedgerEntry> _byRewardableEventId = {};
  final List<PointLedgerEntry> _all = [];

  @override
  Future<PointLedgerEntry?> findByIdempotencyKey(String idempotencyKey) async {
    return _byIdempotency[idempotencyKey];
  }

  @override
  Future<PointLedgerEntry?> findByRewardableEventId(String rewardableEventId) async {
    return _byRewardableEventId[rewardableEventId];
  }

  @override
  Future<void> append(PointLedgerEntry entry) async {
    if (_byIdempotency.containsKey(entry.idempotencyKey)) {
      return;
    }
    _byIdempotency[entry.idempotencyKey] = entry;
    if (entry.rewardableEventId != null) {
      _byRewardableEventId[entry.rewardableEventId!] = entry;
    }
    _all.add(entry);
  }

  @override
  Future<List<PointLedgerEntry>> listByUserId(String userId) async {
    return _all.where((e) => e.userId == userId).toList();
  }
}
