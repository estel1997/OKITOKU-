# 未実装・スタブ一覧（全体）

**着手順の整理は [`IMPLEMENTATION_ROADMAP.md`](./IMPLEMENTATION_ROADMAP.md) を参照**（フェーズ A〜E・後回し項目の明示）。

アプリ全体を通じて、**本番で埋める前提の穴**を整理しています。実装済みの抽象（`FlyerIngestionFacade` / `ReceiptIngestionFacade` / `OcrEngine` など）への接続先も併記します。

## OCR・文書解析

| 項目 | 状態 | メモ |
|------|------|------|
| **Android / iOS の OCR** | **Google ML Kit 日本語**（`MlKitOcrEngine`） | `ocrEngineProvider` が実機で自動選択。`USE_STUB_OCR=true` でスタブに固定可能 |
| Web / デスクトップ | `StubOcrEngine`（固定文言） | ML Kit 非対応プラットフォーム |
| 価格表（`名 ¥100`）のテキスト化後 | `ReceiptTextParser` が **`198円`・`¥100`・`名：198円`（コロン区切り）** 等に対応 | OCR 出力の改行・ノイズに応じてルールを足す |
| OCR 精度・前処理 | 軽量前処理を実装済み | `USE_OCR_PREPROCESS=true`（既定ON）でグレースケール・コントラスト調整・最小幅拡大を適用。傾き補正などは継続課題 |
| PDF テキスト抽出 | **`pdfrx`（Pdfium）で全ページ `loadText`** → `EmailFlyerParser` | 画像のみ PDF は空。サーバ側レンダリング＋OCRは別経路 |
| チラシ PDF → 行 | テキスト PDF は上記で行化可能 | レイアウト表構造化・LLM は未 |
| レシート行の高精度抽出 | `ReceiptTextParser` は正規表現ベース | 店舗テンプレ学習、独自ルール DB |
| メール取り込み | `EmailFlyerParser` は緩いスタブ | Inbound parse（SendGrid / SES + Edge Function） |
| API/CSV 以外のフォーマット | 必要に応じてパーサ追加 | 企業ごとに `CsvFlyerColumnMapping` や専用パーサ |

### レシート OCR のフェーズ分け（方針）

- **行が出ない商品**（例: ﾀﾏﾈｷﾞ）: アプリのパーサ以前に **ML Kit がその行のテキストを返していない** 可能性が高い。撮影条件・解像度・前処理の改善か、別エンジン／サーバ OCR が次の打ち手。
- **今すぐ全チェーン最適化は後回しでよい**: サンエー・BIG・maxvalue など **店ごとのレイアウト学習**は、ある程度 **サンプル（マスク済み画像または「OCR 生テキスト＋正解行」のみ）** が揃ってから `ReceiptTextParser` 拡張 or テンプレ ID 付きパイプラインに落とすのが効率的。
- **次フェーズの優先**（本ドキュメント全体の意図）: **チラシ・マスタデータ・同期・UI の本番接続**を進め、レシート OCR の深掘りは **コーパスが揃った段階**でまとめて行う。

## データ・同期

| 項目 | 状態 | メモ |
|------|------|------|
| 行動圏の店 × Supabase 同期 | **`user_active_stores`（匿名 auth）**／起動時に Pull、変更時に Upsert | ダッシュボードで **Anonymous Sign-in** を有効化すること。端末再インストール後は同一匿名セッションで復元可（アカウント連携前はデバイス間共有なし） |
| 店マスタのオフラインキャッシュ | **`PrefsStoreCache`** が `ComposedStoreRepository` 本番経路 | `NoOpStoreLocalCache` は未使用スタブのみ |
| 周辺安値 `NearbyDeal` | **`product_nearby_deals`** + `ComposedNearbyDealRepository`（失敗時はローカルシード） | マイグレーション `20260410150000_nearby_deals_user_active_stores.sql` |
| チラシ `flyer_offers` | **読み取り**（アプリ） | **INSERT** は Edge Function **`ingest-flyer-offers`**（`x-ingest-secret`）。原本 JPG/PDF は **`ingest-flyer-asset`** で Storage へ（`source_ref` 連携） |
| カタログ商品 | ローカル + 合成リポジトリ | 完全リモート同期のポリシー |
| 価格履歴 | **`product_price_observations`** + 商品詳細 UI | 集計・「前回より安い」は別クエリ／将来ジョブ |
| オンボーディング永続化 | **`OnboardingPrefs`（SharedPreferences）** | アカウント連携は未 |

## UI・プロダクト

| 項目 | 状態 | メモ |
|------|------|------|
| 店舗詳細の周辺価格・営業時間 | **チェーン・市区町村**＋**`storeNearbyDealsProvider`（Supabase 時）**／**営業時間は `stores.opening_hours` で表示（マイグレーション適用要）** | `product_nearby_deals` で店舗 ID 突合。近隣カードの商品名表示などは継続改善 |
| 商品詳細の「安くなったら通知」 | **ウォッチ ON でローカル通知 + `user_watch_products` 同期**、通知一覧はサーバ抽出（`list-cheaper-than-last-notifications`）優先、設定画面から `register-push-token` 可能、`notification_events` キュー基盤あり | Edge Function `deliver-notification-events` で FCM 実送信（`FCM_SERVER_KEY` 必須）。APNs 直接送信は継続課題 |
| 候補店の「非表示」 | **`DismissedSuggestedStorePrefs`** で端末永続 | クラウド同期はアカウント連携後に `suggested` / プロファイルへ |
| 設定画面の一部 | **周辺候補店の表示**は `AppSettingsPrefs` で永続化 | **プッシュ**は MVP オフ固定・アカウント未 |
| チラシ一覧 UI | **ホーム**（サマリー・クイックアクション）・**ウォッチ**（上部バナー）から `/flyers` | タブ追加は任意 |
| ホーム「本日の特売」 | `valid_from` / `valid_to` とローカル日付で件数集計 | 「前回より安い」は **本日有効チラシ × カタログ名突合 × 直近観測**で件数化（`homeCheaperThanLastLabelProvider`） |
| **今日の買い物** タブ | チラシチェック・カタログチェック・メモ・移動手段・合計見積もり（案）。**自動車の往復 km は手入力可**（未入力時は那覇周辺目安） | **GPS・店舗間ルート・レシート照合は未**（レギュラー単価は `naha_fuel_reference.dart`） |

## プラットフォーム

| 項目 | 状態 | メモ |
|------|------|------|
| iOS `Info.plist` | **NSCameraUsageDescription / NSPhotoLibraryUsageDescription** 記載済 | 通知まわりは `flutter_local_notifications` 用の追加キーは通常不要 |
| Android 権限 | **CAMERA / READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE(max 32) / POST_NOTIFICATIONS** 記載 | 実機で通知・ギャラリーを要確認 |
| Windows デスクトップ | ギャラリー挙動は未検証 | 主ターゲットは Android / iOS |

## 法務・運用（コード外）

- 大手チラシの自動取得・再配布は **許諾・利用規約** が前提。
- スクレイピングは **ToS・robots・著作権** の確認が必要。
