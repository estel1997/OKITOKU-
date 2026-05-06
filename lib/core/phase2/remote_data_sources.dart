// フェーズ2: Supabase 向けの配置方針
// - HTTP / PostgREST は lib/data/remote/supabase_*_repository.dart
// - キャッシュは PrefsStoreCache / PrefsCatalogCache
// - dart-define SUPABASE_URL / SUPABASE_ANON_KEY でクライアントを起動（main.dart）
