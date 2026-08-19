import { useCallback, useState } from 'react'
import { useReceiverPeer } from './hooks/useReceiverPeer'
import { ConnectionIndicator } from './components/ConnectionIndicator'
import { QRCodeDisplay } from './components/QRCodeDisplay'
import { HintViewer } from './components/HintViewer'
import { ErrorBanner } from './components/ErrorBanner'
import { SenderSimulator } from './SenderSimulator'
import type { HintStep, PeerToPcMessage } from './types'
import './App.css'

function Receiver() {
  const [steps, setSteps] = useState<HintStep[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handleMessage = useCallback((msg: PeerToPcMessage) => {
    if (msg.type === 'steps') {
      setError(null)
      setSteps(msg.steps)
    } else if (msg.type === 'error') {
      setError(msg.message)
    }
  }, [])

  const { roomId, status, regenerateRoom } = useReceiverPeer(handleMessage)

  return (
    <div className="app-shell">
      <header className="app-header">
        <h1>Desk AI Tutor</h1>
        <ConnectionIndicator status={status} />
      </header>

      {error && <ErrorBanner message={error} onDismiss={() => setError(null)} />}

      <main>
        {status === 'connected' && steps ? (
          <HintViewer steps={steps} />
        ) : (
          <div className="waiting-panel">
            <QRCodeDisplay roomId={roomId} />
            {status === 'disconnected' && (
              <button className="reconnect-button" onClick={regenerateRoom}>
                QRコードを再表示して再接続
              </button>
            )}
          </div>
        )}
      </main>
    </div>
  )
}

function App() {
  const params = new URLSearchParams(window.location.search)
  const sendTarget = params.get('send')

  if (sendTarget) {
    return <SenderSimulator roomId={sendTarget} />
  }

  return <Receiver />
}

export default App
