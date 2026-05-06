import '../../domain/entities/store.dart';
import '../dummy/dummy_data.dart';
import '../repositories/store_repository.dart';

/// ローカルシード。フェーズ2: [StoreLocalCache] とリモート取得を合成する。
class LocalStoreRepository implements StoreRepository {
  @override
  Future<List<Store>> listActiveStores() async {
    await Future<void>.delayed(Duration.zero);
    return kDummyStores.map(_map).toList();
  }

  Store _map(DummyStore d) => Store(
        id: d.id,
        name: d.name,
        chainId: d.chainId,
        openingHours: d.openingHours,
      );
}
