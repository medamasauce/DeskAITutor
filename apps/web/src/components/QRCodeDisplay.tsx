import { QRCodeSVG } from 'qrcode.react'

export function QRCodeDisplay({ roomId }: { roomId: string }) {
  if (!roomId) return null
  return (
    <div className="qr-panel">
      <QRCodeSVG value={roomId} size={220} includeMargin />
      <p className="room-id">
        Room ID: <code>{roomId}</code>
      </p>
      <p className="qr-hint">スマホアプリでこのQRコードを読み取ってペアリングしてください</p>
    </div>
  )
}
