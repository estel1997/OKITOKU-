import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_state.dart';
import 'core/auth/ensure_anonymous_session.dart';
import 'core/config/app_env.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/persistence/onboarding_prefs.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // flutterfire は android / ios / windows のみ。Web・未対応デスクトップはスキップ。
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } on UnsupportedError {
      // macOS / Linux など firebase_options に無いプラットフォーム
    }
  }
  await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  await LocalNotificationsService.ensureInitialized();

  AppLaunch.onboardingCompleted.value = await OnboardingPrefs.isCompleted();

  if (AppEnv.hasSupabase) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
    await ensureAnonymousSession();
  }

  runApp(
    const ProviderScope(
      child: ShoppingPriceWatchApp(),
    ),
  );
}
