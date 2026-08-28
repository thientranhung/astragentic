# `/architecture` — content + visual spec

Ghi 2026-08-28. Route theo `01-sitemap-and-outline.md` gọi trang này `/how-it-works`; site map
mới nhất (`02-design-direction.md` §4) đổi tên thành `/architecture`. Dùng tên mới — nó đã thắng
trong bản outline gần nhất. Nội dung giữ nguyên việc: năm role, vòng đời ticket, thang review,
tech stack.

## 1. Page purpose

This page proves Astragentic is infrastructure, not a chat window: five fixed roles hand a
ticket to each other through named phases, each phase producing a checkable artifact, and it
runs on a small, named, verifiable stack — not "any AI," not "any tracker."

---

## 2. Section-by-section spec

### 2.1 Header block

- **Eyebrow:** `ARCHITECTURE`
- **Headline:** "Five roles. One ticket at a time." (5 words)
- **Body copy** (30 words): "Astragentic doesn't run one big agent. It runs five narrow roles,
  each with one job and its own session boundary, passing a ticket through fixed phases from
  claim to merge."
- **Component:** page title block (H1-equivalent, serif display, no Eyebrow+Lane yet — plain
  header per `02-design-direction.md` §3 typographic scale, "Display" row).

### 2.2 The five roles

- **Eyebrow:** `ROLES`
- **Headline:** "Five sessions, five different lifespans." (6 words)
- **Body copy** (38 words): "Thomas stays resident and routes. Shaper holds one unbroken session
  from grill to tickets. Builder gets one session per ticket, in its own worktree. Rin reviews
  once per milestone, read-only. QA runs the product itself, once per walk."
- **Component:** **Step rail**, repurposed as a 5-row table-like rail (not sequential — these
  roles are concurrent, not steps). See diagram spec 3.1.

### 2.3 Ticket lifecycle

- **Eyebrow:** `LIFECYCLE`
- **Headline:** "One ticket, seven checkpoints." (4 words)
- **Body copy** (34 words): "Claim decides ownership before a worktree exists. Brief hands off
  the ticket. Five more steps follow in fixed order, each leaving an artifact — a commit, a
  marker, a line in the merge message."
- **Component:** **Step rail** (canonical use — sequential, numbered, each step names its
  artifact). See diagram spec 3.2.

### 2.4 Review ladder

- **Eyebrow:** `REVIEW`
- **Headline:** "One round. Three layers. No loop." (6 words)
- **Body copy** (33 words): "Every ticket passes code-review, a simplify pass, and a
  cross-vendor arm — once, in order. At milestones, Rin adds one more gate. A blocking finding
  goes to the owner, never to another round."
- **Component:** **Lane diagram** — the site's flagship component, here drawn as three
  horizontal lanes converging into a gate. See diagram spec 3.3.

### 2.5 Coordination surface (workspace topology)

- **Eyebrow:** `WORKSPACE`
- **Headline:** "Every agent gets its own pane." (6 words)
- **Body copy** (28 words): "One resident router. Several Builders, each in its own git
  worktree and its own terminal pane. Nothing shares a branch. Nothing shares a session."
- **Component:** **Lane diagram** (second instance) — herdr workspace topology, Thomas
  dispatching into parallel panes. See diagram spec 3.4.

### 2.6 Tech stack

- **Eyebrow:** `STACK`
- **Headline:** "Four required. Two optional." (4 words)
- **Body copy** (25 words): "Claude Code is the root runtime — the milestone gate has no
  fallback. Everything else is an adapter: the tracker, the second vendor, the terminal
  workspace."
- **Component:** **Compare grid** (columns: Component | Role | Required/Optional), reusing the
  8-component inventory's grid rather than inventing a 9th. See diagram spec 3.5.

### 2.7 Tracker note (not a full section — one line)

- **Eyebrow:** none (inline, under the stack grid)
- **Copy** (22 words, no headline): "Exactly one issue tracker per project — GitHub Issues,
  Jira, or Linear. The harness does not run without one."
