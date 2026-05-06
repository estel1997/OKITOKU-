import '../../../domain/entities/point_ledger_entry.dart';
import '../../../domain/repositories/point_ledger_repository.dart';
import '../../../domain/services/ledger_balance.dart';

/// 表示用の残高。真実は台帳の集計。
class PointBalanceService {
  PointBalanceService(this._ledger);

  final PointLedgerRepository _ledger;

  Future<int> currentBalance(String userId) async {
    final rows = await _ledger.listByUserId(userId);
    return balanceFromLedger(rows);
  }

  Future<List<PointLedgerEntry>> history(String userId) async {
    final rows = await _ledger.listByUserId(userId);
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }
}
