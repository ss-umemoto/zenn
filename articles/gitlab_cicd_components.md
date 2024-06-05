---
title: "GitLab CI/CD Componentsを使いこなそう！実践ガイドとカタログの作成方法"
emoji: "📔"
type: "tech"
topics: [gitlab, gitlabci, IaC]
published: true
published_at: 2024-06-10 06:00
publication_name: "secondselection"
---

## はじめに

今回はGitLabの「CI/CD components」について紹介します。
この機能を使うことでパイプラインを簡単に再利用できます。
※ 記事はGitLabの`v17.0`時点の内容になります。また、動作確認はオンプレ環境で確認してます。

## CI/CD componentsとは

「CI/CD components」とは、**再利用可能**なパイプラインの構成ユニットです。
※ GitHubでいうと、GitHub Marketplaceで公開されているアクションのようです（筆者はGitHub Actionsを使ったことがほぼありません）。

https://docs.gitlab.com/ee/ci/components/index.html

### メリット

- **再利用性**
  - プロジェクト毎にパイプラインを作ったり・設定したりの手間が減る
- **CI/CDの利用・活用に対するハードルを下げることができる**
  - 利用者は「CI/CD components」の使い方さえわかれば、スクリプトを書かなくても済む

### デメリット

- **習得難易度が高い**
  - CI/CDの知見がないメンバーでは作るのは難しい

## CI/CD components_作り方

### 1. プロジェクトを新規作成し、機能を設定・有効化します

- プロジェクトの説明(`Project description`)
  - 記載が必須
  - ![setting](/images/gitlab_cicd_components/description.drawio.png)
- リポジトリ
  - 有効化（コード管理のため、必須）
- リリース
  - 有効化（カタログを公開・管理するため、必須）
- `CI/CDカタログプロジェクト`
  - 有効化
  - ![setting](/images/gitlab_cicd_components/setting.drawio.png)

### 2. ディレクトリ構成は以下で構成します

```txt:ディレクトリ構成
.
├─ .gitlab-ci.yml
├─ README.md  # 必須です
└─ templates
  ├─ xxxx.yml  # `xxxx`の部分はCI/CD componentsの名前になります
  └─ yyyy.yml  # 複数のコンポーネントを指定できます（v16.11で最大数は30です）
```

### 3. `.gitlab-ci.yml`は以下を最低限設定します（解析やテストが必要であれば、記載）

```yml:.gitlab-ci.yml
# タグができたらリリースを実施する
create-release:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
```

### 4. CI/CD componentsの定義ファイル`templates/*.yml`を設定します

```yml:CI/CD componentsの定義 (例 xxxx.yml)
spec:
  inputs:  # コンポーネントを利用する際のインプット（プロパティのイメージ）
    stage:
      default: test
---
# パイプラインのジョブを記載する。
# $[[ inputs.xxxxx ]]と記載することで、インプットの値を参照することができます
component-job:
  script: echo job $[[ inputs.stage ]]
  stage: $[[ inputs.stage ]]
```

```yml:CI/CD componentsの定義 (例 yyyy.yml)
spec:
  inputs:  # コンポーネントを利用する際のインプット（プロパティのイメージ）
    stage:
      default: build
---
# パイプラインのジョブを記載する。
# $[[ inputs.xxxxx ]]と記載することで、インプットの値を参照することができます
component-job:
  script: echo job $[[ inputs.stage ]]
  stage: $[[ inputs.stage ]]
```

### 5. GitのTagを作成します

1. ![step001](/images/gitlab_cicd_components/create_step_001.drawio.png)
2. ![step002](/images/gitlab_cicd_components/create_step_002.drawio.png)

## CI/CD components_使い方

```yml:.gitlab-ci.yml
include:
  # ${GitLabのドメイン}/${コンポーネントプロジェクトのバス}/${コンポーネント名}@${バージョン}
  - component: gitlab.example.com/components/sample/xxxx@1.0.0
    inputs:
      stage: test
```

## CI/CD Catalog

「CI/CD components」をリスト化したものになります。
カタログの一覧は`${GITLAB_URL}/explore/catalog`で確認できます。
また、パイプラインエディターにもリンクが配置されています。

![パイプラインエディターの場合](/images/gitlab_cicd_components/use_001.drawio.png)

## おわりに

今回はGitLabの「CI/CD components」について記載しました。
「普段、毎回記載していた`.gitlab-ci.yml`の一部を統一化してメンテがしやすい」という点で非常に便利です。

[こちら](https://zenn.dev/ftd_tech_blog/articles/ftd-gitlab-2023-12-10)にも記載がありますが、日本語での情報が少ない。

## 参照

https://docs.gitlab.com/ee/ci/components/index.html

https://zenn.dev/ftd_tech_blog/articles/ftd-gitlab-2023-12-10

https://techstep.hatenablog.com/entry/2024/03/23/094631
