---
title: "GitLab⇒CodeCommitのミラーリング"
emoji: "🎞"
type: "tech"
topics: [gitlab, codecommit, awscdk]
published: true
published_at: 2023-12-14 09:00
publication_name: "secondselection"
---

## はじめに

セカンドセレクション技術部のumemotoです。

この記事はGitLabのリポジトリをAWS上のCodeCommitにミラーリングする方法をまとめたものです。

Gitリポジトリはひとつであるべきですが、「開発はGitLabで管理・運用したい」・「デプロイはCodePipelineによってAWS上でデプロイしたい」という場合があり、記事にしてみました。  
※ この記事は2023/12/12時点のAWSとGitLabのスクリーンショットを記載してます。

構築手順としてはAWSCDKである程度コード化し、いくつかのコマンドを実行して構築する流れになります。

1. ミラーリング先(CodeCommit)の作成
    - [AWSCDKのコードの説明](#awscdkのコード)
    - [AWSのリソース作成](#awsのリソース作成)
2. [GitLabでミラーリングの設定](#gitlabでミラーリングの設定)

### 今回構築する構成

弊社では社内ネットワーク上にGitLabを構築して、普段はGitLabで開発しています。
今回構築する構成はGitLab上で開発しつつ、CodeCommitにミラーリングすることでCodePipelineと連携もできる構成を目指しています。

![system](/images/gitlab_codecommit/system.drawio.png)

### 用語一覧

- CodeCommit
  - AWSのマネージド型のソース管理サービス
- AWS CDK
  - 使い慣れたプログラミング言語でAWSのリソースを定義できるツール

## AWSCDKのコード

AWS上のリソース作成は[AWS CDK](https://aws.amazon.com/jp/cdk/)を利用しています。

記事用に作成したリポジトリは以下になります。

https://gitlab.com/hijiri.umemoto/awscdk-sample

### リポジトリのディレクトリ構成

- **.devcontainer**: VSCodeのDevcontainerの設定
- **bin**: 複数スタックの依存関係を管理・定義
- **lib**: 各スタック（CloudFormationのStackに相当）
    - **repository-stack.ts**: CodeCommitのスタック
- **module**: スタックで利用する関数など
    - **codecommit.ts**
        - **createCodeCommit**: リポジトリの作成
        - **createGitlabIamUser**: ミラーリング時に使用するIAMユーザの作成

### コードの簡単な説明

主要なコードは以下の２つの関数です。

- [createCodeCommit](#createcodecommit): CodeCommitのリソース作成用関数
- [createGitlabIamUser](#creategitlabiamuser): GitLab⇒CodeCommit連携用のIAMユーザ作成

#### createCodeCommit

CodeCommitのリソースを作成する関数です。

```typescript
export const createCodeCommit = (
  app: Construct,
  serviceName: string,
  description: string
): codecommit.Repository => {
  return new codecommit.Repository(
    app,
    `${serviceName}-codecommit`,
    {
      repositoryName: serviceName,
      description: description
    }
  );
};
```

#### createGitlabIamUser

GitLab⇒CodeCommitの連携のため専用のIAMユーザを作成する用の関数です。
権限としては、対象のリソースに対してpushとpullができる権限を設定してます。

```typescript
export const createGitlabIamUser = (
  app: Construct,
  serviceName: string,
  codecommit: codecommit.Repository
): iam.User => {
  const policy_statement = new iam.PolicyStatement({
    effect: iam.Effect.ALLOW,
    actions: [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ],
    resources: [
      codecommit.repositoryArn
    ]
  });

  const policy = new iam.Policy(
    app,
    `${serviceName}-gitlab-mirroring-policy`,
    {
      statements: [policy_statement],
      policyName: `${serviceName}-gitlab-mirroring-policy`
    }
  );

  const user = new iam.User(
    app,
    `${serviceName}-gitlab-mirroring-user`,
    {
      userName: `${serviceName}-gitlab-mirroring-user`
    }
  );

  user.attachInlinePolicy(policy);

  return user;
};
```

## デプロイ

デプロイの手順としては以下になります。

1. [AWSのリソース作成](#awsのリソース作成)
2. [GitLabでミラーリングの設定](#gitlabでミラーリングの設定)

### AWSのリソース作成

[AWSCDKのコード](#awscdkのコード)を利用してAWSのリソースを作成していきます。
その際、AWS CDKのデプロイコマンド以外にもコマンドを実行する必要があります。

`cdk.json`の`serviceName`を作成されるサービス名に変更した上で、以下のコマンドを実行します。

```bash
# ブートストラップ
# 最初の一回だけ実行が必要なコマンドです。
cdk bootstrap

# スタックのデプロイ
cdk deploy RepositoryStack
```

これで、CodeCommitのリソースと連携用のIAMユーザが作成されています。

![cfn](/images/gitlab_codecommit/cloudformation.drawio.png)

続いて作成したIAMユーザのGitの認証情報を生成します。
認証情報を**必ず**メモしてください。

```bash
# Gitの認証情報を作成
# Gitの認証情報が表示されます。後で利用するためメモ必須
aws iam create-service-specific-credential --user-name ${サービス名}-gitlab-mirroring-user --service-name codecommit.amazonaws.com
# {
#     "ServiceSpecificCredential": {
#         "ServiceUserName": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#         "ServicePassword": "yyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
#     }
# }
```

### GitLabでミラーリングの設定

AWSのリソース(CodeCommit)と連携用のIAMユーザができたので、続いてGitLab上でミラーリングの設定します。

ミラーリングするリポジトリのサイドバーから「設定⇒リポジトリ」のページを開きます。
リポジトリのミラーリングを開き、"新規を追加"ボタンから設定していきます。

以下の設定内容を入力し、"ミラーリポジトリ"のボタンを押下します。

- GitリポジトリのURL
  - `https://{{ServiceUserName}}@git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/{{RepositoryName}}`
    - ServiceUserName: Gitの認証情報で出力されたサービスユーザ名
    - RepositoryName: CodeCommitのリポジトリ名
- ユーザ名
  - Gitの認証情報で出力されたサービスユーザ名(ServiceUserName)
- パスワード
  - Gitの認証情報で出力されたパスワード(ServicePassword)
- 保護されたブランチのみミラー
  - チェックを入れる（デプロイ目的のミラーのため、mainなどの保護ブランチに限定する）

![mirroring_01](/images/gitlab_codecommit/mirroring_01.drawio.png)

これで、GitLabにプッシュすることでミラーリングされます。

![mirroring_02](/images/gitlab_codecommit/mirroring_02.drawio.png)

## おわりに

AWSCDKを使ってCodeCommitのリポジトリを作成し、GitLabのリポジトリをミラーリングする方法を簡単に紹介いたしました。

開発はGitLabで管理・運用しつつ、本番環境のデプロイはAWS上で構築可能な状態にできました。
インフラと開発のベンダーが異なる場合の連携とかでも活用できるのではないかと私は考えてます。
