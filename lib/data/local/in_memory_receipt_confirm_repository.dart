import '../../domain/repositories/receipt_confirm_repository.dart';

/// 開発用: 確定でそのまま draft ID を receipt ID として扱う。
class InMemoryReceiptConfirmRepository implements ReceiptConfirmRepository {
  InMemoryReceiptConfirmRepository();

  final Set<String> _confirmed = {};

  @override
  Future<String> confirmReceipt({
    required String userId,
    required String draftReceiptId,
  }) async {
    _confirmed.add(draftReceiptId);
    return draftReceiptId;
  }
}
