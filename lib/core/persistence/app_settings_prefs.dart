import 'package:shared_preferences/shared_preferences.dart';

const _kShowSuggestedStores = 'settings_show_suggested_stores_v1';

/// 設定画面で永続化する UI フラグ（アカウント連携前は端末ローカルのみ）。
abstract final class AppSettingsPrefs {
  static Future<bool> getShowSuggestedStores() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kShowSuggestedStores) ?? true;
  }

  static Future<void> setShowSuggestedStores(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowSuggestedStores, value);
  }
}
