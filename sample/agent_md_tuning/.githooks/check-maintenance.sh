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