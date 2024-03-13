---
title: "Dockerfileマスターへの道：AIとの協業からセキュリティ診断まで徹底解説"
emoji: "🐋"
type: "tech"
topics: [docker, dockerfile, 環境構築, プロンプト, 静的解析]
published: true
published_at: 2024-03-18 06:00
publication_name: "secondselection"
---

## はじめに

[前回](https://zenn.dev/secondselection/articles/how_to_devcontainer)、DevContainerでの開発環境構築を紹介したので、今回はDockerfileを書く方法についてまとめました。
Dockerfileを作る際のテクニックとして、生成AIや静的解析ツールを使う以下の方法を説明します。

- [生成AIとの協業](#生成aiとの協業_dockerfileの骨組み作成)
- [コード規約チェック(hadolint)](#コード規約チェックhadolint)
- [セキュリティ診断(Dockle)](#セキュリティ診断dockle)
- [クラウド上でのイメージスキャン(Amazon ECR Image scanning)](#クラウド上でのイメージスキャンamazon-ecr-image-scanning)

「生成AIとの協業」⇒「コード規約チェック」⇒「セキュリティ診断」を実施することで、ベストプラクティスに基づいた安全なイメージを作ることができます。
さらに、「クラウド上での脆弱性のスキャン」で`共通脆弱性識別子(CVE)`に対するチェックを行います。

## Dockerとは

コンテナ型の仮想化プラットフォームです。軽量で環境の共有や統一化ができます。詳しくは以下のZennの本などを見てみてください。

https://zenn.dev/suzuki_hoge/books/2022-03-docker-practice-8ae36c33424b59

### Dockerfile

イメージの設計図で`FROM`や`RUN`などのコマンドを使ってイメージをカスタマイズできるものです。

https://zenn.dev/suzuki_hoge/books/2022-03-docker-practice-8ae36c33424b59/viewer/2-8-dockerfile

## 生成AIとの協業_Dockerfileの骨組み作成

私は普段Dockerfileを公式のサンプルを見ながら自力で書いているのですが、生成AIを使って作成してもらうこともできます。
初心者は生成AIで出力されたものを元に動かしなら作るのも1つの手ではないでしょうか。

```txt: プロンプト
あなたはDockerの専門家です。
以下の{条件}を満たすDockerfileを作ってください

#条件
言語：##言語##
パッケージ：
　・##パッケージA##
　・##パッケージB##
　・##パッケージC##
　・##パッケージD##
　・##パッケージE##
```

### 生成AIとの協業_Dockerfileの骨組み作成_サンプル

以下がサンプルとして、`PHP8 + Apache + Git`環境を構築したいプロンプトを実行した場合を記載します。
※ 生成AIは誤った回答をする場合もあるので注意しましょう。

```txt: サンプル実行
あなたはDockerの専門家です。
以下の{条件}を満たすDockerfileを作ってください

#条件
言語：PHP8.3
パッケージ：
　・git
　・apache
```

```Dockerfile: 実行結果
# PHP 8.3をベースイメージとして使用
FROM php:8.3-apache

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Apacheの設定
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# ポート80でリッスンするように設定
EXPOSE 80

# Apacheをフォアグラウンドで実行
CMD ["apache2-foreground"]
```

※ **GPT4を使って生成した結果を記載しています。** GPT-3.5だと後述するベストプラクティスには基づいていないものが出力されました。

## コード規約チェック(hadolint)

Dockerfileを書き始めに入れておくといいツールとして、`hadolint`という静的解析ツールがあります。
Dockerfileのベストプラクティスに基づいたlintを実行できます。これによってベストプラクティスの知識が少なくてもキレイで適切なDockerfileが書けます。

https://github.com/hadolint/hadolint

```Dockerfile: 悪い例
FROM ubuntu

RUN apt-get update \
    apt-get install -y git
```

```Dockerfile: 良い例
# 00: タグは指定しましょう
FROM ubuntu:jammy

# 01: インストール時はバージョンを指定する
# 02: 何かをインストールしたらapt-getのリストは削除する
# 03: `--no-install-recommends` を指定して追加のパッケージを回避します
RUN apt-get update \
    && apt-get install -y --no-install-recommends git=1:2.34.1-1ubuntu1.10 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
```

### コード規約チェック(hadolint)_補足

色々な方法で試したり活用できます。

- オンラインでも試せます
  - <https://hadolint.github.io/hadolint/>
- VSCodeの拡張機能もあります
  - <https://marketplace.visualstudio.com/items?itemName=exiasr.hadolint>
- dockerを使っても実行ができます。

dockerを使ってCIにも組み込めます。GitLabの場合は以下を`.gitlab-ci.yml`に書き足すだけです。

```yaml: .gitlab-ci.yml
hadolint:
  image: hadolint/hadolint:latest-debian
  script:
    - hadolint Dockerfile
```

## セキュリティ診断(Dockle)

Dockerfileのセキュリティ診断ツール(lint)です。

https://github.com/goodwithtech/dockle

```Dockerfile: 悪い例
FROM ubuntu:jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends git=1:2.34.1-1ubuntu1.10 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
```

```Dockerfile: 良い例
FROM ubuntu:jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends git=1:2.34.1-1ubuntu1.10 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 非ルートユーザを作成し、非ルートユーザとして実行するように
RUN useradd -d /home/dockle -m -s /bin/bash dockle
USER dockle
```

### セキュリティ診断(Dockle)_補足

dockerを使って実行ができます。

```bash: 実行方法
docker build -t test:v1 -f Dockerfile .
VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  goodwithtech/dockle:v${VERSION} test:v1
```

こちらもdockerを使ってCIにも組み込めます。GitLabの場合は以下を`.gitlab-ci.yml`に書き足すだけです。

https://github.com/goodwithtech/dockle-ci-test/blob/master/.gitlab-ci.yml

## クラウド上でのイメージスキャン(Amazon ECR Image scanning)

`Amazon ECR`のイメージスキャンは`ECR`にプッシュしたタイミングなどで実行され、`共通脆弱性識別子(CVE)`に基づく脆弱性をチェックしてくれます。
イメージスキャンのタイプは2種類あります。

- [ベーシックスキャン](https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/image-scanning-basic.html)
- [拡張スキャン](https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/image-scanning-enhanced.html)

詳しくは公式のドキュメントを参照ください。

https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/image-scanning.html

## おわりに

今回は「生成AIとの協業_Dockerfileの骨組み作成」を最初に紹介しました。
生成AIは誤った回答をする場合もある注意しましょう。

また、以下の静的解析などのツールを用いてチューニングすることでよりベストプラクティスに近くセキュリティも安全なイメージを作ることができます。

- hadolint
- Dockle
- Amazon ECR Image scanning

前回紹介したDevConrainerと組み合わせて開発環境構築にも活用してみてください。

https://zenn.dev/secondselection/articles/how_to_devcontainer

## 参考

https://github.com/hadolint/hadolint

https://github.com/goodwithtech/dockle

https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/image-scanning.html
