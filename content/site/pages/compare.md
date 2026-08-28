# /compare — content + visual spec

Owner's reason for this page, verbatim: comparison helps people understand Astragentic's
place on the AI vibe-coding map.

Source of record for every claim: `content/positioning/superpowers-vs-astragentic.md`. Design
system: `content/site/02-design-direction.md`. IA: `content/site/01-sitemap-and-outline.md`.

---

## 1. Page purpose

This page answers the one question a comparison page exists to answer: where does Astragentic
sit on the map of AI coding tools, and why doesn't it compete with the method toolkit a reader
already uses. It draws one boundary — Astragentic is the orchestration layer that dispatches
many sessions against a tracker, and the engineering method inside each session is rented from
`mattpocock-skills` — then shows Superpowers sitting at the same altitude as that rented
method, not above or below Astragentic.

---

## 2. Section-by-section spec

### 2.1 Header

- **Eyebrow:** `COMPARE`
- **Headline (6 words):** Where Astragentic sits, not who wins
- **Body copy (33 words):** Astragentic is an orchestration layer, not a method. The
  engineering method — how a single session works — is rented from mattpocock-skills, a
  declared dependency. This page shows where that split puts every named tool.
- **Component:** Page header — eyebrow + serif display headline + one dek paragraph. No CTA
  (per writing rule: comparison positions, it doesn't sell).

### 2.2 The layer map

- **Eyebrow:** `THE MAP`
- **Headline (7 words):** Two layers, and only one is ours
- **Body copy (29 words):** Astragentic sits at the bottom, dispatching sessions. Runtimes —
  Claude Code, Codex, OpenCode — sit in the middle. Method sits on top, inside each session:
  mattpocock-skills is the one Astragentic rents.
- **Component:** Layer map diagram — full spec in §3. This is the page's centrepiece; give it
  the full break-out width (up to 1100px), not the 620px prose column.

### 2.3 The clean difference

- **Eyebrow:** `THE DIFFERENCE`
- **Headline (6 words):** A ticket, not a plan file
- **Body copy (33 words):** A single-session tool ends with a plan file in a branch.
  Astragentic ends with tickets on a tracker, wired by blocking edges — the structure that
  lets several agents work the frontier at once.
- **Component:** Receipt — two real artifacts side by side, each with a source label:
  - Left: a tracker excerpt, e.g. `TRA-142  blocked_by  TRA-139` (source label: "issue
    tracker, frontier query").
  - Right: a file path, e.g. `.claude/plans/2026-08-20-feature.md` (source label: "plan file,
    single session").
  - No verdict line under it — the artifact difference is the whole argument. Let it sit.

### 2.4 Side by side

- **Eyebrow:** `SIDE BY SIDE`
- **Headline (6 words):** Eight rows, same layer, no ranking
- **Body copy (31 words):** Columns, not cards — so nothing reads as a winner. Every row is
  something Astragentic's own docs or Superpowers' own release notes state about themselves,
  not a claim made about the other.
- **Component:** Compare grid — full table in §4.

### 2.5 Convergence

- **Eyebrow:** `CONVERGENCE`
- **Headline (5 words):** Two paths, the same shape
- **Body copy (27 words):** Both systems arrived at the same shape — worktree isolation, a
  fresh subagent per task, two-axis review — without copying each other. That is what the
  numbers below show.
- **Component:** Stat trio —
  - `6` / major versions to arrive (Superpowers, 5.1.0 → 6.3.0)
  - `1` / ADR to arrive (Astragentic, ADR 0001)
  - `3` / shared traits, no copying (worktree isolation, fresh subagent per task, two-axis
    review)

### 2.6 FAQ

- **Eyebrow:** `FAQ`
- **Headline (5 words):** Three questions people actually ask
- **Component:** FAQ list — eyebrow-style mono question labels, serif prose answers, no
  accordion animation (motion budget is spent on the homepage lanes). Full Q&A in §5.

---

## 3. Layer map diagram spec

Not SVG — this is a build spec. Visual language reuses existing tokens only: `--paper-sunk`
band fills, `--rule` hairlines at the band edges, `JetBrains Mono` for every label, 2px corner
radius, no shadows. Static — no animation, `prefers-reduced-motion` is moot here since nothing
moves.

**Layout: three horizontal bands, stacked bottom to top, each full-width within the diagram's
1100px break-out.** A mono eyebrow label sits at the left edge of each band, vertically
centred, reading the band name.

| Band (bottom → top) | Label | Nodes in this band |
|---|---|---|
| Bottom | `ORCHESTRATION` | One node: **Astragentic** |
| Middle | `RUNTIME` | Three equal-size nodes: **Claude Code**, **Codex**, **OpenCode** |
| Top | `METHOD` | Three equal-size nodes: **mattpocock-skills**, **Superpowers**, **others** (dashed border — an unenumerated category, not a specific product) |

**Node styling — critical constraint:** every node in the `METHOD` band is drawn at the same
size, same fill, same weight. `mattpocock-skills` gets no visual promotion over `Superpowers`
for being the one Astragentic uses — the only thing that marks it is the edge described below,
not its box.

**The one edge:** a single connecting line runs from the `Astragentic` node, up through the
`RUNTIME` band (drawn behind/through the runtime nodes, not touching any one of them — the
method relationship isn't tied to a specific runtime), terminating at `mattpocock-skills`.
Small mono caption on the line: `rents`. This is the only edge in the diagram. No line
connects Astragentic to Superpowers or to "others" — their absence of a line is the point, not
an insult; they're simply not the thing being rented.

**Emphasis:** `--pass` (the one accent color, "verified") is used for the Astragentic node and
for the `rents` edge only. Every other node — including `mattpocock-skills` — stays in
`--ink`/`--paper-sunk` neutral. The accent marks *what Astragentic is and does*, not *which
method is best*.

**What a reader should conclude in one glance:** Astragentic is not another box in the top
row. It's the band underneath both other bands, one line reaches up into
`mattpocock-skills`, and the rest of that top row sits at the same height with no line at
all — same layer, different choice, nobody ranked.

**Build note (not a page section):** this diagram doesn't map onto any of the 8 components in
`02-design-direction.md` §5 — the closest, "Lane diagram," is vertical lanes for a ticket's
stages, not stacked technology layers. Flag "Layer map" as a 9th component candidate rather
than silently overloading Lane diagram; that's a call for whoever owns the component library,
not made here.

---

## 4. Comparison grid

Columns, not cards. Eight rows — the ones that decide something; brownfield tooling and
enforcement-script counts are real differences but don't change what a reader concludes, so
they're left out. Neutral column headers — version numbers, not "us" / "them".

| | **Astragentic 2.7.13** | **Superpowers 6.3.0** |
|---|---|---|
| Layer | Orchestration; method rented (`mattpocock-skills`) | Method + orchestration in one session |
| Work state | Issue tracker — frontier query, blocking edges, assignee-as-claim | Plan file in the branch |
| Isolation | One worktree + one pane per ticket; several Builders run at once | `.worktrees/` inside the project; one controller calls subagents |
| Roles | 5 roles with contracts — Thomas, Shaper, Builder, Rin, QA | No roles; one controller |
| Review | 4 layers: two-axis code-review → simplify → cross-vendor arm (Codex ↔ Claude) → Rin milestone gate | 1 reviewer per task (two verdicts) + 1 broad review at branch end |
| Product QA | `dispatch-qa-walk` — runs the built product, real journeys | None |
| Runtimes | Claude Code, Codex, OpenCode | 12+ harnesses (Claude Code, Codex, Cursor, Copilot CLI, OpenCode, and others) |
| Release cadence | 1–2 days; each patch fixes one measured defect | 4–6 weeks |

Caption line under the table (small, mono, `--ink-muted`): *Different layer, not a ranking —
see §5 for what that means for a toolkit you're already using.*

---

## 5. FAQ

**Do I have to stop using Superpowers or mattpocock-skills to use Astragentic?**
No stopping needed for mattpocock-skills — it's a required dependency, not an alternative.
Superpowers works fine on its own, just not in the same repo as Astragentic: two orchestrators
would compete for the same worktrees and tracker state.

**Does Astragentic replace Superpowers?**
No. They sit on different layers — Superpowers bundles method and orchestration into one
session; Astragentic rents the method and coordinates many sessions across a tracker. Neither
is a worse version of the other.

**Why not run both in the same repo?**
Both ship worktree tooling, subagent dispatch, and a SessionStart-style bootstrap. Running
both means two schedulers writing to the same branches and two sets of instructions reaching
every pane — not a feature conflict, a coordination collision.

---

## 6. Facts used

Appendix, not a rendered section — kept here so the build has a source for every number and
claim on the page. `/evidence` can link to specific rows if useful; this table is the ledger.

| Claim on this page | Source |
|---|---|
| Astragentic hard-requires `mattpocock-skills` ≥ 1.2.3 | `check-requirements.sh:83,108-117` |
| Superpowers 6.3.0: 14 skills, 0 agents, 0 commands, 1 `SessionStart` hook (`startup\|clear\|compact`) | `content/positioning/superpowers-vs-astragentic.md:26-33` |
| Superpowers supports 12+ harnesses | `content/positioning/superpowers-vs-astragentic.md:34-35` |
| Superpowers release cadence: 5.1.0 (2026-04-30) → 6.0.0 (2026-06-16) → 6.3.0 (2026-08-12) | `content/positioning/superpowers-vs-astragentic.md:37-45` |
| Astragentic: 5 roles with contracts — Thomas, Shaper, Builder, Rin, QA | `README.md:91-95` |
| Astragentic: 4-layer review incl. cross-vendor arm (Codex ↔ Claude) | `README.md:154`; `content/positioning/superpowers-vs-astragentic.md:65` |
| Astragentic: tracker as coordination substrate — frontier query, blocking edges, assignee-as-claim | `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` ("The tracker is the coordination substrate") |
| Astragentic: one worktree + one pane per ticket, several Builders in parallel | `README.md:60-61,145`; `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` ("This harness extends the claim to build tickets") |
| Astragentic: 3 runtimes — Claude Code, Codex, OpenCode | `README.md:8,232-242,302` |
| 19 of Matt Pocock's skills were vendored in Astragentic 0.2.0, removed once the upstream plugin replaced them | `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` ("19 of Matt Pocock's skills were vendored here in 0.2.0") |
| `dispatch-qa-walk` exercises the running product, not the diff | `README.md:95` |
| Astragentic release cadence: 1–2 days, one measured defect per patch | `content/positioning/superpowers-vs-astragentic.md:70`; recent commit history (2.7.8 → 2.7.13) |
| Convergence: both independently reached worktree isolation + fresh subagent per task + two-axis review; Superpowers via 6 major versions, Astragentic via ADR 0001 | `content/positioning/superpowers-vs-astragentic.md:72-75` |
| Excluded on purpose: Superpowers 6.0.0's "2x faster / ~50% fewer tokens" claim is 6.x vs its own 5.x, never used as a comparison to Astragentic | `content/positioning/superpowers-vs-astragentic.md:47-50` |

---

## Hard rules this spec follows

- No section implies Superpowers is worse — every comparison is framed as *different layer*,
  never *better/worse* (grid caption, layer map node styling, FAQ answers all restate this).
- Superpowers' "2x faster / 50% fewer tokens" number does not appear anywhere on this page.
- No third-party/unverified claims about Superpowers' token cost or open issues appear.
- Every number traces to §6.
