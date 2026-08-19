# Desk AI Tutor - Mobile (卓上固定スマホ側)

Flutterアプリ。QRコードでPCとペアリングし、画面タップで手元ノートを撮影、Gemini APIに送って構造化された解法ステップをPCへリアルタイム送信します。詳細は[リポジトリルートのREADME](../../README.md)を参照してください。

## 現在の実装状況（Phase 2: 基本機能）

- [x] QRコードスキャンによるペアリング (`views/qr_scan_view.dart`)
- [x] WebRTC DataChannel (PeerJS互換シグナリング) でPCへ接続 (`services/pairing_service.dart`, `services/peerjs_signaling.dart`)
- [x] 画面タップボタンによる撮影トリガー (`views/home_view.dart`)
- [x] Gemini APIへの送信・構造化出力(`steps`配列)の取得 (`services/gemini_service.dart`)
- [x] APIエラー(429/5xx等)のフィードバック
- [x] APIキーの端末内保存 (`services/api_key_store.dart`)
- [x] Bluetoothリモコン(MediaSession)対応 — Phase 3
- [x] フォアグラウンドサービス化・バッテリー最適化除外 — Phase 3
- [x] 切断時の自動再接続（バックオフ）・復旧不能時のQR再スキャン導線 — Phase 3

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

## Bluetoothリモコン・フォアグラウンドサービスについて

- `android/app/src/main/kotlin/.../TriggerForegroundService.kt` が画面OFF時でもBluetoothリモコンのメディアボタン(`MediaSessionCompat`)を受信し続けるフォアグラウンドサービスです。`PARTIAL_WAKE_LOCK`でCPUのみを起こし、画面は点灯しません。
- 「Android動作確認済み」を明記したBluetoothシャッターリモコン（AVRCP/メディアボタンとして動作するもの）の使用を推奨します。一部の安価な製品はiOS専用設計のため反応しない場合があります。
- 初回起動時、バッテリー最適化の除外をシステムダイアログで依頼します（メーカー独自の電力最適化がある機種では、別途端末設定側での許可が必要な場合があります）。
- Bluetoothリモコンと画面タップボタンは同時に有効で、どちらを使っても同じ撮影・送信ロジックが呼ばれます。

## PeerJS互換シグナリングについて

`apps/web` はブラウザ用の `peerjs` npmパッケージ（PeerJS Cloud既定サーバー）を使ってRoom IDを待ち受けています。Flutter側は同じPeerJS Cloudのシグナリング用WebSocketプロトコルを`services/peerjs_signaling.dart`で直接喋ることで、追加のネイティブSDKなしに相互接続します。DataChannelのシリアライズ形式は`serialization: 'json'`を明示しているため、PC側は受信データをそのままJSONとしてパースします。
