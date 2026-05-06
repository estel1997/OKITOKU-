import '../../domain/entities/store.dart';
import '../dummy/dummy_data.dart';

/// 行動圏拡張候補（`suggested` 相当）。
abstract class SuggestedStoreRepository {
  Future<List<Store>> listSuggestions();
}

class LocalSuggestedStoreRepository implements SuggestedStoreRepository {
  @override
  Future<List<Store>> listSuggestions() async {
    await Future<void>.delayed(Duration.zero);
    return const [
      Store(
        id: 'sg1',
        name: 'マックスバリュ 糸満店',
        chainId: 'maxvalu',
        openingHours: kLocalDemoOpeningHours,
      ),
      Store(
        id: 'sg2',
        name: 'ザ・ビッグ 豊見城店',
        chainId: 'the_big',
        openingHours: kLocalDemoOpeningHours,
      ),
    ];
  }
}
