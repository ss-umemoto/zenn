---
title: "OpenAPIでのファイル分割とサンプルデータの管理法"
emoji: "🧩"
type: "tech"
topics: [openapi, swagger, openapigenerator, prisma, typescript]
published: true
published_at: 2024-05-15 06:00
publication_name: "secondselection"
---

## はじめに

OpenAPIとは、「YAML形式」か「JSON形式」で記載するAPI仕様書の記述フォーマットです。
今回はメンテナンス性が高いOpenAPIの定義ファイル分割をメインに以下について説明していきます。

- [OpenAPIとは](#openapiとは)
- [OpenAPIの定義ファイル分割](#openapiの定義ファイル分割)
- [クライアントコードの自動生成](#クライアントコードの自動生成)

### サンプルコード

https://gitlab.com/hijiri.umemoto/openapi-sample

## OpenAPIとは

OpenAPIとは、「YAML形式」か「JSON形式」で記載するAPI仕様書の記述フォーマットです。元々はSwaggerとして知られていました。
このフォーマットを利用することで以下のAPI構造を記述でき、設計・開発・テストおよびドキュメント作成のプロセスを簡素化・標準化するのに役立ちます。

- APIのエンドポイント
- リクエストとレスポンスの形式
- 認証方法
- etc...

以下の記事が分かりやすく解説してるので、この記事では詳細は割愛します。

https://www.aeyescan.jp/blog/openapi/

### OpenAPIの定義ファイル分割

定義ファイルを1つのファイルで管理した場合、長すぎる1つのファイルになるため保守が大変です。特にサンプルデータも記載すると大変長いファイルになります。
そのため、定義ファイルを分割することで管理を楽にします。フォルダ構成は以下になります。

```txt:サンプルコードのフォルダ構成
docker
└ api-mock
  ├ openapi.yaml  # マージ後のAPI仕様書
  ├ base.yaml     # マージ前のAPI仕様書
  ├ examples      # レスポンス例
  ├ paths         # エンドポイント
  └ schemas       # スキーマ
```

分割したままだと使えないので、コマンドを実行して分割された定義を1つにマージします。
※ 今回は[swagger-merger](https://github.com/WindomZ/swagger-merger#readme)というライブラリを使ってマージします。

分割されているファイルが別のファイルを参照していると、1度の実行ではすべてマージされません。そこで、スクリプトを組んでファイル参照がなくなるまでマージ用のコマンドを実行してマージします。
作成したスクリプトは以下になります。

```bash:swagger-merger.sh
#!/bin/sh

# マージ前後のファイルを指定
base_filename="docker/api-mock/base.yaml"
out_filename="docker/api-mock/openapi.yaml"

# 一回目のマージ
yarn swagger-merger -i $base_filename -o $out_filename

# 参照ファイルがなくなるまでループする
# ※ "$ref: [^']*\.yaml"が一致する文字列がなくなるまでループする
while grep -q "\$ref: [^']*\.yaml" "$out_filename"
do
    yarn swagger-merger -i $out_filename -o $out_filename
done

echo "出力が完了しました"
```

https://github.com/WindomZ/swagger-merger#readme

|マージイメージ|
|:-:|
|![マージイメージ](/images/openapi_sample/image.drawio.png)|

## クライアントコードの自動生成

OpenAPIを使っているので、クライアントコードを自動生成して開発効率を向上します。
以下のサンプルでは`typescript-axios`のジェネレータを使っています。

https://openapi-generator.tech/

```bash:typescript-axiosの場合
yarn openapi-generator-cli generate \
    -i "定義ファイルの場所" \
    -o "出力先" \
    -g typescript-axios
```

## おわりに

今回はOpenAPIに関して以下について説明しました。
OpenAPIの定義ファイルを分割することでメンテナンス性を担保できます。
さらに`OpenAPI Generator`を使うことで型安全なフロントエンドを開発しやすくなります。

- [OpenAPIとは](#openapiとは)
- [OpenAPIの定義ファイル分割](#openapiの定義ファイル分割)
- [クライアントコードの自動生成](#クライアントコードの自動生成)

## 参考

https://zenn.dev/mizu4ma/articles/d3b937b321f3b4
