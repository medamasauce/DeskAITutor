# Desk AI Tutor - Mobile (卓上固定スマホ側)

Flutterアプリ。QRコードでPCとペアリングし、画面タップで手元ノートを撮影、Gemini APIに送って構造化された解法ステップをPCへリアルタイム送信します。詳細は[リポジトリルートのREADME](../../README.md)を参照してください。

## 現在の実装状況（Phase 2: 基本機能）

- [x] QRコードスキャンによるペアリング (`views/qr_scan_view.dart`)
- [x] WebRTC DataChannel (PeerJS互換シグナリング) でPCへ接続 (`services/pairing_service.dart`, `services/peerjs_signaling.dart`)
- [x] 画面タップボタンによる撮影トリガー (`views/home_view.dart`)
- [x] Gemini APIへの送信・構造化出力(`steps`配列)の取得 (`services/gemini_service.dart`)
- [x] APIエラー(429/5xx等)のフィードバック
- [x] APIキーの端末内保存 (`services/api_key_store.dart`)
- [ ] Bluetoothリモコン(MediaSession)対応 — Phase 3
- [ ] フォアグラウンドサービス化・バッテリー最適化除外 — Phase 3

## セットアップ

```bash
flutter pub get
flutter analyze
flutter test
```

実機/エミュレータで動かす場合:

```bash
flutter run
```

## PeerJS互換シグナリングについて

`apps/web` はブラウザ用の `peerjs` npmパッケージ（PeerJS Cloud既定サーバー）を使ってRoom IDを待ち受けています。Flutter側は同じPeerJS Cloudのシグナリング用WebSocketプロトコルを`services/peerjs_signaling.dart`で直接喋ることで、追加のネイティブSDKなしに相互接続します。DataChannelのシリアライズ形式は`serialization: 'json'`を明示しているため、PC側は受信データをそのままJSONとしてパースします。
