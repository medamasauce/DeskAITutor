import { useCallback, useEffect, useRef, useState } from 'react'
import Peer, { type DataConnection } from 'peerjs'
import { ICE_SERVERS } from '../iceConfig'
import type { PeerToPcMessage } from '../types'

// 開発用: スマホアプリ実装前に PC⇔スマホ間の P2P 経路を検証するための
// 送信側シミュレータ。本番のスマホアプリと同じ DataChannel プロトコルで
// 疑似データ（steps 配列 / error）を Room ID 宛に送信する。
export function useSenderPeer(targetRoomId: string) {
  const [status, setStatus] = useState<'idle' | 'connecting' | 'connected' | 'failed'>('idle')
  const connRef = useRef<DataConnection | null>(null)
  const peerRef = useRef<Peer | null>(null)

  useEffect(() => {
    if (!targetRoomId) return
    const peer = new Peer({ config: { iceServers: ICE_SERVERS } })
    peerRef.current = peer

    peer.on('open', () => {
      setStatus('connecting')
      const conn = peer.connect(targetRoomId, { reliable: true })
      connRef.current = conn
      conn.on('open', () => setStatus('connected'))
      conn.on('close', () => setStatus('failed'))
      conn.on('error', () => setStatus('failed'))
    })

    peer.on('error', () => setStatus('failed'))

    return () => {
      peer.destroy()
      peerRef.current = null
      connRef.current = null
    }
  }, [targetRoomId])

  const send = useCallback((msg: PeerToPcMessage) => {
    connRef.current?.send(msg)
  }, [])

  return { status, send }
}
