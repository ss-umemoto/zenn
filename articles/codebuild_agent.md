---
title: "ローカル環境でCodeBuildを爆速実行！テスト・デバッグも楽々！"
emoji: "🏗"
type: "tech"
topics: [aws, codebuild]
published: true
published_at: 2024-03-04 09:00
publication_name: "secondselection"
---

## はじめに

この記事は`CodeBuildエージェント`を使ってローカルでCodeBuildのビルドの検証(ビルド)をした際の備忘録です。
CodeBuildの利用を検討している開発者にとっては、このサービスを使いローカルでCodeBuildを実行して開発効率とコスト削減を実現できます。

- ローカルで事前に検証(ビルド)することで、余計なコミットを**減らせる**
- 検証のためのビルドが減り、ビルドの合計時間を短縮できる（少額だが、**コスト削減が見込める**）

筆者はこの機能を知らず以下のようなことをやらかしていました。

- 検証用のコミットをそこそこ生産していた
- 検証のためにAWSコストをかけてしまった

## CodeBuildとは

[公式](https://aws.amazon.com/jp/codebuild/)の言葉を借りると「ソースコードをコンパイルし、テストを実行し、すぐにデプロイできるソフトウェアパッケージを生成する、フルマネージド型の継続的インテグレーションサービス」です。

Codebuildの料金は「ビルド時間」と「コンピューティングタイプ」によって決まります。
そのため、コスト面を考えるとビルド時間は短い方がよく余計なビルドは避けたほうがいいです。

https://aws.amazon.com/jp/codebuild/pricing/

## CodeBuildエージェント

「CodeBuildエージェント」を使うことで、ローカルでCodeBuildを実行・検証できることが可能です。

https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/use-codebuild-agent.html

実行するにはローカルに以下のツールが必須です（筆者はWSL2で検証しています）。

- Git
- Docker

### 実際にやってみよう

1. ビルドイメージをプルします。
  ```bash
    docker pull public.ecr.aws/codebuild/amazonlinux2-x86_64-standard:4.0
  ```
2. CodeBuildエージェントのイメージをプルします。
  ```bash
    docker pull public.ecr.aws/codebuild/local-builds:latest
  ```
3. 対象プロジェクトのディレクトリに移動します。
4. 実行スクリプトをダウンロードします。
  ```bash
    curl -O  https://raw.githubusercontent.com/aws/aws-codebuild-docker-images/master/local_builds/codebuild_build.sh
    chmod +x codebuild_build.sh
  ```
5. 実行スクリプトを実行します。
  ```bash
    ./codebuild_build.sh -i <1でプルしたイメージ> -a <アーティファクト出力先>
  ```

#### 実行結果

vue3のプロジェクトを想定した`buildspec.yml`を準備して実施します。

```yml: buildspec.yml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 16
      python: 3.9
    commands:
      - echo update npm...
      - n 16
      - npm update -g npm
      - echo node -v
      - node -v
      - echo npm -v
      - npm -v
      - echo install yarn...
      - npm install -g yarn
      - echo yarn -v
      - yarn -v
  pre_build:
    commands:
      - echo install packeages test...
      - yarn install
  build:
    commands:
      - yarn build
artifacts:
  files:
    - 'dist/*'
```

```bash: 実行結果
user@host:~/xxxx$ ./codebuild_build.sh -i public.ecr.aws/codebuild/amazonlinux2-x86_64-standard:4.0 -a test/
Build Command:

docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e "IMAGE_NAME=public.ecr.aws/codebuild/amazonlinux2-x86_64-standard:4.0" -e "ARTIFACTS=/home/ssuser/work/SS/system/reviewsupport/test/" -e "SOURCE=/home/ssuser/work/SS/system/reviewsupport" -e "INITIATOR=ssuser" public.ecr.aws/codebuild/local-builds:latest

Removing agent-resources_build_1 ... done
Removing agent-resources_agent_1 ... done
Removing network agent-resources_default
Removing volume agent-resources_source_volume
Removing volume agent-resources_user_volume
Creating network "agent-resources_default" with the default driver
Creating volume "agent-resources_source_volume" with local driver
Creating volume "agent-resources_user_volume" with local driver
Creating agent-resources_agent_1 ... done
Creating agent-resources_build_1 ... done
Attaching to agent-resources_agent_1, agent-resources_build_1
agent_1  | [Container] 2024/02/25 06:08:36 Waiting for agent ping
agent_1  | [Container] 2024/02/25 06:08:36 Waiting for DOWNLOAD_SOURCE
agent_1  | [Container] 2024/02/25 06:08:37 Phase is DOWNLOAD_SOURCE
agent_1  | [Container] 2024/02/25 06:08:37 CODEBUILD_SRC_DIR=/codebuild/output/src487227837/src
agent_1  | [Container] 2024/02/25 06:08:37 yamlDoc
agent_1  | [Container] 2024/02/25 06:08:37 YAML location is /codebuild/output/srcDownload/src/buildspec.yml
agent_1  | [Container] 2024/02/25 06:08:37 Processing environment variables
agent_1  | [Container] 2024/02/25 06:08:37 Running command echo "Installing Node.js version 16 ..."
agent_1  | Installing Node.js version 16 ...
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:37 Running command n $NODE_16_VERSION
agent_1  |      copying : node/16.20.1
agent_1  |    installed : v16.20.1 (with npm 8.19.4)
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:41 Running command echo "Installing Python version 3.9 ..."
agent_1  | Installing Python version 3.9 ...
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:41 Running command pyenv global  $PYTHON_39_VERSION
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:41 Moving to directory /codebuild/output/src487227837/src
agent_1  | [Container] 2024/02/25 06:08:41 Registering with agent
agent_1  | [Container] 2024/02/25 06:08:41 Phases found in YAML: 3
agent_1  | [Container] 2024/02/25 06:08:41  INSTALL: 11 commands
agent_1  | [Container] 2024/02/25 06:08:41  PRE_BUILD: 2 commands
agent_1  | [Container] 2024/02/25 06:08:41  BUILD: 1 commands
agent_1  | [Container] 2024/02/25 06:08:41 Phase complete: DOWNLOAD_SOURCE State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:08:41 Phase context status code:  Message: 
agent_1  | [Container] 2024/02/25 06:08:41 Entering phase INSTALL
agent_1  | [Container] 2024/02/25 06:08:41 Running command echo update npm...
agent_1  | update npm...
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:41 Running command n 16
agent_1  |   installing : node-v16.20.2
agent_1  |        mkdir : /usr/local/n/versions/node/16.20.2
agent_1  |        fetch : https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.xz
agent_1  |      copying : node/16.20.2
agent_1  |    installed : v16.20.2 (with npm 8.19.4)
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:44 Running command npm update -g npm
agent_1  | npm WARN EBADENGINE Unsupported engine {
agent_1  | npm WARN EBADENGINE   package: 'npm@10.4.0',
agent_1  | npm WARN EBADENGINE   required: { node: '^18.17.0 || >=20.5.0' },
agent_1  | npm WARN EBADENGINE   current: { node: 'v16.20.2', npm: '8.19.4' }
agent_1  | npm WARN EBADENGINE }
agent_1  | 
agent_1  | removed 41 packages, changed 106 packages, and audited 457 packages in 3s
agent_1  | 
agent_1  | 38 packages are looking for funding
agent_1  |   run `npm fund` for details
agent_1  | 
agent_1  | 1 moderate severity vulnerability
agent_1  | 
agent_1  | To address all issues, run:
agent_1  |   npm audit fix
agent_1  | 
agent_1  | Run `npm audit` for details.
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:47 Running command echo node -v
agent_1  | node -v
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:47 Running command node -v
agent_1  | v16.20.2
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:47 Running command echo npm -v
agent_1  | npm -v
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:47 Running command npm -v
agent_1  | npm WARN cli npm v10.4.0 does not support Node.js v16.20.2. This version of npm supports the following node versions: `^18.17.0 || >=20.5.0`. You can find the latest version at https://nodejs.org/.
agent_1  | 10.4.0
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:48 Running command echo install yarn...
agent_1  | install yarn...
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:48 Running command npm install -g yarn
agent_1  | npm WARN cli npm v10.4.0 does not support Node.js v16.20.2. This version of npm supports the following node versions: `^18.17.0 || >=20.5.0`. You can find the latest version at https://nodejs.org/.
agent_1  | 
agent_1  | added 1 package in 1s
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:49 Running command echo yarn -v
agent_1  | yarn -v
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:49 Running command yarn -v
agent_1  | 1.22.21
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:50 Phase complete: INSTALL State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:08:50 Phase context status code:  Message: 
agent_1  | [Container] 2024/02/25 06:08:50 Entering phase PRE_BUILD
agent_1  | [Container] 2024/02/25 06:08:50 Running command echo install packeages test...
agent_1  | install packeages test...
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:50 Running command yarn install
agent_1  | yarn install v1.22.21
agent_1  | [1/4] Resolving packages...
agent_1  | success Already up-to-date.
agent_1  | $ husky install
agent_1  | fatal: detected dubious ownership in repository at '/codebuild/output/srcDownload/src'
agent_1  | To add an exception for this directory, call:
agent_1  | 
agent_1  |      git config --global --add safe.directory /codebuild/output/srcDownload/src
agent_1  | husky - git command not found, skipping install
agent_1  | Done in 0.35s.
agent_1  | 
agent_1  | [Container] 2024/02/25 06:08:50 Phase complete: PRE_BUILD State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:08:50 Phase context status code:  Message: 
agent_1  | [Container] 2024/02/25 06:08:50 Entering phase BUILD
agent_1  | [Container] 2024/02/25 06:08:50 Running command yarn build
agent_1  | yarn run v1.22.21
agent_1  | $ vue-tsc && vite build
agent_1  | vite v4.4.9 building for production...
agent_1  | transforming...
agent_1  | ? 629 modules transformed.
agent_1  | rendering chunks...
agent_1  | computing gzip size...
agent_1  | dist/index.html                                                               0.53 kB ? gzip:   0.32 kB
agent_1  | dist/assets/materialdesignicons-webfont-c1c004a9.woff2                      396.73 kB
agent_1  | dist/assets/materialdesignicons-webfont-80bb28b3.woff                       576.75 kB
agent_1  | dist/assets/materialdesignicons-webfont-a58ecb54.ttf                      1,279.99 kB
agent_1  | dist/assets/materialdesignicons-webfont-67d24abe.eot                      1,280.21 kB
agent_1  | dist/assets/index-9abfce96.css                                                0.04 kB ? gzip:   0.06 kB
agent_1  | dist/assets/detail-modal-843ffaff.css                                        22.87 kB ? gzip:   4.55 kB
agent_1  | dist/assets/index-06e8ebe1.css                                              715.55 kB ? gzip: 102.15 kB
agent_1  | dist/assets/_plugin-vue_export-helper-c27b6911.js                             0.15 kB ? gzip:   0.16 kB ? map:     0.12 kB
agent_1  | dist/assets/404-1c9fa398.js                                                   0.28 kB ? gzip:   0.24 kB ? map:     0.29 kB
agent_1  | dist/assets/login-440ec6ec.js                                                 0.42 kB ? gzip:   0.35 kB ? map:     1.12 kB
agent_1  | dist/assets/useReviewDetail-77169229.js                                       0.49 kB ? gzip:   0.33 kB ? map:     1.81 kB
agent_1  | dist/assets/index-a771b714.js                                                 1.80 kB ? gzip:   1.04 kB ? map:     3.42 kB
agent_1  | dist/assets/review-type.vue_vue_type_script_setup_true_lang-3feb862f.js       2.41 kB ? gzip:   1.16 kB ? map:     4.36 kB
agent_1  | dist/assets/index-ffbe610a.js                                                 3.14 kB ? gzip:   1.39 kB ? map:     6.38 kB
agent_1  | dist/assets/index-e5284ff2.js                                                 4.08 kB ? gzip:   1.34 kB ? map:     5.54 kB
agent_1  | dist/assets/detail-modal.vue_vue_type_script_setup_true_lang-8c45e418.js     43.63 kB ? gzip:  14.02 kB ? map:   184.98 kB
agent_1  | dist/assets/index-1d7765b9.js                                               105.56 kB ? gzip:  37.38 kB ? map:   455.53 kB
agent_1  | dist/assets/index-6d49ce71.js                                               721.18 kB ? gzip: 233.24 kB ? map: 3,184.43 kB
agent_1  | 
agent_1  | (!) Some chunks are larger than 500 kBs after minification. Consider:
agent_1  | - Using dynamic import() to code-split the application
agent_1  | - Use build.rollupOptions.output.manualChunks to improve chunking: https://rollupjs.org/configuration-options/#output-manualchunks
agent_1  | - Adjust chunk size limit for this warning via build.chunkSizeWarningLimit.
agent_1  | ? built in 8.49s
agent_1  | Done in 14.72s.
agent_1  | 
agent_1  | [Container] 2024/02/25 06:09:05 Phase complete: BUILD State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:09:05 Phase context status code:  Message: 
agent_1  | [Container] 2024/02/25 06:09:05 Entering phase POST_BUILD
agent_1  | [Container] 2024/02/25 06:09:05 Phase complete: POST_BUILD State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:09:05 Phase context status code:  Message: 
agent_1  | [Container] 2024/02/25 06:09:05 Expanding base directory path: .
agent_1  | [Container] 2024/02/25 06:09:05 Assembling file list
agent_1  | [Container] 2024/02/25 06:09:05 Expanding .
agent_1  | [Container] 2024/02/25 06:09:05 Expanding file paths for base directory .
agent_1  | [Container] 2024/02/25 06:09:05 Assembling file list
agent_1  | [Container] 2024/02/25 06:09:05 Expanding dist/*
agent_1  | [Container] 2024/02/25 06:09:05 Found 3 file(s)
agent_1  | [Container] 2024/02/25 06:09:05 Preparing to copy secondary artifacts
agent_1  | [Container] 2024/02/25 06:09:05 No secondary artifacts defined in buildspec
agent_1  | [Container] 2024/02/25 06:09:05 Phase complete: UPLOAD_ARTIFACTS State: SUCCEEDED
agent_1  | [Container] 2024/02/25 06:09:05 Phase context status code:  Message: 
agent-resources_build_1 exited with code 0
Aborting on container exit...
```

```bash: アーティファクトも出力されてます。
ls -l
user@host:~/xxxx/test$ ls
artifacts.zip
```

## おわりに

今回は`CodeBuildエージェント`を使ってローカルでCodeBuildのビルドの検証(ビルド)する方法についてまとめました。
ローカルでCodeBuildの検証ができるので、検証用のコミットやビルドの実行が不要になり、「開発効率」と「コスト削減」を実現できます。
無知によって無駄なコミットや料金を発生させていた昔の自分に教えてあげたい（公式ドキュメントはさらっとでも読むべきだなと実感しました）。

## 参考

https://qiita.com/sakai00kou/items/76150753d3dd1a38d578
