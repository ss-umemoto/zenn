---
title: "GA4のデータを収集して、issueに貯めてみた"
emoji: "🖨️"
type: "tech"
topics: [gitlab, googleanalytics, python]
published: true
published_at: 2024-02-26 09:00
publication_name: "secondselection"
---

## はじめに

この記事はGA4の集計データをGitLabのissueに貯めて（保存して）みたというやってみた記事です。

きっかけは「探索レポートで2か月前までしか参照できない」のため、どこかに貯めたいなと思ったことがきっかけです。
※ 記事を書くために調べて初めて知りました。

https://inhouse-plus.jp/marketing/data-retention

最終的に作ってみたものとしては、以下のような流れでデータを保管します。

1. GitLabのCIで毎日スクリプト（Python）を実行する
2. GA4 Data APIでデータを取得し、Issueに集計結果を保存する

## 下準備

クイックスタートを参考に、APIを有効化して認証情報を作成します。
作成した認証情報をGitLabのセキュリティファイルとして設定します。

https://developers.google.com/analytics/devguides/reporting/data/v1/quickstart-client-libraries?hl=ja#python

### １．APIを有効にする

|APIの有効化手順|
|:-:|
|![step01](/images/ga4_api_sample/step01.drawio.png)|

#### 発行された認証情報は以下のような形式になります

```json
{
  "type": "service_account",
  "project_id": "xxxxxxxxxxxxxxx",
  "private_key_id": "xxxxxxxxxxxxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nxxxxxxxxxxxxxxxxx\n-----END PRIVATE KEY-----\n",
  "client_email": "xxxxxxxxxxxxxxx@xxxxxxxxxxxxxxx.iam.gserviceaccount.com",
  "client_id": "xxxxxxxxxxxxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/xxxxxxxxxxxxxxx%40xxxxxxxxxxxxxxx.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```

### ２．GA4にサービスアカウントを追加する

|サービスアカウント追加手順|
|:-:|
|![step02_1](/images/ga4_api_sample/step02_1.drawio.png)![step02_2](/images/ga4_api_sample/step02_2.drawio.png)![step02_3](/images/ga4_api_sample/step02_3.drawio.png)|

### ３．GitLabのセキュリティファイルとして登録する

|セキュリティファイル格納場所|
|:-:|
|![step03](/images/ga4_api_sample/step03.drawio.png)|

## 実装

作ったものの簡単なフローは以下になり、ソースコードも公開してます。

https://gitlab.com/hijiri.umemoto/ga4-api-sample

```mermaid
sequenceDiagram
autonumber

participant ga4 as Google Analytics
participant rpa as バッチ処理<br>【CI・スケジュール実行】
participant gitlab as GitLab【Issue】


rpa ->> ga4: レポートを取得(API)
ga4 -->> rpa: 

rpa ->> rpa: 集計をする

rpa -->> gitlab: issueに集計結果を登録する
```

|集計結果のサンプル|
|:-:|
|![issue_sample](/images/ga4_api_sample/issue_sample.drawio.png)|

### GA4のデータ取得処理

以下はPV数を取得する部分のコードを抜粋したものです。
`RunReportRequest`で取得するための以下のパラメータを指定する形になります。

- `dimensions`: ディメンション
  - 今回は`pageTitle`(ページタイトル), `hostName`(ホスト名), `pagePath`(パス)を指定
- `metrics`: 指標
  - 今回は`screenPageViews`(PV数)を指定
- `date_ranges`: 取得範囲

```python: app/services/ga4.py
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange,
    Dimension,
    Metric,
    RunReportRequest,
)

class GA4:
    def __init__(self):
        self.client = BetaAnalyticsDataClient()

    def get_month_pv(
        self,
        start_date: str,
        end_date: str
    ) -> List[PVData]:
        # PV数をページタイトル毎に取得する
        request = RunReportRequest(
            property=f"properties/{property_id}",
            dimensions=[
                Dimension(name="pageTitle"),
                Dimension(name="hostName"),
                Dimension(name="pagePath")
            ],
            metrics=[Metric(name="screenPageViews")],
            date_ranges=[DateRange(
                start_date=start_date,
                end_date=end_date
            )]
        )
        response = self.client.run_report(request)
```

指定できるデータの属性や計測値は以下に記載されてます。

https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema?hl=ja#metrics

### CIの設定に関するポイント

今回初めて知りましたが、CI実行時にGitLabのセキュリティファイルは以下でダウンロードができます。

```yaml
scheduler:
  script:
    - apk add --update curl && rm -rf /var/cache/apk/*
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | sh
    - # 省略
```

## おわりに

今回は、GA4のAPIを使いデータを取得してGitLabに集計結果を保存できるにしました。
issueにすることで、社内に先月分のPV数を共有するにも便利かもと考えてます。今度試してみよう。
