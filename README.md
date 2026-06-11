# OKITOKU - Shopping Price Watch App

## 概要

OKITOKU は、沖縄県内で日用品や食品を購入するときに、店舗ごとの価格差や買い物候補を確認しやすくすることを目指した Flutter アプリです。

買い物前に「どの店で買うと安いか」「よく買う商品の価格がどう変わっているか」を整理し、日常の節約判断を支援することを目的に開発しています。

このリポジトリでは、Flutter によるモバイル UI、ローカルデータ管理、Supabase / Firebase 連携、価格・チラシ・レシート情報の取り込み設計を学習しながら実装しています。

## 制作目的

このアプリは、以下の学習と実装経験を得るために制作しています。

- Flutter / Dart によるモバイルアプリ開発
- Riverpod と go_router を使った状態管理・画面遷移
- 店舗、商品、価格、チラシ、レシート情報を扱うデータ設計
- Supabase を使ったバックエンド連携とローカルキャッシュ
- Firebase Cloud Messaging とローカル通知の検証
- OCR、PDF、CSV、メール本文など複数形式のデータ取り込み設計
- ポートフォリオとして第三者に伝わる README / docs の整理

## 想定ユーザー

- 沖縄県内で日用品や食品を購入する人
- 複数店舗の価格差を比較したい人
- よく買う商品の価格を記録したい人
- チラシやレシート情報を買い物判断に活用したい人

## 使用技術

| 区分 | 技術 |
|---|---|
| App | Flutter / Dart |
| State Management | Riverpod |
| Routing | go_router |
| Local Storage | SharedPreferences |
| Backend | Supabase |
| Notification | Firebase Cloud Messaging / flutter_local_notifications |
| Data Ingestion | OCR / PDF / CSV / Email parser |
| Database | PostgreSQL / Supabase migrations |
| Version Control | Git / GitHub |

## 主な機能

現在の実装状況に合わせて、機能を段階ごとに整理しています。

### 実装済み・土台あり

- オンボーディングと利用エリア設定
- 店舗一覧、店舗詳細、商品一覧、商品詳細の画面構成
- 沖縄県内の自治体・店舗・商品カテゴリを扱うモデル
- 今日の買い物ルートや移動コストを考慮するドメイン設計
- 店舗別の近隣価格比較カード
- 商品カタログのローカルキャッシュと Supabase 同期
- 設定画面での同期操作、通知設定、実装ロードマップ表示
- Supabase Edge Functions と migrations の管理

### 検証中

- レシート画像・テキストの取り込みと解析
- チラシ情報の PDF / CSV / メール / API 取り込み
- OCR エンジンのプラットフォーム別切り替え
- 価格観測データからの通知候補作成
- Push トークン登録と通知配信フロー

### 今後の改善予定

- 商品登録と価格履歴の入力体験改善
- 店舗別価格比較の精度向上
- 価格変動通知の実用化
- 検索・カテゴリ・店舗フィルタの強化
- UI/UX 改善
- テストコードとスクリーンショットの追加

## 画面構成

現在は、以下のような画面構成を軸に整理しています。

```text
Onboarding
  -> Home
  -> Today Shopping
  -> Store List
  -> Store Detail
  -> Product List
  -> Product Detail
  -> Flyer Offers
  -> Receipt Capture / Review
  -> Notifications
  -> Settings
```

## データ設計の考え方

このアプリでは、以下のようなデータを扱う想定です。

- 店舗
- 商品
- 価格観測
- 価格履歴
- よく見る商品・通知対象商品
- チラシ情報
- レシート解析結果

実装では、ローカルの seed / cache と Supabase の remote repository を組み合わせ、通信に失敗しても最低限の画面表示を続けられる構成を目指しています。

詳しくは [docs/data-design.md](docs/data-design.md) を参照してください。

## 工夫した点

- 日常の買い物という身近な課題を、店舗・商品・価格というデータ構造に分けて整理した
- UI だけでなく、データ取得、キャッシュ、バックエンド連携まで含めて設計した
- Supabase 未設定時でもアプリが動くように、ローカル実装とリモート実装を分けた
- レシート、チラシ、通知など、将来的に広げたい機能を小さな単位に分解した
- README と docs で、実装済みの範囲と今後の予定を分けて説明できるようにした

## 苦労した点・改善した点

- 価格比較に必要な店舗、商品、価格履歴の関係を整理すること
- Flutter で複数画面を扱いながら状態管理を見通しよく保つこと
- ローカルデータと Supabase データの責務を分けること
- OCR や PDF など、端末・環境差が出やすい処理を抽象化すること
- 通知機能を UI、端末トークン、バックエンド処理に分けて考えること

## 学んだこと

- アプリを作る前に、誰のどの課題を解決するのかを整理する重要性
- Flutter では UI だけでなく、状態管理とデータ構造の設計が重要であること
- 価格比較アプリでは、商品、店舗、履歴を分けて考える必要があること
- バックエンド連携は、未設定・通信失敗・ローカルキャッシュを前提に設計する必要があること
- README で目的、構成、実装状況、改善予定を整理すると、第三者に説明しやすくなること

## ドキュメント

- [docs/app-concept.md](docs/app-concept.md)
- [docs/data-design.md](docs/data-design.md)
- [docs/future-roadmap.md](docs/future-roadmap.md)
- [docs/learning-notes.md](docs/learning-notes.md)
- [docs/IMPLEMENTATION_ROADMAP.md](docs/IMPLEMENTATION_ROADMAP.md)
- [docs/UNIMPLEMENTED.md](docs/UNIMPLEMENTED.md)

## 起動方法

Flutter 環境を用意したうえで、以下を実行します。

```bash
flutter pub get
flutter run
```

Supabase や Firebase を使う機能は、各サービスの設定が必要です。API キーや secret は README や docs に記載せず、ローカル環境変数や開発環境ごとの設定で扱います。

## 注意事項

このリポジトリは学習・ポートフォリオ目的で開発しているアプリです。実装済みの機能、検証中の機能、今後の予定は README と docs 内で分けて記載しています。
