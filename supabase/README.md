# Supabase（バックエンド・マスタ）

## マイグレーション

`supabase/migrations/` を **日付順** に適用してください。

1. `20260403120000_phase2_stores_products.sql` — `stores` / `products` と匿名 read 用 RLS
2. `20260409120000_municipalities_master.sql` — **市区町村マスタ** `municipalities`（41 件）、店舗の `municipality` 外部キー、シード店の追加
3. `20260409140000_flyer_offers.sql` — `flyer_offers`（チラシ特売行）
4. `20260410150000_nearby_deals_user_active_stores.sql` — `product_nearby_deals`（周辺安値）、`user_active_stores`（匿名ユーザーの行動圏 ID）、候補店用 `stores` シード（sg1/sg2）
5. `20260421120000_product_price_observations.sql` — **`product_price_observations`**（商品の観測価格履歴・店舗 FK）。商品詳細の「価格履歴」に使用。INSERT は将来 Edge / バッチ用（現状はマイグレーションのシードのみ）
6. `20260421130000_cheaper_than_last_demo_observations.sql` — ホーム「前回より安い」デモ用の観測行追加（任意）
7. `20260421143000_flyer_sources_bucket.sql` — Storage バケット `flyer_sources`（JPG / PDF 原本置き場）
8. `20260506120000_store_opening_hours.sql` — **`stores.opening_hours`**（営業時間・定休の表示用テキスト、改行可）と既存店シード

CLI 例:

```bash
supabase db push
```

または Supabase ダッシュボードの **SQL Editor** に各ファイルの内容を貼り付けて実行します。

## マスタ設計（要点）

| テーブル | 役割 |
|---------|------|
| `municipalities` | 沖縄県 41 市区町村。`name` はアプリの `kOkinawaMunicipalitySections` と同一文字列。 |
| `stores` | 店舗。`municipality` は `municipalities.name` を参照（NULL 可だがシードは全件設定）。`opening_hours` はアプリ店舗詳細に表示（運用で更新）。 |
| `products` | 商品カタログ（既存）。 |

市区町村別の店一覧は `stores.municipality = :name` で取得します（`SupabaseStoreByMunicipalityRepository`）。

## チラシ（特売）取り込み

アプリ側は `FlyerIngestionFacade` に集約し、提供形態ごとにパーサを差し替え可能です。

| 経路 | 実装クラス | 備考 |
|------|------------|------|
| CSV | `CsvFlyerParser` | 列名は `CsvFlyerColumnMapping` で企業別に上書き可 |
| API（JSON） | `ApiJsonFlyerParser` | `offers` / `items` 配列などを解釈 |
| メール | `EmailFlyerParser` | スタブ。Inbound メール → Edge Function で raw を渡す想定 |
| PDF | `PdfFlyerParser` | **テキストレイヤ付き PDF** は Pdfium で抽出しメールパーサへ。画像のみの PDF は空（OCR は別経路） |

MVP では `USE_COMPOSITE_FLYER_INGESTION` 未設定時は `DummyFlyerIngestionFacade`（ダミー行）を返します。許諾後の本番取り込みは **Storage + Edge Function + 上記パーサ + `flyer_offers` 等のテーブル INSERT** を想定。

### `flyer_offers` テーブル

マイグレーション `20260409140000_flyer_offers.sql` で作成。アプリは `SupabaseFlyerOfferRepository` / `flyerOffersProvider` で **SELECT のみ**（INSERT はバックオフィス or Edge Function を想定）。

### Edge Function: `ingest-flyer-offers`

`supabase/functions/ingest-flyer-offers/` に **サービスロールで `flyer_offers` に INSERT** する関数を置いています。バックオフィス・CI・許諾後パイプラインから呼び出す想定です（アプリ本体にシークレットは埋め込みません）。

1. **Secrets**（Dashboard → Project Settings → Edge Functions、または CLI）で次を設定します。
   - `INGEST_SECRET` … 十分長いランダム文字列（呼び出し元と共有）
   - `SUPABASE_SERVICE_ROLE_KEY` と `SUPABASE_URL` は Supabase が Edge Runtime に注入（通常は手動設定不要）

2. デプロイ例:

```bash
supabase functions deploy ingest-flyer-offers --no-verify-jwt
```

