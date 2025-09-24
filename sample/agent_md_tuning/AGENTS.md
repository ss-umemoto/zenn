# リポジトリガイドライン

## プロジェクト概要（Overview）

TODO: プロジェクトの目的・背景・利用範囲を記載すること。  
例: 「このリポジトリはエージェント開発の共通ルールと運用基盤を管理するためのものである」

## コーディング規約（Coding Style Guidelines）

TODO: 使用言語ごとのスタイルガイド（PEP8, ESLint/Prettierなど）、命名規則、コメント方針、Lint/Formatterルールを記載すること。

## セキュリティ（Security considerations）

TODO: APIキーや認証情報の扱い方、依存関係の脆弱性管理、通信方式、入力値検証の必須ルールなどを記載すること。

## ビルド＆テスト手順（Build & Test）

TODO: セットアップ手順、ビルドコマンド、テスト実行方法、CI/CDでのチェック内容を記載すること。

## 知識＆ライブラリ（Knowledge & Library）

- 実装前に`Context7 MCP Server`を利用し、`resolve-library-id` → `get-library-docs` で関連ライブラリ（例：`/upstash/context7`）の最新情報を取得する。

## メンテナンス_ポリシー（Maintenance policy）

- 会話の中で繰り返し指示されたことがある場合は反映を検討すること
- 冗長だったり、圧縮の余地がある箇所を検討すること
- 簡潔でありながら密度の濃い文書にすること
