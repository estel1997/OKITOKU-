import '../../core/persistence/app_settings_prefs.dart';
import '../../core/persistence/dismissed_suggested_store_prefs.dart';
import '../../domain/entities/store.dart';
import 'suggested_store_repository.dart';

/// 設定の「周辺候補店」OFF と、非表示 ID をローカルで反映。
class FilteringSuggestedStoreRepository implements SuggestedStoreRepository {
  FilteringSuggestedStoreRepository(this._inner);

  final SuggestedStoreRepository _inner;

  @override
  Future<List<Store>> listSuggestions() async {
    if (!await AppSettingsPrefs.getShowSuggestedStores()) {
      return [];
    }
    final all = await _inner.listSuggestions();
    final dismissed = await DismissedSuggestedStorePrefs.readIds();
    return all.where((s) => !dismissed.contains(s.id)).toList();
  }
}
