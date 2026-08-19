# Desk AI Tutor（手元AI学習アシスタント）

家庭内に眠っている使わなくなった古いスマートフォンを再利用し、学習机に固定して専用のAIアシスタント化するプロジェクトです。手元のノートをカメラで捉え、トリガー操作（Bluetoothリモコン or 画面タップ）を行うだけで、目の前のPC/タブレットの大画面に解法ステップや数式・図解を自動表示します。

詳細な要件定義・設計は [`docs/spec.md`](./docs/spec.md) を参照してください。

## 開発状況（ロードマップ）

- [x] Phase 1: PC側Webビューワー（`apps/web`）
- [x] Phase 2: モバイルアプリの基本機能（`apps/mobile`） ← 現在ここ
- [ ] Phase 3: Bluetoothリモコン対応・信頼性向上
- [ ] Phase 4: OSS公開・配布整備

## 構成

```
apps/
├── mobile/   # スマホアプリ (Flutter) - Phase 2以降
└── web/      # PC用大画面ビューワー (Vite + React + TypeScript)
docs/         # 設計仕様・TURN構築手順など
```

## PC用Webビューワー（apps/web）の使い方

### ローカルで動かす

```bash
cd apps/web
npm install
npm run dev
```

ブラウザで表示されたURLを開くと、Room IDのQRコードが表示されます。スマホアプリ（Phase 2以降で実装）がこのQRコードを読み取ることでペアリングします。

### スマホアプリなしで動作確認する（開発用シミュレータ）

モバイルアプリが未実装の段階でも、PC⇔スマホ間のP2P通信と段階的ヒント表示のUIを確認できるよう、開発用の送信シミュレータを同梱しています。

1. `npm run dev` でビューワーを開き、表示されたRoom IDをコピーする
2. 別のブラウザタブ（またはウィンドウ）で `http://localhost:5173/?send=<コピーしたRoom ID>` を開く
3. 「サンプルの解答ステップを送信」ボタンを押す
4. 最初のタブ（ビューワー側）にステップが表示され、「次のヒントを見る」ボタンで段階的に開示できることを確認する

> 補足: PeerJS Cloud（シグナリングサーバー）への外部接続が必要なため、外向き通信が制限されたネットワークでは動作しません。

### GitHub Pagesへのデプロイ

`main`ブランチへの `apps/web` 変更のpushで、`.github/workflows/deploy-web.yml` が自動的にビルド・GitHub Pagesへのデプロイを行います。

## スマホアプリ（apps/mobile）の使い方

```bash
cd apps/mobile
flutter pub get
flutter run
```

1. 初回起動時にGoogle AI StudioのAPIキーを入力（端末内にのみ保存）
2. PCビューワーに表示されたQRコードを読み取ってペアリング
3. 手元のノートを画面に収め、画面中央のボタンをタップして撮影・送信

詳細は[`apps/mobile/README.md`](./apps/mobile/README.md)を参照してください。

## データ利用に関する注意（重要）

本プロジェクトはユーザー自身が取得したGoogle AI Studio APIキー（無料枠）を利用するBYOK（Bring Your Own Key）モデルです。

- 手元ノートの画像やAIの回答は、開発者が管理するサーバーを一切経由しません（スマホ⇔PC間はP2P直接通信、必要時のみ無料TURN中継）。
- **ただし、無料枠のGemini APIに送信したデータはGoogle側のモデル改善に利用される可能性があります**（有料ティアと異なり、データ利用のオプトアウトは保証されません）。心配な場合は、Google AI Studioの利用規約・データ利用ポリシーをご自身でご確認のうえ、必要に応じて有料ティアの利用をご検討ください。
- TURN中継を利用する場合、通信内容自体はDTLSで暗号化され中継業者からは復号できませんが、IPアドレスや通信量などのメタデータは中継業者から見える構造になります。メタデータも外部に触れさせたくない場合は [`docs/turn.md`](./docs/turn.md) の自前TURN構築手順を参照してください。

## ライセンス

[MIT License](./LICENSE)
