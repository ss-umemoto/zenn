---
title: "GitLabで役に立つTIPS(その１)"
emoji: "🏷️"
type: "tech"
topics: [gitlab, tips, security, ci, gitlabci]
published: true
published_at: 2024-05-13 06:00
publication_name: "secondselection"
---

## はじめに

少し前に以下の記事にて、GitLabでのGitサーバとして以外の使い方を紹介しました。
前回紹介したもの以外でもGitLabには他にも色々な機能・設定がありますので、今回はその中から何点か紹介します。

※ この記事はGitLabのバージョン`v16.10`時点の記事です。

https://zenn.dev/secondselection/articles/gitlab_operation

## TIPS

今回は以下の4つを紹介します。

- [JSON形式でのテーブルの記載](#json形式でのテーブルの記載)
- [コメントテンプレート](#コメントテンプレート)
- [アクティビティのフィルター・ソート](#アクティビティのフィルターとソート)
- [コンテナスキャン](#コンテナスキャン)

### JSON形式でのテーブルの記載

GitLabでは通常のマークダウン以外の記載方法でもテーブルを表現できます。
その1つにJSON形式での記載方法があります。JSONで記載することによってフィルターが可能になります。

````md
```json:table
{
  "fields" : [
    {"key": "a", "label": "AA"},
    {"key": "b", "label": "BB"},
    {"key": "c", "label": "CC"}
  ],
  "items" : [
    {"a": "11", "b": "22", "c": "33"},
    {"a": "211", "b": "222", "c": "4"}
  ],
  "filter" : true
}
```
````

|サンプル|
|:-:|
|![jsonテーブル](/images/gitlab_tips_001/json_table.drawio.png)|

### コメントテンプレート

コメントもissueやマージリクエストと同じくテンプレートを設定できます。

コメントのテンプレートを設定するのは以下の手順です。

1. アカウントの設定画面を開きます。`/-/profile/comment_templates`
2. 「新規を追加」のボタンをクリックしてテンプレートを設定します  
  ![コメントテンプレート_設定の仕方](/images/gitlab_tips_001/commment_template.drawio.png)

利用方法も簡単です。以下のように💬をクリックしてテンプレートを指定することで利用ができます。

![コメントテンプレート_利用の仕方](/images/gitlab_tips_001/use_commment_template.drawio.png)

#### コメントテンプレート_活用方法

以下で紹介したものなど登録しておいて利用する活用方法があります。

https://zenn.dev/secondselection/articles/generation_ai_comments_filter

### アクティビティのフィルターとソート

issueやマージリクエストではアクティビティが本文以降に表示されています。
やり取りが多くなったりするとこのアクティビティが長くなります。そのときに使える機能です。

![アクティビティ](/images/gitlab_tips_001/activity.drawio.png)

### コンテナスキャン

GitLabのCI機能でDockerイメージの脆弱性をチェックができます。
SASTと組み合わせることでより安全なコンテナイメージを作成していきます。

https://docs.gitlab.com/ee/user/application_security/container_scanning/

```yaml
include:
  - template: Jobs/Build.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_COMMIT_SHA
```

- スキャン結果はJSONファイルでアーティファクトとして保存されます。
  - CE(無料版)は、パイプラインのアーティファクトを毎回ダウンロードして確認する必要があります。
  - EE(有料版)であれば、CodeQualityの形式でマージリクエストに表示されるようです。
- ※ この機能を利用するにはコンテナレジストリを有効にする必要があります。
- ※ プロジェクト外のイメージを対象にする場合は`CS_IMAGE`で指定します。

## おわりに

今回は以下の4つを紹介しましたが、GitLabは色々な機能があります。
今後、他にも役に立つ機能(TIPS)があれば紹介していきます。

- [JSON形式でのテーブルの記載](#json形式でのテーブルの記載)
- [コメントテンプレート](#コメントテンプレート)
- [アクティビティのフィルター・ソート](#アクティビティのフィルターとソート)
- [コンテナスキャン](#コンテナスキャン)
