import '../../domain/entities/store.dart';
import '../dummy/dummy_data.dart';

/// 市区町村単位の店舗一覧（マスタは Supabase `stores.municipality`、オフラインダミーは [kStoresByMunicipality]）。
abstract class StoreByMunicipalityRepository {
  Future<List<Store>> listStoresInMunicipality(String municipalityName);
}

/// `--dart-define` 未設定時。ローカルマップを返す。
class LocalStoreByMunicipalityRepository implements StoreByMunicipalityRepository {
  @override
  Future<List<Store>> listStoresInMunicipality(String municipalityName) async {
    await Future<void>.delayed(Duration.zero);
    return List<Store>.from(storesForMunicipality(municipalityName));
  }
}
