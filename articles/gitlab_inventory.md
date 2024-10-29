---
title: "GitLabとPythonで実現するハンドブック陳腐化防止！自動棚卸しスクリプト作ってみた"
emoji: "🗄️"
type: "tech" 
topics: [python,git,gitlab,hugo,社内ドキュメント]
published: true
published_at: 2024-11-06 06:00
publication_name: "secondselection"
---

## はじめに

社内では`hugo`と`GitLab Pages`を使って[GitLab Handbook](https://handbook.gitlab.com/)に倣って社内ドキュメント（ハンドブック）を運用しています。
社内のハンドブックやリファレンスガイドなどを運用していると、時間とともに内容が古くなり気づけば「これって今も使えるの？」といった問題が発生することも多いです。
そのため、ドキュメント管理において**情報の陳腐化**は避けられない課題です。

本記事では、**GitLab上のMarkdownファイル**を対象に、3ヶ月以上更新されていないものを自動で洗い出し、「棚卸し対象」としてリストアップするPythonスクリプトを紹介します。
これにより、定期的な確認の手間を省きドキュメントの新鮮さを保つためのサポートをしてくれます。

## スクリプトの概要

今回のスクリプトは以下の2つの機能を実装しています。

- **ファイルの最終更新日を取得**
    - Gitリポジトリ内の`content/`ディレクトリ以下のMarkdownファイル（`.md`拡張子）について、各ファイルの最終コミット日を取得し、更新日が古い順に並べます。
- **GitLab上に棚卸し用Issueを自動生成**
    - 取得した更新日をもとに、3ヶ月以上更新のないファイルには「棚卸対象」のタグを付与し、GitLab上にIssueとして一覧表を作成します。

## スクリプトの詳細

スクリプト全体は以下の通りです。各関数の役割について順を追って解説します。

```txt: 必要なライブラリ
python-gitlab
```

```python: スクリプト(inventory.py)
import gitlab
from os import getenv
import subprocess
from datetime import (
    datetime,
    timedelta
)

URL = getenv("GITLAB_URL")
TOKEN = {"private_token": getenv("GITLAB_TOKEN")}
PROJECT_ID = getenv("CI_PROJECT_ID")

target_dir = 'content/'
target_file = '.md'


def get_files_by_commit_date():
    # リポジトリ内のすべてのファイルをリストアップ
    result = subprocess.run(
        ["git", "ls-files", target_dir],
        capture_output=True,
        text=True,
        check=True
    )
    
    # 各ファイルの最終コミット日を辞書に格納
    file_dates = {}
    files = result.stdout.splitlines()
    for file in files:
        if file.endswith(target_file):  # content/ 以下の .md ファイルのみを対象に
            # 各ファイルの最終コミット日を取得
            log_result = subprocess.run(
                ["git", "log", "-1", "--pretty=format:%at", file],
                capture_output=True,
                text=True,
                check=True
            )
            timestamp = int(log_result.stdout.strip())
            file_dates[file] = timestamp

    # 日付でソートし、yyyy-mm-dd形式に変換した連想配列を返す
    sorted_files = {
        file: datetime.fromtimestamp(timestamp)
        for file, timestamp in sorted(file_dates.items(), key=lambda x: x[1])
    }
    
    return sorted_files


def create_gitlab_issue(files_by_commit_date):
    # 3ヵ月前の日付を計算
    three_months_ago = datetime.now() - timedelta(days=90)

    # 表形式のコンテンツ作成
    issue_description = "| ファイルパス | 最終更新日 | 補足 |\n"
    issue_description += "|-----------|------------------|-----------|\n"
    for file, date in files_by_commit_date.items():
        # 3ヵ月以上更新がない場合に「棚卸対象です」を追加
        notes = "棚卸対象： 未対応/不要/更新" if date < three_months_ago else ""
        issue_description += f"| {file} | {date.strftime('%Y-%m-%d')} | {notes} |\n"

    # GitLabプロジェクトの取得
    gl = gitlab.Gitlab(URL, **TOKEN)
    project = gl.projects.get(PROJECT_ID)

    # GitLab Issueの作成
    issue = project.issues.create({
        'title': '【{}】棚卸チェック'.format(
            datetime.now().strftime('%Y年%m月')
        ),
        'description': issue_description
    })
    print("Issue created successfully:", issue.web_url)


if __name__ == "__main__":
    files_by_commit_date = get_files_by_commit_date()
    create_gitlab_issue(files_by_commit_date)

```

### 1. ファイルの最終更新日を取得する `get_files_by_commit_date` 関数

この関数は、リポジトリ内の`content/`ディレクトリ配下の`.md`ファイルについて、各ファイルの最終コミット日を取得します。取得したコミット日をもとに、更新日が古い順に並び替えた辞書形式で返します。

### 2. GitLab上に棚卸しIssueを作成する `create_gitlab_issue` 関数

`get_files_by_commit_date` 関数で取得した情報を使って、3ヶ月以上更新がないファイルを「棚卸対象」としてタグを付け、GitLab上にIssueを作成します。Issueには、対象ファイルのパスや最終更新日が表形式で記載されます。

## 環境変数の設定

このスクリプトは、GitLab APIとやり取りするため、以下の環境変数が必要です。

- `GITLAB_URL`: GitLabのURL
- `GITLAB_TOKEN`: プライベートトークン
- `CI_PROJECT_ID`: 対象プロジェクトのID

これらの変数を適切に設定し、CI/CDパイプラインやローカル環境で実行できるようにしましょう。

## CIの設定

GitLabでCIパイプラインを設定する場合は以下になります。

```yaml: .gitlab-ci.yml
inventory:
  image: python:3.12
  stage: schedule
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  before_script:
    - pip install python-gitlab
  script:
    - python inventory.py
  tags:
    - scheduled
```

## おわりに

本記事で紹介したスクリプトにより、定期的に更新が必要なファイルを自動でリストアップし、GitLab上に棚卸しチェック用のIssueを作成できます。
これにより、情報の陳腐化を防ぐための定期的な確認の手間を省きハンドブックの新鮮さを保つサポートができます。

ぜひ、ご自身のプロジェクトにも導入して、ハンドブックの鮮度を保ってみてください！
