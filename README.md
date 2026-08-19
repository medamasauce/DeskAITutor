# Desk AI Tutor（手元AI学習アシスタント）

家庭内に眠っている使わなくなった古いスマートフォンを再利用し、学習机に固定して専用のAIアシスタント化するプロジェクトです。手元のノートをカメラで捉え、トリガー操作（Bluetoothリモコン or 画面タップ）を行うだけで、目の前のPC/タブレットの大画面に解法ステップや数式・図解を自動表示します。

詳細な要件定義・設計は [`docs/spec.md`](./docs/spec.md) を参照してください。

## 開発状況（ロードマップ）

- [x] Phase 1: PC側Webビューワー（`apps/web`）
- [x] Phase 2: モバイルアプリの基本機能（`apps/mobile`）
- [x] Phase 3: Bluetoothリモコン対応・信頼性向上
- [x] Phase 4: OSS公開・配布整備 ← 現在ここ

## 構成

```
apps/
├── mobile/   # スマホアプリ (Flutter, Android)
└── web/      # PC用大画面ビューワー (Vite + React + TypeScript)
docs/         # 設計仕様・TURN構築手順など
.github/workflows/
├── deploy-web.yml      # apps/web を GitHub Pages へ自動デプロイ
└── release-android.yml # apps/mobile のAPKを自動ビルド（vタグでReleases添付）
```

## 必要なもの

- 使わなくなったAndroidスマートフォン（カメラ・Wi-Fi/モバイル通信が使えるもの）
- 学習机の前のPC・タブレット（Webブラウザが動けばOK）
- [Google AI Studio](https://aistudio.google.com/) の無料APIキー
- （任意）「Android動作確認済み」と明記されたBluetoothシャッターリモコン

## 導入手順

### 1. Gemini APIキーを取得する

[Google AI Studio](https://aistudio.google.com/apikey) にアクセスし、無料枠のAPIキーを発行してください。

### 2. PC側ビューワーを開く

GitHub Pagesへデプロイ済みのURL（このリポジトリの Settings → Pages で確認、またはワークフロー実行結果に表示されるURL）を学習机の前のPC・タブレットのブラウザで開きます。ローカルで動かしたい場合は以下の通りです。

```bash
cd apps/web
npm install
npm run dev
```

QRコードとRoom IDが表示されます。

### 3. スマホアプリをインストールする

配布済みのAPK（GitHub Releasesからダウンロード。下記「配布」参照）をスマホにインストールするか、自分でビルドします。

```bash
cd apps/mobile
flutter pub get
flutter run   # 実機/エミュレータを接続した状態で
```

初回起動時に以下を行います。

1. カメラ権限・通知権限を許可
2. バッテリー最適化の除外を確認（ダイアログが出たら許可）
3. Gemini APIキーを入力
4. PC画面のQRコードをスキャンしてペアリング

### 4. 使ってみる

1. スマホを学習机に固定し、手元のノートが画面に映るようにする
2. 画面中央のボタンをタップ、またはBluetoothリモコンのボタンを押す
3. PC画面に解法ステップが段階的に表示される（「次のヒントを見る」で1つずつ開示）

## 配布（GitHub Releasesからのインストール）

`v*` 形式のタグ（例: `v0.1.0`）をpushすると、`.github/workflows/release-android.yml` が自動的にリリースAPKをビルドし、GitHub Releasesに添付します。スマホの「提供元不明のアプリ」インストールを許可した上で、Releasesページからダウンロードしてインストールしてください。

## トラブルシューティング

| 症状 | 確認・対処 |
|---|---|
| QRコードを読み取ってもペアリングできない | PC・スマホ双方がインターネットに接続されているか確認（PeerJS Cloudへの外部WebSocket接続が必要）。企業/学校のネットワークやファイアウォールが原因で接続できない場合は、時間を置くか別ネットワークで試す |
| Wi-Fiルーターの設定で接続が確立しない | 一部のルーターは「APアイソレーション」が有効でSTUNのみでは接続できません。自動でOpen Relay Project（無料TURN）にフォールバックしますが、それでも失敗する場合は[`docs/turn.md`](./docs/turn.md)の自前TURN構築を検討してください |
| Bluetoothリモコンのボタンを押しても反応しない | 製品が「Android動作確認済み」か確認（iOS専用設計の製品は反応しません）。スマホの設定でBluetoothリモコンが正しくペアリングされているか確認してください |
| 画面OFF・バックグラウンドでリモコンが効かない | フォアグラウンドサービスの常駐通知が出ているか確認。端末メーカー独自の電力最適化（自動起動制限、アプリのスリープ等）がある機種では、端末設定側で本アプリを対象外に設定してください（機種ごとの設定手順はメーカーのサポートページを参照） |
| 「今日はAPIの利用上限に達しました」と表示される | Gemini APIの無料枠のレート制限に達しています。時間を置くか、Google AI Studioで利用状況を確認してください |
| GitHub Pagesが404になる | リポジトリの Settings → Pages で Source が「GitHub Actions」になっているか確認してください。`deploy-web.yml` の初回実行でPagesが自動的に有効化されます |
| APKのビルドに失敗する | `flutter doctor` でAndroidツールチェーンが揃っているか確認してください。CI (`release-android.yml`) のログも参考になります |

## デモ

実機での動作の様子（撮影→送信→PC画面への表示）を撮影したデモGIF/動画は今後追加予定です。お手元で試された際のスクリーンショットや動画を歓迎します。

## データ利用に関する注意（重要）

本プロジェクトはユーザー自身が取得したGoogle AI Studio APIキー（無料枠）を利用するBYOK（Bring Your Own Key）モデルです。

- 手元ノートの画像やAIの回答は、開発者が管理するサーバーを一切経由しません（スマホ⇔PC間はP2P直接通信、必要時のみ無料TURN中継）。
- **ただし、無料枠のGemini APIに送信したデータはGoogle側のモデル改善に利用される可能性があります**（有料ティアと異なり、データ利用のオプトアウトは保証されません）。心配な場合は、Google AI Studioの利用規約・データ利用ポリシーをご自身でご確認のうえ、必要に応じて有料ティアの利用をご検討ください。
- TURN中継を利用する場合、通信内容自体はDTLSで暗号化され中継業者からは復号できませんが、IPアドレスや通信量などのメタデータは中継業者から見える構造になります。メタデータも外部に触れさせたくない場合は [`docs/turn.md`](./docs/turn.md) の自前TURN構築手順を参照してください。

## サブプロジェクトのドキュメント

- [`apps/web/README.md`](./apps/web/README.md) - PC用Webビューワーの実装詳細
- [`apps/mobile/README.md`](./apps/mobile/README.md) - スマホアプリの実装詳細
- [`docs/spec.md`](./docs/spec.md) - 要件定義・設計仕様書
- [`docs/turn.md`](./docs/turn.md) - 自前TURN構築手順

## ライセンス

[MIT License](./LICENSE)
