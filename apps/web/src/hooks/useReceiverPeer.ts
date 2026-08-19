import { useCallback, useEffect, useRef, useState } from 'react'
import Peer, { type DataConnection } from 'peerjs'
import { v4 as uuidv4 } from 'uuid'
import { ICE_SERVERS } from '../iceConfig'
import type { ConnectionStatus, PeerToPcMessage } from '../types'

// PC/大画面側: 一意な Room ID で Peer を起動し、スマホからの接続を待ち受ける。
export function useReceiverPeer(onMessage: (msg: PeerToPcMessage) => void) {
  const [roomId, setRoomId] = useState<string>('')
  const [status, setStatus] = useState<ConnectionStatus>('waiting')
  const peerRef = useRef<Peer | null>(null)
  const connRef = useRef<DataConnection | null>(null)
  const onMessageRef = useRef(onMessage)
  onMessageRef.current = onMessage

  const createPeer = useCallback((id: string) => {
    const peer = new Peer(id, { config: { iceServers: ICE_SERVERS } })
    peerRef.current = peer

    peer.on('open', () => setStatus('waiting'))

    peer.on('connection', (conn) => {
      connRef.current = conn
      setStatus('connecting')

      conn.on('open', () => setStatus('connected'))

      conn.on('data', (data) => {
        onMessageRef.current(data as PeerToPcMessage)
      })

      conn.on('close', () => {
        setStatus('disconnected')
        connRef.current = null
      })

      conn.on('error', () => {
        setStatus('reconnecting')
      })
    })

    peer.on('disconnected', () => {
      setStatus('reconnecting')
      peer.reconnect()
    })

    peer.on('error', (err) => {
      console.error('Peer error', err)
      setStatus('disconnected')
    })

    return peer
  }, [])

  useEffect(() => {
    const id = uuidv4()
    setRoomId(id)
    const peer = createPeer(id)

    return () => {
      peer.destroy()
      peerRef.current = null
      connRef.current = null
    }
  }, [createPeer])

  // 復旧不能な切断時に、新しい Room ID で QR を再発行して再接続導線を出す。
  const regenerateRoom = useCallback(() => {
    peerRef.current?.destroy()
    const id = uuidv4()
    setRoomId(id)
    setStatus('waiting')
    createPeer(id)
  }, [createPeer])

  return { roomId, status, regenerateRoom }
}
