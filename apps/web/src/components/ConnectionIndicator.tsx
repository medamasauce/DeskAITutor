import type { ConnectionStatus } from '../types'

const LABELS: Record<ConnectionStatus, string> = {
  waiting: 'スマホの接続を待機中',
  connecting: '接続中…',
  connected: '接続中',
  reconnecting: '再接続を試みています…',
  disconnected: '切断されました',
}

const DOT_CLASS: Record<ConnectionStatus, string> = {
  waiting: 'dot dot-waiting',
  connecting: 'dot dot-connecting',
  connected: 'dot dot-connected',
  reconnecting: 'dot dot-connecting',
  disconnected: 'dot dot-disconnected',
}

export function ConnectionIndicator({ status }: { status: ConnectionStatus }) {
  return (
    <div className="connection-indicator" role="status">
      <span className={DOT_CLASS[status]} />
      <span>{LABELS[status]}</span>
    </div>
  )
}
