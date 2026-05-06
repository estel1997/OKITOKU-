import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

/// FCM トークンを取得し、Supabase Edge Function `register-push-token` へ登録する。
abstract final class PushTokenRegistrationService {
  /// Push通知の有効/無効を Supabase に反映する。
  ///
  /// - 有効化: パーミッション要求 → FCM トークン取得 → `enabled=true` で登録
  /// - 無効化: FCM トークン取得 → `enabled=false` で更新
  static Future<String> setEnabled({required bool enabled}) async {
    if (!AppEnv.hasSupabase) {
      throw StateError('Supabase が未設定です。');
    }

    await _ensureFirebaseInitialized();
    final messaging = FirebaseMessaging.instance;
    if (enabled) {
      await messaging.requestPermission();
    }
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('FCM トークンを取得できませんでした。');
    }

    await Supabase.instance.client.functions.invoke(
      'register-push-token',
      method: HttpMethod.post,
      body: {
        'token': token,
        'platform': _platformName(),
        'enabled': enabled,
      },
    );
    return token;
  }

  /// 互換: 「登録」ボタンから利用。
  static Future<String> registerCurrentDeviceToken() async {
    return setEnabled(enabled: true);
  }

  static Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    try {
      await Firebase.initializeApp();
    } catch (e) {
      throw StateError(
        'Firebase 初期化に失敗しました。google-services.json / GoogleService-Info.plist の設定を確認してください。($e)',
      );
    }
  }

  static String _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'web',
    };
  }
}
