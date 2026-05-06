import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

/// ダッシュボードで「匿名ユーザー」を有効にしていることが前提。失敗時はローカルのみ。
Future<void> ensureAnonymousSession() async {
  if (!AppEnv.hasSupabase) {
    return;
  }
  try {
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) {
      return;
    }
    await client.auth.signInAnonymously();
  } catch (_) {}
}
