---
title: "CSSのcounter-incrementを使った簡単な連番設定"
emoji: "🔢"
type: "tech"
topics: [css]
published: true
published_at: 2024-08-26 06:00
publication_name: "secondselection"
---

## はじめに

皆さんはCSSの`counter-increment`というプロパティをご存知でしょうか。恥ずかしながら私は知りませんでした。
このプロパティを使うことでHTML要素に連番を自動的に割り当てられます。

## 使い方の基本

まずはカウンター名を指定します。

- `counter-increment: カウンター名`
    - カウンター名とインクリメントする数値（デフォルトは1）を指定します
    - 指定したカウンターの値をインクリメントします
- `counter-reset: カウンター名`
    - 指定したカウンターの値をリセットします
- `counter(カウンター名)`
    - 指定したカウンターの値を利用します

@[codepen](https://codepen.io/rpgivwxc-the-looper/pen/rNEYPYa)

### ユースケース：FAQページでの活用

この機能は、FAQページで自動的に質問番号を付ける際に非常に便利です。例えば、各質問に対して自動的に番号を付与することで、ページの管理が容易になります。

```css
h2 {
  counter-reset: question-counter;
}

h2::before {
  counter-increment: question-counter;
  content: "Q" counter(question-counter) ". ";
}
```

## おわりに

`counter-increment`は、CSSのプロパティの1つでカウンターの値を操作するために使用されます。
この機能を使うことで、手動で番号を付ける必要がなくなります。

## 参考

https://developer.mozilla.org/ja/docs/Web/CSS/counter-increment

https://www.genius-web.co.jp/blog/web-programming/a-method-of-using-a-css-counter-increment-to-easily-get-a-sequential-number-automatically.html
