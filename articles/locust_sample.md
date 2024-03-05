---
title: "【初心者でも安心】Locustで始める負荷テスト"
emoji: "🦗"
type: "tech"
topics: [locust, python, test, 負荷テスト, パフォーマンス]
published: true
published_at: 2024-03-11 06:00
publication_name: "secondselection"
---

## はじめに

今回は以前プロジェクトで活用した負荷テストツールである「Locust」を備忘録として記事にしてみました。

プロジェクトでは、非機能要件として以下を満たしていることを確認するために利用しました。

- xxxx(PV数/日)のリクエストに耐えられること
- yy秒以内に処理が完了すること
- 同時アクセス数がzzまで耐えられること

今回、Locustを選んだのは最近よく使っているPythonでシナリオが記載できるからです。
Locustはdocker-composeを使うことでワーカーを増やし分散負荷を生成できる点も選定理由の1つです。
ただ、負荷テストツールには[JMeter](https://jmeter.apache.org/)や[k6](https://k6.io/)など様々なツールがあります。
どのツールを使うかは、プロジェクトの要件や開発者のスキルセットなどを考慮して選択する必要があります。

| ツール名 | 特徴 |
|---|---|
| [Locust](https://locust.io/) | Pythonユーザーにとって使いやすくシンプルなUIで初心者にもおすすめ |
| [JMeter](https://jmeter.apache.org/) | Javaで記述できるため多くの企業で利用されている |
| [k6](https://k6.io/) | JavaScriptで記述できるため、Webフロントエンド開発者にとって使いやすい |

## Locustとは

オープンソースの負荷テストツールのひとつで、ツール名から以下のようなイメージをもってください。
「蝗害」という言葉があるように大量発生したリクエスト(バッタやイナゴ)をどれだけ対処できるかをテストできるツールです。

![イメージ](/images/locust_sample/image.drawio.png)

https://locust.io/

### Locustのコード

locustの`task`がポイントで、ユーザが操作する想定のタスク（シナリオ）を指定できます。
また、複数のタスクを定義している場合、引数の重みを変えることでユーザが実施するタスクの割合を指定できます。

```python
from locust import HttpUser, task


class SampleApi(HttpUser):

    @task(1)
    def task_a(self):
        # requestのモジュールと同じ書き方でリクエストができます
        self.client.get('/tesk/a')

    @task(1)
    def task_b(self):
        self.client.get('/tesk/b')
```

### Locustの実行方法

まずは、簡単な実行方法を説明します。後半で少し具体的なサンプルを記載してますので、そちらも見てください。

Web UIを立ち上げてアクセスします。
※ `http://localhost:8089`でアクセスができます。

```bash: WEB UI立ち上げコマンド
locust -f xxxxxxxxx.py
```

![WEB画面](/images/locust_sample/web.drawio.png)

続いて、パラメータを入力しテストを開始します。

- `Number of users (peak concurrency)`: 同時ユーザ数(最大)
- `Ramp Up (users started/second)`: 1秒間でのユーザ増加数
- `Host`: リクエスト先

|実行結果(統計情報)|
|:-:|
|![実行結果A](/images/locust_sample/result_a.drawio.png)|

|実行結果(グラフ)|
|:-:|
|![実行結果A](/images/locust_sample/result_b.drawio.png)|

実行結果の応答時間が増加し、１秒当たりのリクエストが増加しなくなった場合、対象のアプリケーションは「過負荷」もしくは「飽和」状態になります。
その際の原因は様々ですので、調査の上対応しましょう。

#### 注意事項

- **リクエスト先には十分気をつけること**
  - リクエスト先を間違えると、本番サーバに負荷がかかることでサービスに影響与える可能性もあります。

## サンプル

サンプルとして今回は以下のようなテストを用意しました。

![サンプル環境](/images/locust_sample/dev_env.drawio.png)

さらに、今回はユーザのアクセスが正午（12時頃）に一番リクエストが多いIoTシステムをサンプルとして考えてます。
また、負荷によるレスポンス遅延として正午（12時頃）にレスポンスが遅くなるシステムとしてます。
※ あくまでサンプルです。

グラフで表すと以下のようなサンプルを構築してます。

![リクエスト数](/images/locust_sample/load_graph.drawio.png)

- **縦軸**：リクエスト数／秒
  - **オレンジ**：ユーザからのリクエスト
  - **ブルー**　：IoTシステムからのリクエスト

--------------------------------

ソースコードのサンプルは以下で公開しておりますが、ポイントを解説していきます。

https://gitlab.com/hijiri.umemoto/locust-sample

### ポイント

ポイントは、アクティブな時間帯を計算するところです。
これで、グラフのようなリクエストを実現してます（ベストな書き方があれば教えてください）。

```python: ポイント
from datetime import datetime
import random

# アクセスが集中する割合
access_rate = {
     0: 0.05,  1: 0.05,
     2: 0.05,  3: 0.05,
     4: 0.05,  5: 0.05,
     6: 0.2,   7: 0.4,
     8: 0.5,   9: 0.65,
    10: 0.75, 11: 0.9,
    12: 1.0,  13: 0.9,
    14: 0.75, 15: 0.65,
    16: 0.5,  17: 0.4,
    18: 0.2,  19: 0.05,
    20: 0.05, 21: 0.05,
    22: 0.05, 23: 0.05
}


class SampleUser:
    running_mode = False

    def set_running_mode(self, mode: bool):
        """ユーザのアクティブな時間帯
        Args:
            mode: ランディングテストモードにするか
        """
        self.running_mode = mode

    def user_active(self):
        """アクティブな時間帯をベースにリクエストがするかと検証する
        """
        if self.running_mode is False:
            return True

        # リクエストするかを計算する
        hour = datetime.now().hour
        rate = access_rate[hour]

        if random.random() <= rate:
            return True

        return False
```

### サンプルの実行・その結果

では、実際に上記のサンプルを動かしてみます。

```bash
# テスト用サーバ起動コマンド
uvicorn app.main:app --host=0.0.0.0 --reload

# ランディングテストのような形式のテスト
locust -f test_running.py

# サンプルでは通常パターンのテストは以下のコマンドで実行できます。
locust -f test_load.py
```

|実行結果(統計情報)|
|:-:|
|![実行結果C](/images/locust_sample/result_c.drawio.png)|

|実行結果(グラフ)|
|:-:|
|![実行結果D](/images/locust_sample/result_d.drawio.png)|

## おわりに

負荷テストツールである「Locust」について記事にしてみました。
普段使っているPythonでシナリオを記載できるので、個人的には感覚が掴みやすかったです。

今回の記事では説明できませんでしたが、`docker`を使って分散負荷テストの実行も可能です。

- <https://docs.locust.io/en/2.0.0/running-locust-docker.html>
- <https://book.st-hakky.com/hakky/distributed-processing-locust-with-docker/>