`--no-verify-jwt` は **JWT ではなく `x-ingest-secret` で保護する**ためです。検証を有効にしたい場合は別途 JWT 検証を関数内に追加してください。

3. リクエスト例（`SERVICE_ROLE` はクライアントに載せないこと。サーバ・CI のみ）:

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/ingest-flyer-offers" \
  -H "Content-Type: application/json" \
  -H "x-ingest-secret: $INGEST_SECRET" \
  -d '{"offers":[{"product_name":"試験 牛乳 1L","chain_id":"san_a","price_yen":178,"ingestion_source":"apiJson","source_ref":"batch/demo"}]}'
```

成功時は `{ "inserted": N, "ids": [...] }` が返ります。各行は `product_name` と `ingestion_source` が必須です。任意で `id`（UUID）を指定するとその ID で挿入します。

### Edge Function: `ingest-flyer-asset`（JPG / PDF 共通）

`supabase/functions/ingest-flyer-asset/` は、`x-ingest-secret` 認証で **JPG/PDF 原本を Storage `flyer_sources` に保存**します。
戻り値の `source_ref`（`storage://flyer_sources/...`）を、そのまま `ingest-flyer-offers` の `source_ref` に入れてください。

```bash
supabase functions deploy ingest-flyer-asset --no-verify-jwt
```

受け付ける `content_type`:

- `image/jpeg` / `image/jpg`
- `application/pdf`

リクエスト例（PowerShell）:

```powershell
$bytes = [System.IO.File]::ReadAllBytes("C:\path\aeon_flyer.jpg")
$b64 = [Convert]::ToBase64String($bytes)

$asset = @{
  filename = "aeon_flyer_2026-04-21.jpg"
  content_base64 = $b64
  content_type = "image/jpeg"
} | ConvertTo-Json -Depth 5

$res = Invoke-RestMethod -Method Post `
  -Uri "$env:SUPABASE_URL/functions/v1/ingest-flyer-asset" `
  -Headers @{ "x-ingest-secret" = $env:INGEST_SECRET } `
  -ContentType "application/json" `
  -Body $asset

$res.source_ref
```

次に `source_ref` を使って `ingest-flyer-offers` へ構造化データを入れます（JPG/PDF どちらも同じ手順）:

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/ingest-flyer-offers" \
  -H "Content-Type: application/json" \
  -H "x-ingest-secret: $INGEST_SECRET" \
  -d '{"offers":[{"product_name":"牛乳 1L","chain_id":"aeon","price_yen":178,"ingestion_source":"manual","source_ref":"storage://flyer_sources/2026-04-21/xxxxx-aeon_flyer_2026-04-21.jpg"}]}'
```

### Edge Function: `ingest-price-observations`

`product_price_observations` への **一括 INSERT**（`x-ingest-secret` + `INGEST_SECRET`）。バッチ・バックオフィス用。

```bash
supabase functions deploy ingest-price-observations --no-verify-jwt
```

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/ingest-price-observations" \
  -H "Content-Type: application/json" \
  -H "x-ingest-secret: $INGEST_SECRET" \
  -d '{"observations":[{"product_id":"p1","store_id":"s1","price_yen":188,"source":"manual"}]}'
```

各行: `product_id`・`price_yen` 必須。`observed_at` 省略時はサーバ時刻。`source` 省略時は `manual`。

### Edge Function: `list-cheaper-than-last-notifications`

ウォッチ商品（`user_watch_products`）だけを対象に、**本日有効チラシ**と**直近観測価格**をサーバ側で比較し、
「前回より安い」候補を返します。アプリの通知一覧はこの関数を優先利用し、未デプロイ時はローカル計算にフォールバックします。

```bash
supabase functions deploy list-cheaper-than-last-notifications
```

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/list-cheaper-than-last-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_JWT" \
  -H "Content-Type: application/json"
```

戻り値は `{ "hits": [...] }` 形式。各 hit に `product`, `offer`, `last_observation`, `savings_yen` を含みます。

### Edge Function: `register-push-token`

ログイン済みユーザーの端末トークンを `user_push_tokens` に保存/更新します（将来の FCM/APNs 配信用）。

```bash
supabase functions deploy register-push-token
```

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/register-push-token" \
  -H "Authorization: Bearer $SUPABASE_ANON_JWT" \
  -H "Content-Type: application/json" \
  -d '{"token":"<device-token>","platform":"android","enabled":true}'
```

