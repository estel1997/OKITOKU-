/// `--dart-define=SUPABASE_URL=...` `--dart-define=SUPABASE_ANON_KEY=...` で Supabase を有効化。
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// `--dart-define=USE_COMPOSITE_FLYER_INGESTION=true` で CSV/API/メール/PDF パーサを有効化（ダミーではなく中身を通す）
  static const useCompositeFlyerIngestion = bool.fromEnvironment(
    'USE_COMPOSITE_FLYER_INGESTION',
    defaultValue: false,
  );

  /// `--dart-define=USE_STUB_OCR=true` で ML Kit を使わずスタブ OCR に固定（ユニットテスト等）
  static const useStubOcr = bool.fromEnvironment(
    'USE_STUB_OCR',
    defaultValue: false,
  );

  /// `--dart-define=USE_OCR_PREPROCESS=true` で OCR 前に簡易前処理（グレースケール/コントラスト）を有効化。
  static const useOcrPreprocess = bool.fromEnvironment(
    'USE_OCR_PREPROCESS',
    defaultValue: true,
  );
}
