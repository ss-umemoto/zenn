---
title: "PythonでMQTTについて学ぼう（devcontainerによる開発環境構築付き）"
emoji: "🔗"
type: "tech"
topics: [python, mqtt, 初心者向け]
published: true
published_at: 2024-09-17 06:00
publication_name: "secondselection"
---

## はじめに

この記事は、「MQTTとはなにか」から実際にPythonを使ってMQTTを用いたデータ通信の方法について記載しています。

## MQTTとは

MQTTとは、非同期に1対多の通信ができるプロトコルで、IoTシステムなどで多数のデバイス間で短いメッセージを頻繁に送受信するようなシーンで利用されています。

| 用語 | 説明 |
| --- | ---- |
| トピック (Topic) | メッセージ送受信のキー情報 (`/`を使って階層構造を表現できる) |
| メッセージ (Message) | デバイス間で交換される情報 |
| ブローカー (Broker) | ・MQTTにおけるサーバーの役割<br />・サブスクライバーとパブリッシャーの仲介する |
| サブスクライバー (Subscriber) | ・ブローカーからトピックを受信するクライアント<br>・ワイルドカードの`#`や`+`を使うことで複数のトピックを受信も可能 |
| パブリッシャー (Publisher) | ブローカーに向けてメッセージを送信するクライアント |

### MQTTの特徴

MQTTの特徴としては以下の5つが挙げられます。

1. 軽量で効率的
    - MQTTはメッセージヘッダーが小さく、小さいことでネットワーク帯域幅を最適化できる。
    - 必要なリソースが少ないことから小さなマイクロコントローラにも適している。
    - ※ 例えば、HTTPとヘッダサイズを比較すると、HTTPは`50Byte～`に対してMQTTは`2Byte～`となっています。
2. 拡張性
    - 数百万台のIoTデバイスと接続するための拡張性を備えている
3. 信頼性
    - 3つの異なるサービスのレベル(QoS)を指定できる。
        - `Qos0～2`があり、`Qos2`が一番高いレベルとなっており送信側と受信側の応答やメッセージの保存を用いて品質のレベルを担保する
4. セキュア
    - `TLSによるメッセージの暗号化`や`クライアント認証`を使用してセキュアな通信を実現できる
5. 充実したサポート
    - Pythonなどの多くのプログラミング言語でライブラリがある。

## 実装サンプル

サンプルとして、dockerで環境構築した以下の構成を利用します。

- ブローカー：Mosquitto(モスキート)
- サブスクライバーやパブリッシャー：Python

![サンプル](/images/mqtt_from_python/sample.drawio.png)

### paho-mqtt

`paho-mqtt`はPythonでMQTT通信を実装するためのライブラリで、強力なツールとなります。
MQTT通信のサブスクライバーやパブリッシャーの機能をサポートし、クライアント認証などのセキュア通信も実装可能です。

```txt
# 本記事では`2.1.0`を利用しています
pip install paho-mqtt
```

#### ディレクトリ構成と環境関連のファイル

ディレクトリ構成と環境関連のファイルは以下になります。

```txt: ディレクトリ構成
- .devcontainer
  - devcontainer.json
- mosquitto
  - config
    - mosquitto.conf
- requirements.txt
- Dockerfile
- docker-compose.yml
- app
  - mqtt.py
  - publisher.py
  - subscriber.py
```

:::details `環境関連のファイル`

```txt: requirements.txt
paho-mqtt==2.1.0
```

```json: .devcontainer/devcontainer.json
{
  "name": "workspace",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "workspace",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.flake8",
        "ms-python.mypy-type-checker",
        "ms-python.black-formatter"
      ]
    }
  }
}
```

```txt: mosquitto/config/mosquitto.conf
set_tcp_nodelay true
listener 1883
allow_anonymous true
max_queued_messages 0
```

```dockerfile: Dockerfile
FROM python:3.12

RUN apt-get update && \
    apt-get -y install --reinstall ca-certificates && \
    apt-get -y install software-properties-common && \
    pip install --upgrade pip

# Install Basic Packages
COPY ./requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir --ignore-installed -r /workspace/requirements.txt
```

```yml: docker-compose.yml
services:
  workspace:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      PYTHONPATH: /workspace
    volumes:
      - ./:/workspace/
    command: sleep infinity
    networks:
      - mqtt-local

  mqtt:
    image: eclipse-mosquitto
    expose:
      - 1883
    ports:
      - 1883:1883
    restart: unless-stopped
    volumes:
      - ./mosquitto/config:/mosquitto/config
    networks:
      - mqtt-local

networks:
  mqtt-local:
```

:::

#### サンプルコード

今回のサンプルコードは、シンプルなサブスクライブ/パブリッシュを実行します。
サブスクライバーは`test/+`をサブスクライブし、パブリッシャーは1秒ごとに`test/{i}`へメッセージをパブリッシュします。

```python: app/mqtt.py
import paho.mqtt.client as mqtt  # type: ignore # MQTTのライブラリをインポート

host = "mqtt"  # ブローカのホスト
port = 1883  # ブローカのポート


def on_connect(client, userdata, flags, reason_code, properties):
    """
    接続時のコールバック関数
    """
    if reason_code == 0:
        print("接続成功： " + str(reason_code))
    else:
        print("接続失敗： " + str(reason_code))


def on_message(client, userdata, msg):
    """
    サブスクライブ時のコールバック関数
    """
    print(msg.topic + ":" + str(msg.payload))


def connect_mqtt(host: str, port: int):
    """
    ブローカーへの接続
    """
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

    # コールバック関数を登録
    client.on_connect = on_connect
    client.on_message = on_message

    # ブローカーに接続
    client.connect(host, port, 60)
    return client
```

##### サブスクライバー

```python: app/subscriber.py
from mqtt import host, port, connect_mqtt

# サブスクライブするTopic
topic = 'test/+'  # ワイルドカードを使って複数のトピックをサブスクライブ


def run():
    client = connect_mqtt(host, port)
    client.subscribe(topic)
    client.loop_forever()


if __name__ == "__main__":
    run()
```

##### パブリッシャー

```python: app/publisher.py
from mqtt import host, port, connect_mqtt
from datetime import datetime
import time

# MQTTブローカーの設定
topic = "test/{}"


def publish(client, topic, message):
    result = client.publish(topic, message)

    # ステータスコードを確認
    status = result[0]
    if status == 0:
        print(f"`{topic}`に`{message}`を送信しました")
    else:
        print(f"`{topic}`への送信に失敗しました")


def run():
    client = connect_mqtt(host, port)
    # パブリッシュ(10回)
    for i in range(10):
        publish(
            client,
            topic.format(i),
            datetime.now().strftime("%Y/%m/%d %H:%M:%S").encode("utf-8"),
        )
        time.sleep(1)  # 1秒停止


if __name__ == "__main__":
    run()
```

##### 実行結果

devcontainer上で2つのターミナルを開き、`python app/subscriber.py`と`python app/publisher.py`を実行します。
サブスクライバー側でメッセージが受け取れていることが確認できます。

![実行結果](/images/mqtt_from_python/exec_sample.png)

## おわりに

今回はPythonを使ってMQTT通信する方法をまとめました。
IoTシステムなどで多数のデバイス間で短いメッセージを頻繁に送受信するようなシーンで利用できます。

## 参考

https://qiita.com/kbys-fumi/items/3ebb31a94fd3f9cc0b7a

https://www.kumikomi.jp/mqtt/

https://tech-blog.rakus.co.jp/entry/20180912/mqtt/iot/beginner
