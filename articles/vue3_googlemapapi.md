---
title: "Google Maps APIとVue3を組み合わせた地図アプリケーションの作り方"
emoji: "🗾"
type: "tech"
topics: [vue3, googlemap, googlemapsapi]
published: true
published_at: 2024-05-20 06:00
publication_name: "secondselection"
---

## はじめに

今回はプロジェクトで[Google Maps API](https://developers.google.com/maps?hl=ja)をVue3で利用したときの備忘録として記事にしてみました。
プロジェクトでは以下の機能を使ってデバイスの経路や計測ポイントの密度を表示しました。

- [ポリライン](#ポリラインpolyline)
  - [公式ドキュメント](https://developers.google.com/maps/documentation/javascript/shapes?hl=ja)
  - 経路などの連続した線を描画したいときに使います。
- [ヒートマップ](#ヒートマップheatmaplayer)
  - [公式ドキュメント](https://developers.google.com/maps/documentation/javascript/heatmaplayer?hl=ja)
  - 人口の多さなどデータが集中している場所などを表現したいときに使います。

## Google Maps API

Google Mapsの機能を組み込むことが可能なツールです。
地図の表示はもちろん、経路やヒートマップなどの描画が可能です。
利用にはGoogle Cloud Platformでプロジェクトを作成し、APIキーを取得する必要があります。利用には通常、使用量に応じた料金が発生します。

https://developers.google.com/maps/documentation/javascript/get-api-key?hl=ja

## Google Maps API + Vue3

今回は以下のライブラリを使って`Google Maps API + Vue3`を使っていきます。

https://www.npmjs.com/package/vue3-google-map

```bash:追加方法
npm install vue3-google-map
# OR
yarn add vue3-google-map
```

### 地図表示

`GoogleMap`コンポーネントを使うことで簡単に地図を表示できます。
※ 地図を表示するだけであれば、無料なので[埋め込み](https://ay-net.jp/homepage/201/)がオススメです。

![maponly](/images/vue3_googlemapapi/maponly.drawio.png)

```js
<script setup lang="ts">
import { Ref, ref, watch } from 'vue';
import { GoogleMap } from 'vue3-google-map';

type gmap = {
  mapRef: Ref<HTMLElement | undefined>;
  ready: Ref<boolean>;
  map: Ref<google.maps.Map | undefined>;
  api: Ref<typeof google.maps | undefined>;
  mapTilesLoaded: Ref<boolean>;
};

const { VITE_GMAP_API_KRY } = import.meta.env;
const mapRef: Ref<gmap | null> = ref(null);

const center = { lat: 34.7055864522747, lng: 135.4989457104213 };

watch(() => mapRef.value?.ready, (ready) => {
  if (!ready) {
    return;
  }
});
</script>

<template>
  <GoogleMap 
    ref="mapRef"
    :api-key="VITE_GMAP_API_KRY"
    style="width: 100%; height: 600px"
    :center="center"
    :zoom="15"
  />
</template>
```

#### 地図表示_プロパティ

`GoogleMap`コンポーネントで指定できるプロパティは[公式](https://developers.google.com/maps/documentation/javascript/reference/map?hl=ja#MapOptions)と同じ内容が設定できます。
主なプロパティをここでは紹介します。

| プロパティ | 設定内容 |
| --------- | ------- |
| `api-key` | Google Cloud Platformで取得したAPIキーを指定 |
| `center` | 表示した地図の初期位置 |
| `center.lat` | 表示した地図の初期位置（緯度） |
| `center.lng` | 表示した地図の初期位置（経度） |
| `zoom` | 初期ズームレベル |

### ポリライン(Polyline)

経路などの連続した線を表示したい場合は`Polyline`コンポーネントを利用します。
例えば、デバイスが○月△日に移動した経路を表示したいときなどです。

![polyline](/images/vue3_googlemapapi/polyline.drawio.png)

```js
<script setup lang="ts">
import { Ref, ref, watch } from 'vue';
import { GoogleMap, Polyline } from 'vue3-google-map';

type gmap = {
  mapRef: Ref<HTMLElement | undefined>;
  ready: Ref<boolean>;
  map: Ref<google.maps.Map | undefined>;
  api: Ref<typeof google.maps | undefined>;
  mapTilesLoaded: Ref<boolean>;
};

const { VITE_GMAP_API_KRY } = import.meta.env;
const mapRef: Ref<gmap | null> = ref(null);
const lineOption: Ref<google.maps.PolylineOptions | null> = ref(null);

const center = { lat: 34.7055864522747, lng: 135.4989457104213 };

const path = [
  { lat: 34.70246409457652, lng: 135.49540519451972 },
  { lat: 34.70350489355238, lng: 135.49737930026106 },
  { lat: 34.70523364935635, lng: 135.49707889286566 },
  { lat: 34.7055864522747, lng: 135.4989457104213 },
  { lat: 34.70821478628786, lng: 135.49772262307397 },
  { lat: 34.71123109354799, lng: 135.4980444881405 },
  { lat: 34.711162263421876, lng: 135.49694223970306 }
];

watch(() => mapRef.value?.ready, (ready) => {
  if (!ready) {
    return;
  }

  lineOption.value = {
    path: path,
    geodesic: true,
    strokeColor: '#FF0000',
    strokeOpacity: 1,
    strokeWeight: 2,
    icons: [
      {
        icon: {
          fillColor: "#FFFFFF",
          fillOpacity: 1,
          path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
          scale: 4,
        },
        repeat: '10%'
      }
    ]
  }
});
</script>

<template>
  <GoogleMap 
    ref="mapRef"
    :api-key="VITE_GMAP_API_KRY"
    style="width: 100%; height: 600px"
    :center="center"
    :zoom="15"
  >
    <Polyline v-if="lineOption" :options="lineOption" />
  </GoogleMap>
</template>
```

#### ポリライン(Polyline)_プロパティ

`Polyline`コンポーネントで指定できるプロパティも[公式](https://developers.google.com/maps/documentation/javascript/reference/polygon?hl=ja#PolylineOptions)と同じ内容が設定できます。
主なプロパティをここでは紹介します。

| プロパティ | 設定内容 |
| --------- | ------- |
| `path` | ストローク（線）の座標 |
| `strokeColor` | ストローク（線）の色 |
| `strokeOpacity` | ストローク（線）の透明度`0.0～1.0` |
| `strokeWeight` | ストローク（線）の太さ（幅） |
| `icons` | ストローク（線）に沿って表示されるアイコン |
| `icons[i].repeat` | 連続表示するアイコンの間隔。`50% や 12px`で設定できる |
| `icons[i].icon.path` | アイコンの形状 |
| `icons[i].icon.scale` | アイコンのサイズ |

### ヒートマップ(HeatmapLayer)

ヒートマップを表示したい場合は`HeatmapLayer`コンポーネントを利用します。
例えば、人口の多い箇所を赤く表示したいときなどです。

![HeatmapLayer](/images/vue3_googlemapapi/heatmaplayer.drawio.png)

```js
<script setup lang="ts">
import { Ref, ref } from 'vue';
import { GoogleMap, HeatmapLayer } from 'vue3-google-map';

type gmap = {
  mapRef: Ref<HTMLElement | undefined>;
  ready: Ref<boolean>;
  map: Ref<google.maps.Map | undefined>;
  api: Ref<typeof google.maps | undefined>;
  mapTilesLoaded: Ref<boolean>;
};

const { VITE_GMAP_API_KRY } = import.meta.env;
const mapRef: Ref<gmap | null> = ref(null);

const center = { lat: 34.7055864522747, lng: 135.4989457104213 };

// 各データポイントの影響の半径（ピクセル単位）
const radius = 30;

// 座標配列
const heatmapData = [
  { location: { lat: 34.7055864522747, lng: 135.4989457104213 } },
  // ...
  { location: { lat: 34.7055864522747, lng: 135.4989457104213 } }
];

</script>

<template>
  <GoogleMap 
    ref="mapRef"
    :api-key="VITE_GMAP_API_KRY"
    :libraries="['visualization']"
    style="width: 100%; height: 600px"
    :center="center"
    :zoom="15"
  >
    <HeatmapLayer :options="{ data: heatmapData, radius: radius }" />
  </GoogleMap>
</template>
```

#### ヒートマップ(HeatmapLayer)_プロパティ

`HeatmapLayer`コンポーネントで指定できるプロパティも[公式](https://developers.google.com/maps/documentation/javascript/reference/visualization?hl=ja#HeatmapLayerOptions)と同じ内容が設定できます。
主なプロパティをここでは紹介します。

| プロパティ | 設定内容 |
| --------- | ------- |
| `radius` | データポイントの影響の半径（ピクセル単位） |
| `data` | データポイント |
| `data[i].location.lat` | データポイント(緯度) |
| `data[i].location.lng` | データポイント(経度) |
| `data[i].weight` | 【任意】重み付け |

### ハマりどころ

#### google.mapsをsetupのスクリプト中で使うとエラーが出る

setup関数の中で`google.maps`を参照するとエラー`ReferenceError: google is not defined`が発生しました。
このエラーは、setup関数が実行されているタイミングではまだインポートされていないため発生します。

回避方法としては以下になります。

1. `GoogleMap`のコンポーネントをwatchする（vueのwatch関数を使う）
2. ロード済み`ready=true`にステータスが変わる
3. `google.maps`を参照する

```js:NG時（スクリプト部のみ抜粋）
import { GoogleMap, Polyline } from 'vue3-google-map';

const lineOption: Ref<google.maps.PolylineOptions | null> = ref(null);

// 表示元データ（線）
const path = [
  // 省略
];

lineOption.value = {
  path: path,
  geodesic: true,
  strokeColor: '#FF0000',
  strokeOpacity: 1,
  strokeWeight: 2,
  icons: [
    {
      icon: {
        fillColor: "#FFFFFF",
        fillOpacity: 1,
        path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, // ここでエラー
        scale: 4
      },
      repeat: '10%'
    }
  ]
}
```

```js:OK時（スクリプト部のみ抜粋）
import { Ref, ref, watch, } from 'vue';
import { GoogleMap, Polyline } from 'vue3-google-map';

type gmap = {
  mapRef: Ref<HTMLElement | undefined>;
  ready: Ref<boolean>;
  map: Ref<google.maps.Map | undefined>;
  api: Ref<typeof google.maps | undefined>;
  mapTilesLoaded: Ref<boolean>;
};

const { VITE_GMAP_API_KRY } = import.meta.env;
const mapRef: Ref<gmap | null> = ref(null);
const lineOption: Ref<google.maps.PolylineOptions | null> = ref(null);

// 表示元データ（線）
const path = [
  // 省略
];

watch(() => mapRef.value?.ready, (ready) => {
  if (!ready) {
    return;
  }

  lineOption.value = {
    path: path,
    geodesic: true,
    strokeColor: '#FF0000',
    strokeOpacity: 1,
    strokeWeight: 2,
    icons: [
      {
        icon: {
          fillColor: "#FFFFFF",
          fillOpacity: 1,
          path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
          scale: 4,
        },
        repeat: '10%'
      }
    ]
  }
});
```

```html:OK時（テンプレート部のみ抜粋）
<GoogleMap 
  ref="mapRef"
  :api-key="VITE_GMAP_API_KRY"
  :libraries="['visualization']"
  style="width: 100%; height: 600px"
  :center="center"
  :zoom="15"
>
  <Polyline v-if="lineOption" :options="lineOption" />
</GoogleMap>
```

## おわりに

今回は`Google Maps API + Vue3`の構成でポリラインとヒートマップの2種類のレイアウトを紹介しました。
無料枠があるといっても有償であるため、利用回数の制限など考慮して使いましょう。
