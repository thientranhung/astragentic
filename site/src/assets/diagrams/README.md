# Diagram SVGs — color mapping for `Diagram.astro`

These 8 files are the inline `<svg>` extracted from the archify-delivered HTML in
`site/public/explore/*.html` (see `content/site/04-build-contract.md` §4). Hard-coded
`width`/`height` on the root `<svg>` was stripped; `viewBox` is kept so the component can
size it responsively.

## The SVGs carry classes, not inline colors

Archify's renderer keeps color out of the SVG markup and puts it in a `<style>` block that
lives in the delivered HTML's `<head>`, outside the `<svg>` we extracted. That means these
files render **colorless** (default black/none) until something supplies CSS for the classes
below. `Diagram.astro` must either:

1. Ship a small stylesheet mapping these classes to `02-design-direction.md` §3 tokens
   (`--paper --paper-sunk --ink --ink-muted --rule --pass --defect`), or
2. Wrap each SVG's classed elements and restyle via `:global()` selectors scoped to the
   component.

Option 1 is simpler and keeps every diagram visually consistent with the rest of the site.

## Classes found across the 8 files

Fill/stroke roles (component "type" in the archify JSON — architecture/workflow/dataflow/
lifecycle diagrams):

| Class | Archify default (dark) | Rule | Suggested site token |
|---|---|---|---|
| `.c-backend` | fill `rgba(6,78,59,.4)`, stroke `#34d399` | `fill: var(--backend-fill); stroke: var(--backend-stroke)` | stroke → `--pass` (or `--ink`) |
| `.c-frontend` | fill `rgba(8,51,68,.4)`, stroke `#22d3ee` | same pattern | stroke → `--ink` |
| `.c-security` | fill `rgba(136,19,55,.4)`, stroke `#fb7185` | same pattern | stroke → `--defect` (this is the review/gate color) |
| `.c-database` | fill `rgba(76,29,149,.4)`, stroke `#a78bfa` | same pattern | stroke → `--ink-muted` |
| `.c-cloud` | fill `rgba(120,53,15,.3)`, stroke `#fbbf24` | same pattern | stroke → `--ink-muted` |
| `.c-external` | fill `rgba(30,41,59,.5)`, stroke `#94a3b8` | same pattern | stroke → `--ink-muted` |
| `.c-region` | `fill: color-mix(in srgb, var(--cloud-fill) 48%, transparent); stroke-dasharray: 9 4` | boundary/band fill | → `--paper-sunk` |
| `.c-lane` | `stroke-dasharray: 7 3` | lane divider | → `--rule` |
| `.c-mask` | label background mask, no color rule captured | — | → `--paper` |

Edge/arrow variants (connection `variant` in the JSON):

| Class | Rule | Suggested site token |
|---|---|---|
| `.a-default` / `.m-default` | stroke/fill `var(--arrow)` (`#64748b`) | `--ink-muted` |
| `.a-emphasis` / `.m-emphasis` | stroke/fill `var(--arrow-emphasis)` (`#34d399`) | `--pass` (this is the one accent — reserve it) |
| `.a-security` / `.m-security` | stroke/fill `var(--security-stroke)` (`#fb7185`), dashed | `--defect` |
| `.a-dashed` / `.m-dashed` | stroke/fill `var(--database-stroke)` (`#a78bfa`), dashed | `--ink-muted`, dashed |

Text:

| Class | Rule | Suggested site token |
|---|---|---|
| `.t-primary` | `fill: var(--text)` | `--ink` |
| `.t-muted` | `fill: var(--text-muted)` | `--ink-muted` |
| `.t-dim` | `fill: var(--text-dim)` | `--ink-muted` at lower opacity |
| `.t-backend` / `.t-frontend` / `.t-security` / `.t-cloud` / `.t-external` / `.t-messagebus` | tag/badge text, colored to match the component's stroke | pair with the `.c-*` mapping above |

Sigils (small type-indicator glyphs beside node labels):

| Class | Note |
|---|---|
| `.semantic-sigil` | positioning wrapper, no color |
| `.s-backend` / `.s-frontend` / `.s-security` / `.s-cloud` / `.s-external` / `.s-database` | `color: var(--<type>-stroke)` — same palette as `.c-*` |
| `.sigil-fill` | inherits `currentColor` from the `.s-*` class above |

## Per-diagram notes

- **five-roles, hub-and-spokes, layer-map** (architecture): use `c-backend/-frontend/-security/
  -external`, region boundaries (`c-region`), `a-default/-emphasis/-security/-dashed`.
- **ticket-lifecycle** (workflow): same component classes plus a `group`/`phase` band (renders
  with `c-region`-like dashed framing for the "review ladder" bracket).
- **parallel-lanes, cross-vendor-arm** (sequence): participant boxes use the same `c-*` set;
  messages use `m-*` (filled arrowheads) with `return`/`dashed` variants folded into
  `m-security`/`m-dashed`.
- **ticket-states** (lifecycle): state types (`start/active/decision/success/failure/...`)
  reuse the same `.c-backend/-frontend/-security/-database` classes as architecture diagrams —
  confirmed by inspecting the extracted SVG, no separate lifecycle-only palette exists.
- **frontier-query** (dataflow): stage bands use `c-region`; flows use `a-*`.
- **structure** (architecture, added build spec 4): four `c-region` boundaries (Runtime,
  Harness, Coordination, Your Project); no new classes.
- **hooks** (workflow, added build spec 4): the `guard_decision` group with
  `variant: "security"` renders as `.c-security-group` (not documented above — the
  `c-<variant>-group` pattern extends the group/phase banding already used by
  ticket-lifecycle, just with the security color instead of emphasis). Style it the same way
  as `.c-region` but with `--defect` instead of `--paper-sunk`.
- Both `structure` and `hooks` ship English (`content/site/diagrams/`) and Vietnamese
  (`content/site/diagrams/vi/`) sources; SVGs live at `structure.svg`/`hooks.svg` and
  `vi/structure.svg`/`vi/hooks.svg`.

Build note: the one accent rule from `02-design-direction.md` (`--pass` reserved for
"verified") means `.a-emphasis`/`.m-emphasis` should be the only place a diagram-level accent
color appears — every other class should resolve to neutral ink tones.
