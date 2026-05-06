import '../entities/rewardable_event.dart';

abstract class RewardableEventRepository {
  Future<RewardableEvent?> findByIdempotencyKey(String idempotencyKey);

  Future<void> save(RewardableEvent event);
}