- **Component:** plain caption line under the Compare grid, mono 12px per Eyebrow style, not a
  new component.

### 2.8 Closing line

- **Eyebrow:** none
- **Copy** (18 words, no headline): "Installation is five steps and it's boring on purpose. See
  it on `/install`, not here."
- **Component:** plain text link-out, bottom of page. No CTA button — per owner constraint,
  installation is not a selling point on this page.

**Total body word count across sections: ~228 words.** Reader time at 200 wpm ≈ 70 seconds of
reading, plus diagram-scanning time — comfortably under the 3-minute budget.

---

## 3. Diagram specs

### 3.1 Five roles — role rail

**Type:** Step rail, non-sequential variant (5 rows, vertical stack on mobile / 5-column grid
on desktop ≥ 900px).

**Columns per row (left to right):**
1. Mono role name, uppercase, bold: `THOMAS`, `SHAPER`, `BUILDER`, `RIN`, `QA`.
2. Session cadence, mono 12px, `--ink-muted`: `resident`, `one per effort (unbroken)`, `one per
   ticket`, `one per milestone`, `one per walk`.
3. One-line job, serif prose 16px: `router — frontier, dispatch, arms, merge`; `grill → spec →
   tickets, no /compact`; `implements + code-review + simplify, own worktree`; `verifies
   artifact AND process traces, read-only worktree`; `runs the real product — journeys +
   contracts`.
4. Isolation badge, mono 11px pill, `--paper-sunk` background: `shared` (Thomas), `shared`
   (Shaper), `worktree` (Builder), `detached worktree` (Rin), `worktree` (QA).

**Ordering:** fixed, matches the order the ticket touches them in the common case (Thomas →
Shaper → Builder → Rin → QA), not alphabetical.

**Emphasis:** row 3 (Builder) gets a `--rule` top+bottom border slightly heavier than the other
four — it's the row every ticket definitely passes through; Rin and QA are milestone/walk-gated,
not per-ticket.

**No color coding beyond `--pass`/`--defect` reservation** — do not invent a 5-color role
palette; that would break the "one accent" rule in `02-design-direction.md` §3.

### 3.2 Ticket lifecycle — step rail

**Type:** Step rail, canonical (numbered, sequential, vertical list, each step full-width row).

**Steps, in order, each with: number (mono, large), step name (serif bold), artifact it leaves
(mono, small, `--ink-muted`), and actor (mono, uppercase, right-aligned):**

1. **Claim** — artifact: `assignee written + read back` — actor: `THOMAS`
2. **Brief** — artifact: `dispatch into pane, at Base commit` — actor: `THOMAS`
3. **Implement** — artifact: `commits on ticket branch` — actor: `BUILDER`
4. **Code-review** — artifact: `both axes, one pass` — actor: `BUILDER`
5. **Simplify** — artifact: `simplify(increment): commit, names the pass` — actor: `BUILDER`
6. **Cross-vendor arm** — artifact: `arm(ticket): receipt` — actor: `BUILDER` (opposite vendor
   reads the diff)
7. **Merge** — artifact: `Ledger: line, assignee cleared` — actor: `THOMAS`

**Emphasis:** steps 4–6 (code-review, simplify, arm) get a bracket/brace on the right margin
labeling them `REVIEW LADDER — one round`, visually grouping them as the block detailed in
§3.3/2.4. This is the one place the two diagrams should visually rhyme so a reader connects
them.

**No branching drawn.** This is the happy path only — do not draw the claim-race or
stale-claim edge cases; those belong in prose/footnote, not the diagram (keeps it readable in
under 5 seconds).

### 3.3 Review ladder — lane diagram (flagship)

**Type:** Lane diagram, 3 horizontal lanes converging to a single gate shape, then branching to
a milestone diamond.

**Lanes (left to right, each lane a horizontal bar/track):**
1. `CODE-REVIEW` — sub-label `Standards + Spec, one pass`
2. `SIMPLIFY` — sub-label `marker commit`
3. `CROSS-VENDOR ARM` — sub-label `Codex ↔ Claude`

