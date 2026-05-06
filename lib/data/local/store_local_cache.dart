import '../../domain/entities/store.dart';

/// フェーズ2: `shared_preferences` や Isar で `List<Store>` をキャッシュする。
/// Supabase から取得したスナップショットをオフライン表示する際に使用する。
abstract class StoreLocalCache {
  Future<List<Store>?> read();
  Future<void> write(List<Store> stores);
  Future<void> clear();
}

/// 永続化先がない環境向けのメモリ内キャッシュ実装。
class NoOpStoreLocalCache implements StoreLocalCache {
  List<Store>? _snapshot;

  @override
  Future<void> clear() async {
    _snapshot = null;
  }

  @override
  Future<List<Store>?> read() async {
    final current = _snapshot;
    if (current == null) {
      return null;
    }
    return List<Store>.from(current);
  }

  @override
  Future<void> write(List<Store> stores) async {
    _snapshot = List<Store>.from(stores);
  }
}
