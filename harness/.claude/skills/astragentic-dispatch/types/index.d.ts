export type BoardRow = {
  key: string
  role: string
  state: 'registered' | 'sent' | 'received' | 'working' | 'ended' | 'merged'
  since: number
  note?: string
}

export type Banner = {
  branch: string
  extra: string
}

export type Flow = {
  ran: string[]
  tddNa: boolean
  reviewNa: boolean
  refusals: number
  lastRefusal: { gate: string; at: number } | null
  qaMode: string | null
}

declare module 'claude-code' {
  interface PluginState {
    'astragentic-dispatch': { board: BoardRow[]; banner: Banner; flow: Flow }
  }
}
