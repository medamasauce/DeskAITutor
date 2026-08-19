import { useEffect, useState } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkMath from 'remark-math'
import rehypeKatex from 'rehype-katex'
import type { HintStep } from '../types'

// Gemini 側で全ステップが生成済みでも、フロントエンド側で物理的に
// 開示数をガードする（モデルの指示追従性に依存しない）。
export function HintViewer({ steps }: { steps: HintStep[] }) {
  const [revealedCount, setRevealedCount] = useState(1)

  useEffect(() => {
    setRevealedCount(1)
  }, [steps])

  const sorted = [...steps].sort((a, b) => a.order - b.order)
  const visible = sorted.slice(0, revealedCount)
  const hasMore = revealedCount < sorted.length

  return (
    <div className="hint-viewer">
      {visible.map((step) => (
        <div className="hint-step" key={step.order}>
          <div className="hint-step-label">ステップ {step.order}</div>
          <ReactMarkdown remarkPlugins={[remarkMath]} rehypePlugins={[rehypeKatex]}>
            {step.latex ? `${step.content}\n\n$$${step.latex}$$` : step.content}
          </ReactMarkdown>
        </div>
      ))}
      {hasMore && (
        <button className="next-hint-button" onClick={() => setRevealedCount((c) => c + 1)}>
          次のヒントを見る（{revealedCount}/{sorted.length}）
        </button>
      )}
    </div>
  )
}
