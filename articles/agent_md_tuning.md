---
title: "AGENTS.mdの育て方（検討/模索中）"
emoji: "👨‍🍼"
type: "tech"
topics: [openai, codexcli, vibecoding, zennfes2025ai]
published: true
published_at: 2025-09-26 06:00
publication_name: "secondselection"
---

## はじめに

最近流行りのコーディングエージェント（`Codex CLI`や`Claude Code`など）のツールをチームメンバーに社内システムの開発などで試してもらっています。
特に本稿内で紹介しているスクリプトでは、`Codex CLI`をベースにした運用を前提に話を進めます。
一方で、「チーム内でAIの生成するコードが安定していない」という報告を受けました。このとき頼りになるのが「AGENTS.md」です。

頼りにできる「AGENTS.md」ですが、 **何を書くべきだろう？** という悩みができました。
今回はこの「AGENTS.md」を **育てる** という以下の発想に刺激を受けて、AGENTS.mdの育て方を検討してみたという記事です。

https://x.com/sazan_dev/status/1968222841981002203

## AGENTS.mdとは？

`AGENTS.md`は、コーディングエージェントにプロジェクト固有の知識やルールを共有するためのMarkdownドキュメントです。
わかりやすく言うと、「**AGENTS.md＝コーディングエージェント用のREADME**」です。

このドキュメントを使えば、`Codex`や`Gemini CLI`のような異なるツールでも一貫したコンテキストを与えられます。
結果として、レビュー負荷の高いコード生成の揺れを抑え、チーム開発の再現性を高められます。

https://agents.md/

## AGENTS.mdの育て方

1. AGENTS.mdのテンプレートを作成する
2. 会話をもとに内省させてカイゼンをさせる
3. pre-commitを使った定期的なカイゼンをさせる

![成長イメージ](/images/agent_md_tuning/image.drawio.png)

### AGENTS.mdのテンプレート

育てること前提で以下のようなテンプレートをリポジトリ直下に作成します。
作成後、`AGENTS.mdを読み、TODOを簡潔に埋めて`とコーディングエージェントにリクエストして初回のAGENTS.mdを作ります。

```md: AGENTS.md
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
```

MCPとして`Context7 MCP Server`を使うものとしてます。

https://github.com/upstash/context7

### 会話をもとに内省させてカイゼンをさせる

コーディングエージェントと開発を進めていく途中で以下のプロンプトを実行して改善案を出させて育てていきます。

```txt: プロンプト
AGENTS.mdを読みトーンと原理原則を理解せよ。
今日の会話を振り返り、繰り返し発生した失敗や私からの繰り返し指示があれば、それを防ぐための追加ルールをAGENTS.mdに提案せよ。
会話が少ない場合は、基本的な失敗防止策や自発的行動のチェックリストを追加すること。
出力はAGENTS.mdのトーンに合わせること。
```

### pre-commitを使った定期的なカイゼンをさせる

今回は、Python製のフック管理ツールである`pre-commit`を使って「特定の条件に一致したら`AGENTS.md`も更新する」運用にしています。

コミット前にフックが動くことで、ガイドラインの更新漏れを機械的に防げます。

- AGENTS.mdの最終コミット日が30日前のとき
- README.mdが変更されたとき
- ディレクトリ構成の変更があるとき
- パッケージ管理ファイルの中身が変更されたとき

```yaml: .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: maintenance-check
        name: Maintenance Check
        entry: .githooks/check-maintenance.sh
        language: system
        pass_filenames: false   # 引数としてファイルリストを渡さない場合
```

```bash: .githooks/check-maintenance.sh
#!/usr/bin/env bash
set -e

# codexがインストールされていない場合はスキップ
if ! command -v codex >/dev/null 2>&1; then
  echo "[pre-commit] codex not found → skip"
  exit 0
fi

# 今回のコミットで AGENTS.md が更新されているか
if git diff --cached --name-only | grep -q '^AGENTS.md$'; then
  echo "[pre-commit] AGENTS.md updated → OK"
  exit 0
fi

# --- ここから「AGENTS.md が更新されていない場合」のチェック ---

# AGENTS.md 更新日チェック（30日以上前）
FILE="AGENTS.md"
last_commit_ts=$(git log -1 --format="%ct" -- "$FILE" 2>/dev/null)
if [ -z "$last_commit_ts" ]; then
  echo "[Maintenance] $FILE のコミット履歴が存在しません。"
  exit 0
fi

now_ts=$(date +%s)
days_since_commit=$(((now_ts - last_commit_ts) / 86400))
if [ "$days_since_commit" -gt 30 ]; then
  codex exec -s workspace-write "[Maintenance] $FILE が30日以上更新されていません。AGENTS.mdを更新してください"
  exit 0
fi

# README.md 変更チェック
if git diff --cached --name-only | grep -q '^README.md$'; then
  codex exec -s workspace-write "[Maintenance] README.md が変更されました。AGENTS.mdを更新してください"
  exit 0
fi

# ディレクトリ構成変更チェック
if git diff --cached --name-status | grep -E "^(A|D|R)"; then
  codex exec -s workspace-write "[Maintenance] ディレクトリ構成が変更されました。AGENTS.mdを更新してください"
  exit 0
fi

# パッケージ管理ファイル変更チェック
PACKAGE_FILES=(
  package.json
  package-lock.json
  requirements.txt
)
if git diff --cached --name-only | grep -q -f <(printf '%s\n' "${PACKAGE_FILES[@]}"); then
  codex exec -s workspace-write "[Maintenance] パッケージ管理ファイルが変更されました。AGENTS.mdを更新してください"
  exit 0
fi
```

#### Devcontainer環境

Devcontainer環境では、`postCreateCommand`を使って`pre-commit`をセットアップしてフックを自動登録する構成にしています。

```json: .devcontainer/devcontainer.json
{
  "name": "Ubuntu",
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/python:1": {}
  },
  "postCreateCommand": "/bin/sh .devcontainer/postCreateCommand.sh"
}
```

```bash: .devcontainer/postCreateCommand.sh
mkdir "$HOME/.codex"
cp .codex/config.toml "$HOME/.codex/config.toml"

npm install -g @openai/codex

sudo apt-get update
sudo apt-get install -y pipx

pipx ensurepath
pipx install pre-commit

chmod +x .githooks/check-maintenance.sh
pre-commit install
pre-commit run --all-files
```

## まとめ

`AGENTS.md`を整備することで、エージェントと開発チームが共有する知識の解像度をそろえられます。
テンプレートを叩き台に「原理原則を圧縮」「対話で内省」「定期的に再構成」という育成サイクルを回すとループ抑制やマジックナンバー削減といった改善できそうです。
さらに、pre-commitで更新を強制する仕組みと組み合わせることで、ガイドラインの陳腐化を防ぎつつ、誰が触っても同じ品質でエージェントを運用できると考えてます。
日々の開発で気づいた改善案をこまめに取り込み、チーム固有のルール・手順・ナレッジを粘り強く磨いていくことが、生成コードの品質と開発体験を底上げする最短ルートです。

## 参考URL

https://agents.md/

https://x.com/sazan_dev/status/1968222841981002203

https://www.ai-souken.com/article/what-is-agents-md

https://js2iiu.com/2025/08/22/agents-md/

https://zenn.dev/secondselection/articles/openai_codex
