import 'package:flutter/foundation.dart';

/// 初回オンボーディング完了フラグ（起動時は [OnboardingPrefs] から復元）。
class AppLaunch {
  AppLaunch._();

  static final ValueNotifier<bool> onboardingCompleted = ValueNotifier(false);
}
