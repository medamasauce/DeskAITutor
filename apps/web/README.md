# Desk AI Tutor - Web Viewer (PC/大画面側)

PeerJS (WebRTC) を使い、スマホから送られてくる解法ステップを大画面に表示するビューワーです。詳細は[リポジトリルートのREADME](../../README.md)を参照してください。

## セットアップ

```bash
npm install
npm run dev
```

## 主要な構成

- `src/hooks/useReceiverPeer.ts` - Room ID発行、スマホからのDataChannel接続待ち受け、切断時の再接続導線
- `src/hooks/useSenderPeer.ts` - 開発用送信シミュレータが使うPeer接続ロジック（本番のスマホアプリと同一プロトコル）
- `src/components/HintViewer.tsx` - 段階的ヒント表示（Markdown + KaTeX）
- `src/iceConfig.ts` - STUN / TURN (Open Relay Project) 設定。自前TURNへの切替は[`docs/turn.md`](../../docs/turn.md)参照
