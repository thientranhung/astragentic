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
  version: string
  /** newest release tag at the package remote when newer than `version`, else '' */
  latest: string
  /** open tickets per status, from `scripts/tracker.sh counts`, refreshed on events only; '' until read */
  tracker?: string
}

export type Flow = {
  ran: string[]
  /** the flow step invoked most recently, by its latest call; null before the first */
  latest: { name: string; at: number } | null
  /** when the pane last ended a turn with nothing live; 0 before the first */
  lastTurnEndAt: number
  tddNa: boolean
  reviewNa: boolean
  uxOwed: boolean | null   // 4.5.3: what the brief said (FLOW names bmad-ux, or `UX: n/a`); null before a brief or with no FLOW line
  refusals: number
  lastRefusal: { gate: string; at: number } | null
  qaMode: string | null
}

declare module 'claude-code' {
  interface PluginState {
    'astragentic-dispatch': { board: BoardRow[]; banner: Banner; flow: Flow }
  }
}
