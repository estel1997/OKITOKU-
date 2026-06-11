# Portfolio Cleanup Report

作業日: 2026-06-12

## 対象

- OKITOKU-
- Jump_king_Unity
- git_sample

## 対応したこと

### OKITOKU-

- README.md をポートフォリオ向けに全面改修
- Flutter 初期テンプレートの文言を削除
- アプリ概要、制作目的、想定ユーザー、使用技術、主な機能、学んだこと、今後の改善予定を追加
- 実装済み、検証中、今後の予定を分けて記載
- docs を追加
  - docs/app-concept.md
  - docs/data-design.md
  - docs/future-roadmap.md
- .gitignore を確認
  - .env、Firebase 設定ファイル、鍵ファイルなどは除外済み
  - 今回の追加変更は不要

### Jump_king_Unity

- private 化を試行
- 実行コマンド:
  - `gh repo edit estel1997/Jump_king_Unity --visibility private`
- 結果:
  - 失敗
- 理由:
  - GitHub CLI が未ログイン
  - `gh auth login` または `GH_TOKEN` の設定が必要

### git_sample

- private 化を試行
- 実行コマンド:
  - `gh repo edit estel1997/git_sample --visibility private`
- 結果:
  - 失敗
- 理由:
  - GitHub CLI が未ログイン
  - `gh auth login` または `GH_TOKEN` の設定が必要

## 変更したファイル

- README.md
- docs/app-concept.md
- docs/data-design.md
- docs/future-roadmap.md
- portfolio_cleanup_report.md

## セキュリティ確認

以下の観点で確認しました。

- API キー
- secret
- token
- service role
- password
- Bearer token
- Supabase URL / anon key
- Firebase 設定値

確認結果:

- 指定パターンの検索では、`secret`、`token`、`private` などの一般語句・手順説明・プレースホルダ名はヒット
- API キー、secret、token、個人情報の実値は README.md と docs に追加していない

## 手動対応が必要なこと

### private 化

GitHub CLI で行う場合:

```bash
gh auth login
gh repo edit estel1997/Jump_king_Unity --visibility private
gh repo edit estel1997/git_sample --visibility private
```

GitHub 画面で行う場合:

1. 対象リポジトリを開く
2. Settings を開く
3. General の下部にある Danger Zone を確認
4. Change repository visibility を選択
5. Make private を選択
6. リポジトリ名を入力して確定

### GitHub プロフィール整理

- OKITOKU- の About 欄を更新
- OKITOKU- に Topics を追加
- Pinned repositories の表示順を整理
