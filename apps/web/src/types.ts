export interface HintStep {
  order: number
  content: string
  latex?: string
}

export type PeerToPcMessage =
  | { type: 'steps'; steps: HintStep[] }
  | { type: 'error'; code: string; message: string }

export type ConnectionStatus =
  | 'waiting' // room created, waiting for phone to scan/connect
  | 'connecting'
  | 'connected'
  | 'reconnecting'
  | 'disconnected'
