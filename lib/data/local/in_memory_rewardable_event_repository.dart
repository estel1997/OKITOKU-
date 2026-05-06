import '../../domain/entities/rewardable_event.dart';
import '../../domain/repositories/rewardable_event_repository.dart';

class InMemoryRewardableEventRepository implements RewardableEventRepository {
  final Map<String, RewardableEvent> _byIdempotency = {};

  @override
  Future<RewardableEvent?> findByIdempotencyKey(String idempotencyKey) async {
    return _byIdempotency[idempotencyKey];
  }

  @override
  Future<void> save(RewardableEvent event) async {
    _byIdempotency[event.idempotencyKey] = event;
  }
}
