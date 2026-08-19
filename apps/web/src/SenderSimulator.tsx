import { useState } from 'react'
import { useSenderPeer } from './hooks/useSenderPeer'
import type { HintStep } from './types'

const SAMPLE_STEPS: HintStep[] = [
  { order: 1, content: 'まず、両辺から **3** を引いて式を整理します。', latex: '2x + 3 = 11 \\implies 2x = 8' },
  { order: 2, content: '次に、両辺を **2** で割ります。', latex: 'x = \\dfrac{8}{2}' },
  { order: 3, content: 'よって答えは次の通りです。', latex: 'x = 4' },
]

// 開発用シミュレータページ（ URL: /?send=<roomId> ）。
// スマホアプリが未実装の段階でも、PC側の受信〜段階的ヒント表示までを
// 実機なしで確認できるようにするための開発者向けツール。
export function SenderSimulator({ roomId }: { roomId: string }) {
  const { status, send } = useSenderPeer(roomId)
  const [sent, setSent] = useState(false)

  return (
    <div className="sender-simulator">
      <h1>送信シミュレータ（開発用）</h1>
      <p>接続先 Room ID: <code>{roomId}</code></p>
      <p>接続状態: <strong>{status}</strong></p>
      <button
        disabled={status !== 'connected'}
        onClick={() => {
          send({ type: 'steps', steps: SAMPLE_STEPS })
          setSent(true)
        }}
      >
        サンプルの解答ステップを送信
      </button>
      <button
        disabled={status !== 'connected'}
        onClick={() => send({ type: 'error', code: 'RATE_LIMIT', message: '今日はAPIの利用上限に達しました' })}
      >
        エラー通知を送信（テスト）
      </button>
      {sent && <p>送信しました。PC画面（QRコードを表示していたタブ）を確認してください。</p>}
    </div>
  )
}