**Flow:** all three lanes run in strict sequence (not parallel — correct this against
README's mermaid which draws them as one chain `R1 --> R2 --> R3`, not three parallel lanes).
**Correction to make in the visual:** draw this as ONE lane with three consecutive segments,
not three parallel lanes — parallel lanes would visually claim concurrency that isn't true.
Reuse the "lane" visual language (vertical rule texture) but bend it into a single horizontal
segmented bar: `[ code-review ] → [ simplify ] → [ cross-vendor arm ] → ● MERGE`.

**After MERGE**, a small diamond decision node: `milestone?` — `yes` branches down to a labeled
box `RIN GATE` (colored with `--pass` border, since this is a verification checkpoint); `no`
branches to `next ticket` (loops back to the start of the segmented bar, drawn as a thin curved
arrow, de-emphasized).

**From RIN GATE, one more edge:** `blocking finding` → `OWNER` (small circle/avatar-less node,
labeled `owner`, `--defect` colored — this is the one place `--defect` is licensed to appear on
this page, per the "real defect only" rule). Label this edge clearly: **not** "another round" —
literally draw a small strike-through or "×" near a ghost node labeled `another round` to make
the "no loop" claim visually explicit (echoes the headline "no loop").

**Caption beneath, mono 12px:** `Prior system: 5–14 rounds. This ladder: one.` — sourced to
docs/adr/0001 (cite in the facts table, not on the diagram itself, to keep the diagram
uncluttered).

### 3.4 Workspace topology — lane diagram (second instance)

**Type:** Lane diagram / node graph, matching README's orchestration-topology mermaid
structurally but restyled to house tokens.

**Container:** a single bounding box labeled `HERDR WORKSPACE` (mono eyebrow label top-left of
the box, `--rule` border, `--paper-sunk` fill).

**Nodes inside, arranged as one hub + up to 5 spokes (use exactly the README example
population so the diagram is a real, citable instance, not a generic mockup):**
- Hub: `THOMAS` — `resident router` — larger node, `--pass`-tinted border.
- Spoke 1: `ticket:TRA-139` — sub-label `Builder` — dispatched via edge labeled `dispatch`
- Spoke 2: `ticket:TRA-142` — sub-label `Builder` — edge labeled `dispatch`
- Spoke 3: `spec:TRA-87` — sub-label `Shaper` — edge labeled `dispatch`
- Spoke 4: `qa:TRA-125` — sub-label `QA` — edge labeled `dispatch-qa`
- Spoke 5: `rin:TRA-125` — sub-label `Rin` — edge labeled `review`

**Layout:** hub at left or top-center, 5 spokes fan out to the right/below, each spoke drawn as
its own vertical "lane" bar (reuses the site's vertical-lane texture from
`02-design-direction.md` §3 "Texture" — each spoke lane is literally one of the parallel
vertical lanes described there, giving this diagram double duty as the page's nod to the
homepage's signature motion motif, but **static here**, no animation on this page).

**Emphasis:** all 5 spokes same visual weight — the point is "several agents, same moment, no
collision," so no single spoke should dominate.

**Caption beneath, mono 12px:** `Each Builder: its own pane, its own worktree, its own
branch.`

### 3.5 Tech stack — compare grid

**Type:** Compare grid (columns, not cards), two stacked tables sharing one grid frame.

**Table A — Required (4 rows):**

| Component | Role |
|---|---|
| Claude Code CLI | Root runtime — every role can run here; the milestone gate has no fallback |
| Git (worktree support) | Isolation boundary — one worktree per Builder |
| herdr ≥ 0.8.0 | Terminal workspace manager — agent panes |
| mattpocock-skills ≥ 1.2.3 | The engineering method — wayfinder, grill, spec, tickets, implement, review |

**Table B — Optional (2 rows):**

| Component | Role |
|---|---|
| Codex CLI | Cross-vendor arm — a second AI reviews every ticket |
| OpenCode CLI | Third runtime option for role dispatch |

**Visual distinction between the two tables:** Required rows sit on `--paper-sunk`
background (weightier, "you need this"); Optional rows sit on plain `--paper` with a lighter
`--ink-muted` row label reading `optional` to their left, mono 10px, rotated or as a small
column badge — not a color, since color budget is spent.

**No tracker row inside this grid** — trackers get their own one-line caption (§2.7) below the
grid, not a third table, because "exactly one, pick one" is a different shape of fact than
"required vs optional" and mixing them muddies both.

---

## 4. Facts used on this page

| Claim | Source file:line |
|---|---|
| Five roles: Thomas, Shaper, Builder, Rin, QA | `harness/.agents/roles/thomas.md`, `shaper.md`, `builder.md`, `rin.md`, `qa.md` (role headers) |
| Thomas: resident session | `harness/.agents/roles/thomas.md:3` ("Session: resident") |
| Shaper: one unbroken session, no /compact | `harness/.agents/roles/shaper.md:3-4` |
| Builder: one session per ticket, sole writer in its worktree | `harness/.agents/roles/builder.md:3,8-9` |
| Rin: one per milestone, detached worktree, read-only | `harness/.agents/roles/rin.md:3-6` |
| Rin: one round per milestone | `harness/.agents/roles/rin.md` ("**One round per milestone.**") |
| QA: one per walk, product running, does not read the diff | `harness/.agents/roles/qa.md:3,7-8` |
| Claim: assignee written before worktree exists, read back | `harness/.agents/roles/thomas.md:74-83` (claim protocol) |
| Dispatch via `dispatch-ticket` + runtime adapter | `harness/.agents/roles/thomas.md:116` |
| Review ladder: code-review → simplify → cross-vendor arm, one pass each | `harness/.agents/roles/builder.md:29-33`; `README.md:150-166` (mermaid) |
| Simplify marker commit names the pass | `harness/.agents/roles/rin.md` ("`simplify(increment):` marker ... its body names the pass") |
| Cross-vendor arm receipt `arm(ticket):` | `harness/.agents/roles/builder.md:33,111,159` |
| Merge carries `Ledger:` line | `harness/.agents/roles/thomas.md:202-203` |
| Prior system: 5–14 review rounds | `harness/.agents/roles/rin.md` ("The prior package looped here and measured 5 to 14 rounds"); `docs/adr/0001` |
| Blocking finding escalates to owner, not another round | `harness/.agents/roles/rin.md` (design blocker → owner, mermaid `README.md:160`) |
| Workspace topology: Thomas hub + Builder/Shaper/QA/Rin spokes, per-pane dispatch | `README.md:121-146` (orchestration topology mermaid) |
| Each Builder: own pane, own worktree | `README.md:145-146` |
| Stack required: Claude Code CLI, Git worktree, herdr ≥0.8.0, mattpocock-skills ≥1.2.3 | `README.md:49-52,232-235` |
| Stack optional: Codex CLI, OpenCode CLI | `README.md:241-242` |
| Claude Code CLI: root runtime, Rin gate has no fallback | `check-requirements.sh` (comment above HAVE_CLAUDE check, "Rin's milestone gate runs as a Herdr pane on the root provider's runtime, and no Codex or opencode adapter can host it") |
| Exactly one tracker per project: GitHub Issues / Jira / Linear | `harness/.agents/tracker-contract.md:15-21` |
| Tracker requirement 3 (assignee) met natively by none — readback is advisory | `harness/.agents/tracker-contract.md:109-112` |
| Package is not a binary/npm: install.sh stages to `.astraler/releases/<version>/`, agent then reads ADAPT-HARNESS.md | `README.md:256-266`; `install.sh:5-8,250` |
| Scripts are Bash + Python3 only, no Windows-specific tooling found | inferred from shebangs across `harness/scripts/*` (`3× #!/bin/bash`, `6× #!/usr/bin/env bash`, `3× #!/usr/bin/env python3`) and no `uname`/OS branching in `check-requirements.sh`/`install.sh` — not an explicit repo claim, flag as inference if used verbatim on-page |
