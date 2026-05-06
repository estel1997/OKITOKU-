/// レシート確定の永続化（明細・価格観測など既存ドメイン）。実装は Supabase / ローカルに委譲。
abstract class ReceiptConfirmRepository {
  /// 確定済みレシート ID を返す。冪等に同一 ID を返してよい。
  Future<String> confirmReceipt({
    required String userId,
    required String draftReceiptId,
  });
}
