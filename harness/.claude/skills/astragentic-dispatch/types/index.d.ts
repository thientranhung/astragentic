export type BoardRow = {
  key: string
  role: string
  state: 'registered' | 'sent' | 'received' | 'working' | 'ended' | 'merged'
  since: number
  note?: string
}

declare module 'claude-code' {
  interface PluginState {
    'astragentic-dispatch': { board: BoardRow[] }
  }
}
