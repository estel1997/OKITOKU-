import '../entities/point_ledger_entry.dart';

/// 台帳から残高を算出する。キャッシュがあっても真実のソースは台帳行。
int balanceFromLedger(Iterable<PointLedgerEntry> entries) {
  var sum = 0;
  for (final e in entries) {
    sum += e.delta;
  }
  return sum;
}