Flutter 側は設定画面の「Push トークンを登録」からこの関数を呼び出します。  
初回は Firebase 設定（`google-services.json` / `GoogleService-Info.plist`）が必要です。

### Edge Function: `queue-cheaper-than-last-notifications`

`user_watch_products` を全ユーザー分スキャンし、前回より安い候補を `notification_events` にキューします。  
実行保護は `x-ingest-secret`（`INGEST_SECRET`）です。Cron/CI/バッチから呼び出してください。

```bash
supabase functions deploy queue-cheaper-than-last-notifications --no-verify-jwt
```

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/queue-cheaper-than-last-notifications" \
  -H "x-ingest-secret: $INGEST_SECRET" \
  -H "Content-Type: application/json"
```

### Edge Function: `deliver-notification-events`

`notification_events(status='queued')` を取得し、`user_push_tokens(enabled=true)` 宛に FCM を送信します。  
1件でも送信成功したイベントは `delivered`、全失敗は `failed`、トークン無しは `skipped` に更新されます。  
実行保護は `x-ingest-secret`（`INGEST_SECRET`）です。

必要な Secret:

- `FCM_SERVER_KEY`（Firebase Cloud Messaging のサーバーキー）
- `INGEST_SECRET`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

```bash
supabase functions deploy deliver-notification-events --no-verify-jwt
```

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/deliver-notification-events" \
  -H "x-ingest-secret: $INGEST_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"limit":50}'
```

## データ保持（重複防止 + 自動削除）

- `20260422173000_ingest_dedup_constraints.sql`:
  - `flyer_offers (ingestion_source, source_ref)` の重複防止（`source_ref IS NOT NULL`）
  - `product_price_observations (product_id, store_id, price_yen, observed_at, source)` の重複防止
- `20260422180000_add_90d_retention_cleanup.sql`:
  - `pg_cron` で毎日 `03:15` に古い履歴を削除
- `20260422190000_retention_days_setting.sql`:
  - 保持日数を `public.app_runtime_settings` の `price_watch_retention_days` から読み込むように変更
- `20260422193000_retention_cap_180_days.sql`:
  - 保持日数の上限を **180日（半年）** に制限（下限1日）
- `20260422200000_retention_settings_rpc.sql`:
  - アプリ用 RPC `get_price_watch_retention_days()` / `set_price_watch_retention_days(p_days)` を追加
  - `set_*` は 1〜180 に丸めて保存
- `20260422210000_user_watch_products.sql`:
  - 匿名/ログインユーザーごとのウォッチ商品 ID 配列 `user_watch_products`
  - `auth.uid() = user_id` の RLS で本人のみ read/write
- `20260422220000_push_notification_foundation.sql`:
  - Push端末トークン `user_push_tokens`
  - 通知キュー `notification_events`（重複防止付き）

保持日数を変更する例（120日）:

```sql
insert into public.app_runtime_settings (key, value_text)
values ('price_watch_retention_days', '120')
on conflict (key) do update
set value_text = excluded.value_text,
    updated_at = now();
```

> `price_watch_retention_days` は 1〜180 の範囲で利用され、180 を超える値は自動的に 180 として扱われます。

アプリ（設定画面）から変更する場合も、このRPC経由で同じ制約が適用されます。

## レシート画像

- クライアント: `image_picker` → `ReceiptProcessingScreen` にバイト列を渡す → `CompositeReceiptIngestionFacade`（**Android/iOS は ML Kit 日本語** + `ReceiptTextParser`）。
- Web / デスクトップは `StubOcrEngine`。強制的にスタブにする場合は `--dart-define=USE_STUB_OCR=true`。

## Flutter から接続

`--dart-define=SUPABASE_URL=...` と `--dart-define=SUPABASE_ANON_KEY=...` を付けてビルドすると、`storesInMunicipalityProvider` が **Supabase** を参照します。未定義のときは **ローカル**の `kStoresByMunicipality`（ダミー）にフォールバックします。

**Authentication → Providers** で **Anonymous Sign-in** をオンにしてください（`user_active_stores` の RLS は `auth.uid()` 前提）。
