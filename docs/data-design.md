# Data Design

## 方針

OKITOKU では、店舗、商品、価格、価格履歴、よく見る商品を分けて扱います。実装では Supabase migrations と Dart の domain entities が詳細な構造の基準になります。

このドキュメントでは、ポートフォリオとして読みやすいように主要データを整理します。

## stores

店舗を表します。

| 項目 | 内容 |
|---|---|
| id | 店舗 ID |
| name | 店舗名 |
| chain | チェーン名 |
| municipality | 市町村 |
| address | 住所 |
| latitude / longitude | 位置情報 |
| created_at | 作成日時 |

利用例:

- 店舗一覧
- 店舗詳細
- 近隣店舗候補
- 今日の買い物ルート

## products

商品を表します。実装上は catalog product として扱う部分があります。

| 項目 | 内容 |
|---|---|
| id | 商品 ID |
| name | 商品名 |
| category | カテゴリ |
| unit | 単位 |
| brand | ブランド |
| created_at | 作成日時 |

利用例:

- 商品一覧
- 商品詳細
- よく買う商品の管理
- 価格比較対象

## prices

特定店舗で観測された商品の価格を表します。実装上は price observation として扱う部分があります。

| 項目 | 内容 |
|---|---|
| id | 価格 ID |
| store_id | 店舗 ID |
| product_id | 商品 ID |
| price | 価格 |
| observed_at | 観測日 |
| source | 入力元 |

利用例:

- 店舗別価格比較
- 商品詳細での価格表示
- チラシやレシートからの価格登録

## price_histories

価格の変化を追うための履歴です。prices / price observations を時系列で扱うことで、履歴として利用します。

| 項目 | 内容 |
|---|---|
| id | 履歴 ID |
| product_id | 商品 ID |
| store_id | 店舗 ID |
| price | 価格 |
| recorded_at | 記録日時 |
| source | 手入力、チラシ、レシートなど |

利用例:

- 過去価格との比較
- 値下がり通知
- 店舗別の価格傾向

## favorites

ユーザーがよく見る商品や通知対象にしたい商品を表します。実装上は watch products などの名前で扱う部分があります。

| 項目 | 内容 |
|---|---|
| id | お気に入り ID |
| user_id | ユーザー ID |
| product_id | 商品 ID |
| notify_enabled | 通知対象か |
| created_at | 作成日時 |

利用例:

- よく買う商品の管理
- 価格変動通知
- ホーム画面のショートカット

## 関係性

```text
stores
  -> prices

products
  -> prices
  -> price_histories
  -> favorites

favorites
  -> products
```

## 今後の改善案

- 商品名の表記ゆれ吸収
- 店舗ごとのカテゴリ差分への対応
- チラシ価格とレシート価格の区別
- セール期間の開始日・終了日管理
- 通知条件の細分化
- Supabase 側の RLS と user_id の整理
