Props used across `home.mdx`, `why.mdx`, `architecture.mdx`, `compare.mdx`, `evidence.mdx`.
For the builder to match component implementations against. All components imported from
`../../components/<Name>.astro`.

## Eyebrow

Used as a wrapping component with plain text children, no props.

```
<Eyebrow>Orchestration layer for coding agents</Eyebrow>
```

## LaneDiagram

Home only, block 3 (parallel lanes). `lanes`: array of `{ ticket, stages, activeStage }`.
`stages` is the ordered label list (`claim → build → review → merge`); `activeStage` is the
index of the dot's current position, used to draw the four lanes out of phase per the spec in
`content/site/pages/home.md`.

```
<LaneDiagram
  lanes={[
    { ticket: "TRA-139", stages: ["claim", "build", "review", "merge"], activeStage: 1 },
    ...
  ]}
/>
```

## StatTrio

`items`: array of exactly 3 `{ value, label }`. `value` is the mono number/range string
(supports ranges like `"5–14 → 1"`), `label` is the small caption, already upper-cased in the
copy so the component should not re-transform it.

```
<StatTrio items={[{ value: "136", label: "FAILURE MODES, LOGGED" }, ...]} />
```

## Receipt

`kind`: short slug naming what artifact this is (`workspace`, `frontier-query`, `arm-report`,
`git-log`, `tracker-board`, `ledger-excerpt`, `install-commands`, `tracker-excerpt`,
`plan-file`, `ledger-index`). `pending`: boolean — true on every Receipt in this batch, since no
real screenshot/artifact has been captured yet (per build contract §0, never invent one).
`source`: optional string naming where the real artifact would come from, shown as a small
source label. Children (optional): inline literal text of the artifact when it's a short quoted
string (tracker line, file path) rather than an image.

```
<Receipt kind="workspace" pending />
<Receipt kind="tracker-excerpt" source="issue tracker, frontier query" pending>
  `TRA-142  blocked_by  TRA-139`
</Receipt>
```

## DefectCard

`id`: the `AST-xxx` ledger id, rendered in the card's mono header. Children: the one-line story
and cost, as prose/markdown (bold lede sentence + explanatory sentence). This is the only
component licensed to use `--defect`.

```
<DefectCard id="AST-016">
Agents sharing one checkout moved `HEAD` under each other. ...
</DefectCard>
```

## CompareGrid

Two shapes used:
1. Home block 4 — `columns`: array of column headers (4 mechanism names); `rows`: array of
   `{ label, values }` where `values` is a parallel array to `columns`, one entry per column
   (used once for the one-sentence row, once for the Receipt row — `values` can contain JSX
   nodes, not just strings).
2. Architecture stack grid / Compare page — `columns`: array of header labels; `rows`: array of
   `{ label, values, weight? }`. `weight: "required" | "optional"` marks the required-vs-optional
   background distinction described in `02-design-direction.md` §5 (Compare grid).

```
<CompareGrid
  columns={["Astragentic 2.7.13", "Superpowers 6.3.0"]}
  rows={[{ label: "Layer", values: ["...", "..."] }]}
/>
```

## StepRail

Two modes via `sequential` boolean.
- `sequential={false}` (Architecture §2.2, the 5-role rail): `steps` is an array of
  `{ name, cadence, detail, badge, emphasis? }`. `emphasis: true` on the Builder row only, per
  spec (heavier `--rule` border).
- `sequential={true}` (Architecture §2.3, ticket lifecycle): `steps` is an array of
  `{ number, name, artifact, actor, group? }`. `group: "review-ladder"` marks steps 4–6 so the
  builder can draw the bracket grouping them, per the architecture draft's diagram spec §3.2.

```
<StepRail sequential={false} steps={[{ name: "THOMAS", cadence: "resident", detail: "...", badge: "shared" }]} />
<StepRail sequential={true} steps={[{ number: 1, name: "Claim", artifact: "...", actor: "THOMAS" }]} />
```

## Diagram

`slug`: one of the 8 diagram slugs in the build contract's table (`five-roles`,
`ticket-lifecycle`, `parallel-lanes`, `ticket-states`, `frontier-query`, `layer-map`,
`hub-and-spokes`, `cross-vendor-arm`). Used only where the contract's per-page table names it —
`architecture.mdx` uses `five-roles`, `ticket-lifecycle`, `hub-and-spokes`; `compare.mdx` uses
`layer-map`; `evidence.mdx` uses `cross-vendor-arm`. No page invents an unlisted slug.

```
<Diagram slug="five-roles" />
```

## QuoteBlock

Used once, on `evidence.mdx`, for the RELEASE-NOTES 2.7.12 line. `source`: string citation shown
below/beside the quote. Children: the quoted text itself, verbatim.

```
<QuoteBlock source="RELEASE-NOTES.md, 2.7.12">
Every check in this package now proves the tooling is correct. Nothing in it proves the loop works.
</QuoteBlock>
```
