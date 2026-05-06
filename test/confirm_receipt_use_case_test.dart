import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_price_watch/data/local/in_memory_point_ledger_repository.dart';
import 'package:shopping_price_watch/data/local/in_memory_receipt_confirm_repository.dart';
import 'package:shopping_price_watch/data/local/in_memory_rewardable_event_repository.dart';
import 'package:shopping_price_watch/domain/policies/receipt_point_grant_policy.dart';
import 'package:shopping_price_watch/domain/services/ledger_balance.dart';
import 'package:shopping_price_watch/domain/usecases/confirm_receipt_use_case.dart';

void main() {
  test('confirm records rewardable event; ledger optional by policy', () async {
    final receipt = InMemoryReceiptConfirmRepository();
    final events = InMemoryRewardableEventRepository();
    final ledger = InMemoryPointLedgerRepository();

    final uc = ConfirmReceiptUseCase(
      receiptConfirmRepository: receipt,
      rewardableEventRepository: events,
      pointLedgerRepository: ledger,
      policy: const ReceiptPointGrantPolicy(
        grantPointsOnReceiptConfirm: true,
        pointsPerReceiptConfirm: 10,
      ),
    );

    final first = await uc.execute(userId: 'u1', draftReceiptId: 'draft-1');
    expect(first.rewardableEvent.sourceReceiptId, 'draft-1');
    expect(first.ledgerEntry?.delta, 10);

    final second = await uc.execute(userId: 'u1', draftReceiptId: 'draft-1');
    expect(second.rewardableEvent.id, first.rewardableEvent.id);
    expect(second.ledgerEntry?.delta, 10);

    final balance = balanceFromLedger(await ledger.listByUserId('u1'));
    expect(balance, 10);
  });

  test('no points when grant policy off', () async {
    final uc = ConfirmReceiptUseCase(
      receiptConfirmRepository: InMemoryReceiptConfirmRepository(),
      rewardableEventRepository: InMemoryRewardableEventRepository(),
      pointLedgerRepository: InMemoryPointLedgerRepository(),
      policy: const ReceiptPointGrantPolicy(),
    );

    final out = await uc.execute(userId: 'u1', draftReceiptId: 'draft-2');
    expect(out.ledgerEntry, isNull);
  });
}
