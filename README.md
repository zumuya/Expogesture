# Expogesture

NAKAHASHI Ichiro さんによって開発された Mac OS X 用ユーティリティ“Expogesture”を macOS Big Sur と Apple Silicon に対応させた派生バージョンです。

[公式サイト](http://ichiro.nnip.org/osx/Expogesture/)の説明より：

> Expogestrue は、マウスでのジェスチャーに反応し、設定されたアクションを実行するアプリケーションです。
>
> 例1: マウスで右回りに小さな円を描くと、アプリケーションが隠れる(Cmd+H)
> 例2: 左回りに小さな円を描くと、Expose (F9)

## 使用について

- 現在バイナリを配布していないため、Xcode を入手してソースコードをコンパイルする必要があります。
- 使用のためには「システム環境設定 > プライバシー > アクセシビリティ」で許可する必要があります。

## メンテナンス方針

- 基本的には公開者が自分自身で使用するために作業したものを配布しているだけであり、要望やバグ報告に応えるモチベーションは存在しません。
- 公開者の必要としない機能や最新 API への置き換えの手間が大きい機能は削除します。
- メンテナンス手間を増やさないように UI は英語のみの表示を前提とします。
- 公開者は Mission Control や Launchpad の起動をするだけに使用しており、数年に一度も開かない環境設定ウインドウは最低限しか動作確認をしません。
- 公開者の好みに合わせてデフォルト設定を変更します。
- 公開者が使用しているアーキテクチャと OS バージョンでしか動作確認をしていません。Deployment Target は“10.14”に指定されていますが本当に起動するのかいっさい検証していません。
- メンテナンス上の都合により前のバージョンの設定を引き継がなくすることがあります。

## オリジナルからの変更点

### コードの改善

- 古い API を macOS Big Sur でも動くように置き換えました。
- 古い .nib ファイルを .xib ファイルに変換しました。
- コードを ARC（Automatic Reference Counting）に対応させました。
- 通知オーバレイを .xib ファイルから削除してコードで生成するように変更しました。
- 設定ファイルのフォーマットに影響する変更を加えているためバンドル識別子を変更しました。

### 減った機能

- 英語以外を表示するためのリソースをいくつか削除しました。
- タスクスイッチャ機能を削除しました。
- HID デバイス関係の API を使用してマウスの移動を捉えるモード（デフォルト）とタイマーで定期的にカーソル位置を取得するモード（オプション）が存在しましたが、前者を削除して後者のみに対応しています。

### その他

- デフォルトの動作を Mission Control や Launchpad の起動に変更しました。
- Mission Control や Launchpad のキーで通知オーバレイが表示されるとき、Big Sur 上では SF Symbols を使ってキーボード上の刻印に近いものを表示するようにしました。

## 既知の問題

- デフォルト設定で Mission Control や Launchpad のキーが登録されていますが、それらを環境設定ウインドウ上で押しても登録できません。`~/Library/Preferences` にある .plist の設定ファイルを編集して直接キーコード（160 または 130）を指定する必要があるようです。設定ファイル変更後は cprefsd が終了するまで反映されない可能性があります。

## ライセンス

オリジナルと同様、GPL V2 です。
