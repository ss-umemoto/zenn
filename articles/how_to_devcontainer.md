---
title: "【超便利】DevContainerでサクッと開発環境を構築しよう！"
emoji: "🔖"
type: "tech"
topics: [vscode, devcontainer, 環境構築]
published: true
published_at: 2024-03-11 06:00
publication_name: "secondselection"
---

## はじめに

`Dev Container`の拡張機能はコンテナ（docker）を利用して開発環境を構築できる機能です。
この記事では、新規構築だけではなく既存のDockerfileやdocker-compose.ymlを使ったパターンについても紹介していきます。

- [zennの執筆環境（新規構築）](#zennの執筆環境新規構築)
- [既存のDockerfileを利用した構築](#既存のdockerfileを利用した構築)
- [既存のdocker-compose.ymlを利用した構築](#既存のdocker-composeymlを利用した構築)

## Dev Containerとは

[VSCode](https://code.visualstudio.com/)は定番のコードエディタで、様々な「拡張機能」を追加して機能拡張できる点が特徴の1つです。他にも主要なプラットフォームで使えるなど様々な特徴を持っています。
[Docker](https://www.docker.com/ja-jp/)を利用して環境構築可能な拡張機能が`Dev Container`です。

https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

### 特徴

- VSCodeとDockerがインストールされていれば、開発構築が簡単に構築できます
  - Dockerfileやdocker-composeにも対応している
- コード（ファイル）化されるので、構築時の差異が発生しづらい
  - VSCodeの拡張機能も指定できる（拡張機能を統一もできる）

## zennの執筆環境（新規構築）

zennの執筆環境としても活用しているので、例として紹介します。
zennの記事以外にもmarkdownを使っている設計書などにも活用できます。

構築手順は後述しますが、最終的にできた設定ファイル`devcontainer.json`は以下になります。

```json: devcontainer.json
{
  "name": "zenn",
  // dockerイメージ
  "image": "mcr.microsoft.com/devcontainers/base:jammy",
  // nodeやpythonなどのインストール設定
  "features": {
    "ghcr.io/devcontainers/features/node:1": {}
  },
  "customizations": {
    // カスタマイズ
    "vscode": {
      "extensions": [
        "taichi.vscode-textlint",  // 文章校正として、textlintの拡張機能
        "DavidAnson.vscode-markdownlint",  // Markdownの構文とスタイルをチェックの拡張機能
        "hediet.vscode-drawio",  // 図を記載する際に使うdrawioの拡張機能
        "bierner.markdown-mermaid"  // mermaidの記載もプレビューできるようにする拡張機能
      ],
      "settings": {}
    }
  },
  // 起動時の実行コマンド
  // 今回はnodejsのパッケージをインストール
  "postCreateCommand": "yarn install"
}
```

### zennの執筆環境_構築完了後

構築完了後、以下のことができる環境になります。

- `Zenn CLI`がターミナルで実行できる
- 校正がVSCode上でできる
  - [textlint](https://github.com/textlint/textlint)
  - [markdownlint](https://github.com/DavidAnson/markdownlint)
- 図などを編集・プレビューできる
  - [draw.io](https://www.drawio.com/)
  - [mermaid](https://mermaid.js.org/)

### zennの執筆環境_新規構築の流れ

GUIで指定した方法を記載しますが、慣れてきたら`.devcontainer/devcontainer.json`を書いた方が個人的には速いです。

1. VSCodeの左下「><」を選択します。
2. `Open Container Configuration File`を選択します。  
  ![step001](/images/how_to_devcontainer/step001.drawio.png)
3. イメージを選択します。今回は"Ubuntu"のイメージを選びます。  
  ![step002](/images/how_to_devcontainer/step002.drawio.png)
4. "jammy"のタグを選びます。
5. 元のイメージにはないツールとして"Nodejs"を入れるように選択します。  
  ![step003](/images/how_to_devcontainer/step003.drawio.png)
6. "OK"⇒"Keep Defaults"で選択すると、設定ファイルが作成されます。
    - `.devcontainer/devcontainer.json`
7. 右下に表示される`Reopen in Container`をクリックして環境を立ち上げます。
8. nodejsがインストールされた環境(コンテナ)が立ち上がるので、お好きなパッケージ管理でパッケージをダウンロードします。
    - zenn-cli (例：`yarn add zenn-cli`)
    - markdownlint-cli2 (例：`yarn add --dev markdownlint-cli2`)
    - textlint (例：`yarn add --dev textlint`)
        - textlint-rule-xxxも同時に追加します。
9. ここまでの設定だとdevcontainer起動してすぐはパッケージがインストールされないので、`devcontainer.json`の`postCreateCommand`にインストールコマンドを記載します。
    - `postCreateCommand`は環境(コンテナ)起動時に毎回呼ばれるコマンドです。
    - 例：`yarn install`
10. 続いて拡張機能を`devcontainer.json`の`customizations.vscode.extensions`に指定します。
    - 拡張機能のIDの確認方法は以下になります。  
      ![step004](/images/how_to_devcontainer/step004.drawio.png)
11. `devcontainer.json`を保存すると、右下に`ReBuild`が表示されるのでクリックします。

※ フロントエンド(VueやReactなど)の開発環境も同じように構築ができます。

## 既存のDockerfileを利用した構築

すでにDockerfileを使って環境を構築してる場合でもdevcontainerを活用できます。
基本は同じで、`devcontainer.json`の一部を変えるのみです。

```diff json: devcontainer.json
{
-   "image": "mcr.microsoft.com/devcontainers/base:jammy",
-   "features": {
-     "ghcr.io/devcontainers/features/node:1": {}
-   }
+   "build": {
+     "dockerfile": "../Dockerfile"
+   },
}
```

想定フォルダ構成は以下です。

- .devcontainer
  - devcontainer.json
- Dockerfile (すでにあったファイル)

## 既存のdocker-compose.ymlを利用した構築

同じくすでにdocker-composeを使って環境(WEB+DB)を構築してる場合でもdevcontainerを活用できます。
基本は同じで、`devcontainer.json`の一部を変えるのみです。

```diff json: devcontainer.json
{
-   "image": "mcr.microsoft.com/devcontainers/base:jammy",
-   "features": {
-     "ghcr.io/devcontainers/features/node:1": {}
-   }
+  "dockerComposeFile": [
+    "../docker-compose.yml"
+  ],
+  "service": "サービス名",
+  "workspaceFolder": "フォルダパス",
}
```

想定フォルダ構成は以下です。

- .devcontainer
  - devcontainer.json
- docker-compose.yml (すでにあったファイル)

## その他サンプル

### Pythonの開発環境として使いたい場合

:::details Python+poetry

- .devcontainer
  - devcontainer.json
  - Dockerfile

```json: devcontainer.json
{
  "name": "poetry3-poetry-pyenv",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "njpwerner.autodocstring"
      ]
    }
  }
}
```

```dockerfile: Dockerfile
FROM mcr.microsoft.com/devcontainers/base:jammy
# FROM mcr.microsoft.com/devcontainers/base:jammy 

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=vscode

RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update \ 
    && apt-get install -y build-essential --no-install-recommends make \
        ca-certificates \
        git \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncurses5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev

# Python and poetry installation
USER $USER
ARG HOME="/home/$USER"
ARG PYTHON_VERSION=3.10
# ARG PYTHON_VERSION=3.10

ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${HOME}/.local/bin:$PATH"

RUN echo "done 0" \
    && curl https://pyenv.run | bash \
    && echo "done 1" \
    && pyenv install ${PYTHON_VERSION} \
    && echo "done 2" \
    && pyenv global ${PYTHON_VERSION} \
    && echo "done 3" \
    && curl -sSL https://install.python-poetry.org | python3 - \
    && poetry config virtualenvs.in-project true
```

:::

### Laravel(DBコンテナ含む)の開発環境として使いたい場合

:::details Laravel+MySQL

- .devcontainer
  - devcontainer.json
- docker
  - Dockerfile
- docker-compose.yml

```json: devcontainer.json
{
  "name": "PHP",
  "dockerComposeFile": [
    "../docker-compose.yml"
  ],
  "service": "webapp",
  "workspaceFolder": "/var/www/html"
}
```

```yml: docker-compose.yml
version: '3'

services:
  webapp:
    build:
      context: ./docker
      dockerfile: Dockerfile
      args:
        WWWGROUP: '${WWWGROUP}'
    extra_hosts:
      - 'host.docker.internal:host-gateway'
    ports:
      - '${APP_PORT:-80}:80'
    environment:
      WWWUSER: '${WWWUSER}'
      LARAVEL_SAIL: 1
      XDEBUG_MODE: '${SAIL_XDEBUG_MODE:-off}'
      XDEBUG_CONFIG: '${SAIL_XDEBUG_CONFIG:-client_host=host.docker.internal}'
    volumes:
      - './:/var/www/html'
      - vol_vendor:/var/www/html/vendor
      - vol_node_modules:/var/www/html/node_modules
    depends_on:
      - mysql

  mysql:
    image: 'mysql/mysql-server:8.0'
    ports:
      - '${FORWARD_DB_PORT:-3306}:3306'
    environment:
      MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'
      MYSQL_ROOT_HOST: '%'
      MYSQL_DATABASE: '${DB_DATABASE}'
      MYSQL_USER: '${DB_USERNAME}'
      MYSQL_PASSWORD: '${DB_PASSWORD}'
      MYSQL_ALLOW_EMPTY_PASSWORD: 1
    volumes:
      - 'vol_mysql:/var/lib/mysql'
    healthcheck:
      test:
        - CMD
        - mysqladmin
        - ping
        - '-p${DB_PASSWORD}'
      retries: 3
      timeout: 5s

volumes:
  vol_mysql:
    driver: local
  vol_node_modules:
    driver: local
  vol_vendor:
    driver: local
```

```dockerfile: Dockerfile
FROM ubuntu:22.04

ARG WWWGROUP
ARG NODE_VERSION=18
ARG POSTGRES_VERSION=15

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php8.3-cli php8.3-dev \
    php8.3-pgsql php8.3-sqlite3 php8.3-gd php8.3-imagick \
    php8.3-curl \
    php8.3-imap php8.3-mysql php8.3-mbstring \
    php8.3-xml php8.3-zip php8.3-bcmath php8.3-soap \
    php8.3-intl php8.3-readline \
    php8.3-ldap \
    php8.3-msgpack php8.3-igbinary php8.3-redis php8.3-swoole \
    php8.3-memcached php8.3-pcov php8.3-xdebug \
    libapache2-mod-php8.3 apache2 \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -sLS https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client-$POSTGRES_VERSION \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.3

RUN groupadd --force -g $WWWGROUP sail
RUN useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail

COPY php.ini /etc/php/8.3/apache2/php.ini
RUN cp -R /etc/php/8.3/cli/conf.d /etc/php/8.3/apache2/conf.d
COPY apache/default.conf /etc/apache2/sites-enabled/000-default.conf
RUN a2enmod rewrite

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
```

:::

## おわりに

`Dev Container`の拡張機能を使った環境構築について改めてまとめました。
常々思っていますが、コンテナでの環境構築はかなり便利です。また、`Dev Container`を使うことで開発環境でのlintなどの拡張機能をチームで統一ができます。
すでにDockerfileやdocker-composeを使っていれば、簡単に利用できる点でも好きな拡張機能です。

最後に`Dev Container`を使うメリットをまとめておきます。

- ローカル環境を汚さない
- 環境構築をコード化できる
- lintなどの拡張機能をチームで統一ができる
- dockerを使っているプロジェクトであれば、容易に使える

## 参考

https://codezine.jp/article/detail/16467

https://zenn.dev/suzuki_hoge/books/2022-03-docker-practice-8ae36c33424b59/viewer/1-3-docker

https://zenn.dev/conecone/articles/ab8d71d81e64bb

https://qiita.com/yoshii0110/items/c480e98cfe981e36dd56
