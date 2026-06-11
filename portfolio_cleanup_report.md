# Portfolio Cleanup Report

作業日: 2026-06-12

## 対象

- OKITOKU-
- Jump_king_Unity
- git_sample
- GitHub full cleanup follow-up

## OKITOKU- 再確認結果

- README.md は Flutter 初期テンプレートではない
- 沖縄県内の買い物・価格比較アプリ prototype として説明されている
- 実装済み、検証中、今後予定が分けて書かれている
- docs/app-concept.md がある
- docs/data-design.md がある
- docs/future-roadmap.md がある
- docs/learning-notes.md を追加
- `.github` テンプレートを追加
- `.env.example` を追加

## private 化再確認

### Jump_king_Unity

- 実行コマンド:
  - `gh repo edit estel1997/Jump_king_Unity --visibility private --accept-visibility-change-consequences`
- 結果:
  - 成功

### git_sample

- 実行コマンド:
  - `gh repo edit estel1997/git_sample --visibility private --accept-visibility-change-consequences`
- 結果:
  - 成功

## セキュリティ確認

- README / docs に API key、secret、token、service role key、個人情報の実値は追加していない
- `.env.example` は placeholder のみ
- `.gitignore` では `.env`、Firebase 設定ファイル、鍵ファイルなどを除外済み

## 変更したファイル

- README.md
- docs/learning-notes.md
- .env.example
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/bug_report.md
- .github/ISSUE_TEMPLATE/feature_request.md
- portfolio_cleanup_report.md

## 詳細なアカウント全体確認

アカウント全体の巡回順と手動確認項目は、profile README repo の `github_manual_update_guide.md` にまとめています。
