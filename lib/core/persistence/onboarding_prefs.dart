import 'package:shared_preferences/shared_preferences.dart';

/// 初回オンボーディング完了フラグ（端末ローカル）。
abstract final class OnboardingPrefs {
  static const _key = 'onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
