---
title: "PythonでModbus通信を学ぼう：外部機器データ取得ガイド"
emoji: "🔗"
type: "tech"
topics: [python, modbus, pymodbus, 初心者向け]
published: true
published_at: 2024-06-03 09:00
publication_name: "secondselection"
---

## はじめに

PythonからMoudbus通信を使ってPLC（Programmable Logic Controller）などの産業用機器からデータを取得した際の備忘録です。

## Modbusとは

Modbusは主に産業用のデバイス間でデータを交換するために使用されます。
Modbusはオープンなプロトコルであり、多くの産業用機器やシステムで広く採用されています。以下にModbusの概要を示します。

### 基本構造

Modbusはマスタ／スレーブアーキテクチャに基づいており、マスタは通信を開始してスレーブはマスタの要求に応答します。

### 通信モード

Modbusにはいくつかの通信モードがあり、主に以下の2つが一般的です。

1. **Modbus TCP/IP**
    - イーサネットネットワークを介して通信します。
    - TCP/IPプロトコルスタックを使用し、より高いデータ転送速度を実現します。
2. **Modbus RTU (Remote Terminal Unit)**
    - シリアル通信（RS-232やRS-485）を使用します。
    - バイナリフォーマットを使用し、データの送受信が効率的です。
    - データパケットには、アドレスフィールド、機能コード、データ、エラーチェックフィールド（CRC）が含まれます。

### データモデル

Modbusは4つの異なるデータモデルを持ちます。それぞれ異なるアドレス空間を持ち、特定のデータ型に対応しています。

1. **コイル (Coils)**
    - デジタル出力、読み書き可能
    - 各コイルは1ビットのデータを保持します。
    - 主な使用例：`制御命令、設定(ON/OFF)`
2. **ディスクリート入力 (Discrete Inputs)**
    - デジタル入力、読み取り専用
    - 各入力は1ビットのデータを保持します。
    - 主な使用例：`センサー読み取り値(ON/OFF)`
3. **保持レジスタ (Holding Registers)**
    - アナログ出力、読み書き可能
    - 各レジスタは16ビットのデータを保持します。
    - 主な使用例：`制御命令、設定値`
4. **入力レジスタ (Input Registers)**
    - アナログ入力、読み取り専用
    - 各レジスタは16ビットのデータを保持します。
    - 主な使用例：`センサー読み取り値`

### 機能コード

Modbusには特定の操作を指定するための機能コードがあります。主な機能コードには以下のものがあります。
※ 機器によってはすべての機能コードがあるとは限りません。

- **01**: コイルの読み取り
- **02**: ディスクリート入力の読み取り
- **03**: 保持レジスタの読み取り
- **04**: 入力レジスタの読み取り
- **05**: 単一コイルの書き込み
- **06**: 単一保持レジスタの書き込み
- **15**: 複数コイルの書き込み
- **16**: 複数保持レジスタの書き込み

## PyModbus

PyModbusは、PythonでModbusプロトコルを実装するためのライブラリです。
そのため、産業用自動化システムやデータ収集システムの構築において、PythonプログラムからModbusデバイスと通信するための強力なツールとなります。
Modbus通信のクライアント（マスタ）およびサーバ（スレーブ）機能をサポートし、`Modbus RTU`と`Modbus TCP/IP`を含む多くの通信モードを実装できます。

PyModbusのインストールは、通常以下のようにpipを使用して行います。

```bash
# 本記事では`3.6.8`を利用しています
pip install pymodbus[all]
```

### PyModbus(Modbus TCP/IP)

サンプルとしては`TCP/IP`の通信モードのサンプルを記載します。
イメージは以下のような構成になります。

![tcp_sample.drawio.png](/images/modbus_from_python/tcp_sample.drawio.png)

#### PyModbus(Modbus TCP/IP)_サーバ（スレーブ）

```python: server.py
import asyncio
from pymodbus.server import StartAsyncTcpServer
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import (
    ModbusSequentialDataBlock,
    ModbusSlaveContext,
    ModbusServerContext
)

store = ModbusSlaveContext(
    di=ModbusSequentialDataBlock(0, [17]*100),
    co=ModbusSequentialDataBlock(0, [17]*100),
    hr=ModbusSequentialDataBlock(0, [15]*100),
    ir=ModbusSequentialDataBlock(0, [17]*100)
)
context = ModbusServerContext(slaves=store, single=True)

identity = ModbusDeviceIdentification()
identity.VendorName = 'pymodbus'
identity.ProductCode = 'PM'
identity.VendorUrl = 'http://github.com/bashwork/pymodbus/'
identity.ProductName = 'pymodbus Server'
identity.ModelName = 'pymodbus Server'
identity.MajorMinorRevision = '1.0'

async def start():
    await StartAsyncTcpServer(context, identity=identity, address=("localhost", 5020))

if __name__ == "__main__":
    asyncio.run(start())
```

#### PyModbus(Modbus TCP/IP)_クライアント（マスタ）

```python: client.py
from pymodbus.client import ModbusTcpClient
from pymodbus.exceptions import ModbusException
from pymodbus.pdu import ExceptionResponse

client = ModbusTcpClient('localhost', 5020)

try:
    client.connect()

    # Coils部のデータ読み取り
    print('----------- Coils(読取) -----------')
    result = client.read_coils(1, 10)
    print(result.bits)
    # 期待結果: [True, True, True, True, True, True, True, True, True, True, False, False, False, False, False, False]

    # Coils部にデータ書き込み
    print('----------- Coils(書込) -----------')
    result = client.write_coil(1, False)
    result = client.read_coils(1, 10)
    print(result.bits)
    # 期待結果: [False, True, True, True, True, True, True, True, True, True, False, False, False, False, False, False]

    # Discrete Inputs部のデータ読み取り
    print('----------- Discrete Inputs(読取) -----------')
    result = client.read_discrete_inputs(1, 10)
    print(result.bits)
    # 期待結果: [True, True, True, True, True, True, True, True, True, True, False, False, False, False, False, False]

    # Holding Registers部のデータ読み取り
    print('----------- Holding Registers(読取) -----------')
    result = client.read_holding_registers(1, 10)
    print(result.registers)
    # 期待結果: [15, 15, 15, 15, 15, 15, 15, 15, 15, 15]

    # Holding Registers部にデータ書き込み
    print('----------- Holding Registers(書込) -----------')
    values = [10, 20, 30, 40, 50]
    result = client.write_registers(1, values)
    result = client.read_holding_registers(1, 10)
    print(result.registers)
    # 期待結果: [10, 20, 30, 40, 50, 15, 15, 15, 15, 15]

    # Input Registers部のデータ読み取り
    print('----------- Input Register(読取) -----------')
    result = client.read_input_registers(1, 10)
    print(result.registers)
    # 期待結果: [17, 17, 17, 17, 17, 17, 17, 17, 17, 17]

    # 異常パターンの記載方法サンプル
    print('----------- 異常パターンの記載方法サンプル -----------')
    result = client.write_registers(1, values)
    if not result.isError():
        print("Write successful")
    elif isinstance(result, ExceptionResponse):
        print(result.original_code)
        print(result.function_code)
        print(result.exception_code)
        raise Exception('エラーレスポンスが返ってきました')

except ModbusException as ex:
    print(ex)
except Exception as ex:
    print(ex)
finally:
    if client.connected:
        client.close()
```

## おわりに

今回はPythonを使ってModbus通信する方法をまとめました。
産業用機器からデータを収集するようなIoTシステムの構築に利用できます。
