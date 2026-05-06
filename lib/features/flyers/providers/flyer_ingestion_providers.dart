import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../data/ingestion/dummy_flyer_ingestion_facade.dart';
import '../../../data/ingestion/flyer_ingestion_facade.dart';

/// チラシ取り込みの統一入口。
///
/// - **MVP / 許諾前**: [DummyFlyerIngestionFacade]（ダミーデータ）
/// - **検証・本番**: `AppEnv` またはビルドフラグで [CompositeFlyerIngestionFacade] に差し替え
final flyerIngestionFacadeProvider = Provider<FlyerIngestionFacade>((ref) {
  if (AppEnv.useCompositeFlyerIngestion) {
    return CompositeFlyerIngestionFacade();
  }
  return const DummyFlyerIngestionFacade();
});
