# `/why` — content + visual spec

Drafted 2026-08-28. Source of truth: `harness/.agents/memory/recurring-failure-modes.md` (136-entry
ledger), `harness/.agents/tracker-contract.md`, `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md`.
Every AST id below was opened and read in full before use; two items from the original brief
did not survive verification and were dropped or corrected — see the note at the bottom.

---

## 1. Page purpose

`/why` makes the case for coordination by showing what breaks without it: real, dated defects
from this package's own ledger, not hypothetical risk. It ranks six measured failures from
merely annoying to actively expensive, then walks two downstream projects — on the same day,
on two different trackers — where the pattern played out end to end.

---

## 2. Section-by-section spec

### 2.1 Hero

- **Eyebrow:** `WHY`
- **Headline (7 words):** What breaks without coordination
- **Body copy (39 words):** Four coding agents can share one real codebase. Nothing stops them
  from moving each other's HEAD, shipping conflicting writes, or losing work a pane already
  called done. Every case below is measured, dated, and cited — not a hypothetical.
- **Component:** Eyebrow + headline + prose. No diagram, no CTA — the reader has no reason to
  act yet.

### 2.2 Six failures, ranked

- **Eyebrow:** `SIX FAILURES, MEASURED`
- **Headline (5 words):** Ranked from annoying to expensive
- **Body copy (38 words):** Same pattern every time: agents did exactly what their contract
  said, and the contract had a gap. No malice, no carelessness — just coordination nothing was
  watching. Ordered by what it cost when nobody caught it in time.
- **Component:** Defect card × 6 (spec in §3 below).

### 2.3 Two projects, same migration day

- **Eyebrow:** `TWO PROJECTS, SAME MIGRATION DAY`
- **Headline (7 words):** What two trackers hid on migration day
- **Body copy (33 words):** 2026-08-21: two downstream projects switched issue trackers on the
  same day. One hid its own board from the owner. The other surfaced five coordination
  failures now in this ledger.
- **Component:** Receipt × 2 (one board excerpt, one ledger excerpt) + ~120-word case-study
  prose per project (spec in §4 below).

### 2.4 The rest of the record

- **Eyebrow:** `THE FULL RECORD`
- **Headline (7 words):** 136 more entries live in the ledger
- **Body copy (~30 words):** These six are a sample. The other entries are dated, quoted, and
  bound to the file that fixed them — nothing here is the whole story. Full ledger → `/evidence`.
- **Component:** Stat trio — `6` shown here / `136` total ledger entries / `13` releases in 3
  days that each closed one. Links to `/evidence`.

---

## 3. Defect cards — annoying to expensive

Each card: one-line story, measured cost (as literally measured — no instance generalised into
"always"), AST id. `--defect` red is used on these six cards only.

**1 — Idle capacity**
Twelve tickets were ready to claim. Two of four Builder slots sat idle anyway.
*Cost:* measured once, one project — 2 of 4 slots idle after two merges, 12 claimable tickets
waiting, nothing errored.
`AST-131`

**2 — The board lied about what was still open**
Four tickets kept reading "in progress" days after their code had already merged.
*Cost:* measured once, one project — 4 tickets stale, the oldest by a full day, before anyone
noticed.
`AST-074`

**3 — Two correct tickets, one silent collision**
Two unrelated-looking tickets both edited the same three rows of one shared file.
*Cost:* measured twice in one day — a naive merge would have reverted already-reviewed work.
`AST-056`

**4 — "Done" meant the turn ended, not the work**
A pane read `done` while the Builder was twenty minutes into real, uncommitted work.
*Cost:* measured three times, one pane, one session — the dispatcher nearly reported it
abandoned before checking further.
`AST-097`

**5 — Cleanup deleted work nobody had committed yet**
A Builder stopped after writing code but before committing it. Cleanup then removed the
worktree.
*Cost:* measured five times, three Builder sessions — 93 to 433 lines lost each time, never
recovered.
`AST-092`

**6 — Secrets and buyer PII, committed and reviewed clean**
An export step committed live secrets and buyer PII into a tracked file.
*Cost:* one measured incident — a same-vendor review passed it; a cross-vendor reviewer
caught it before it shipped further.
`AST-015`

---

## 4. Case studies (~120 words each)

### `etsy-fulfillment-thanh` — the board that lied to the one person who couldn't query it

On 2026-08-21, `etsy-fulfillment-thanh` moved its tracker from Linear to GitHub Issues. Every
frontier query the harness ran stayed correct — dispatch, claim, and merge kept working
exactly as before. The board did not: it showed Backlog on 68 of 71 items, three of which had
live Builders actively working. No agent noticed, because no agent reads a board — it
recomputes readiness on demand. The owner did, by opening it and looking. GitHub Issues has no
built-in five-state status a human can read without running a query, so the one surface meant
for a person who cannot query anything was wrong on 68 of 71 items. The tracker contract now
names that surface as a hard requirement, not an assumption.

### `workspace-app-inception` — five failures the pipeline caught on itself

`workspace-app-inception` moved its own tracker from Linear to Jira on 2026-08-21, the project
this package's Jira adapter is measured against. Separately, across its working life, the same
project's own Thomas session surfaced five coordination failures now in the ledger: a `Pass:`
line two of three honest Builders got wrong (AST-090), `install.sh` overwriting the project's
own name on re-staging (AST-091), a cross-vendor review companion exiting 0 on a configuration
failure and caching the false state (AST-095), a pane reading `done` while a Builder was twenty
minutes into real work the dispatcher nearly called abandoned (AST-097), and a fork sub-agent
that returned narration instead of doing its assigned review (AST-098). None were caused by the
tracker swap — the project simply ran its pipeline closely enough to catch what a quieter one
would have missed.

---

## 5. Facts used

| Claim | AST id / source | file:line |
|---|---|---|
| Two of four Builder slots sat idle while twelve tickets were claimable | AST-131 | `harness/.agents/memory/recurring-failure-modes.md:3346` |
| Four tickets read in-progress days after their code had already merged, oldest by a full day | AST-074 | `harness/.agents/memory/recurring-failure-modes.md:1302` |
| Two tickets edited the same three rows of one file; a naive merge would have reverted reviewed work | AST-056 | `harness/.agents/memory/recurring-failure-modes.md:867` |
| A pane read `done` while a Builder was twenty minutes into real work; measured three times, one session | AST-097 | `harness/.agents/memory/recurring-failure-modes.md:2114` |
| Builder stopped before committing; cleanup deleted 93–433 lines, measured five times, three sessions | AST-092 | `harness/.agents/memory/recurring-failure-modes.md:1945` |
| Export step committed live secrets and buyer PII; same-vendor review passed it, cross-vendor caught it | AST-015 | `harness/.agents/memory/recurring-failure-modes.md:109` |
| `etsy-fulfillment-thanh` moved Linear → GitHub on 2026-08-21 | tracker-contract | `harness/.agents/tracker-contract.md:26-27` |
| Board showed Backlog on 68 of 71 items while every frontier query stayed correct | tracker-contract | `harness/.agents/tracker-contract.md:45-46` |
| `workspace-app-inception` moved Linear → Jira (project `IN`) the same day | tracker-contract | `harness/.agents/tracker-contract.md:27-28` |
| Two of three honest Builders wrote a `Pass:` line the verifier rejected | AST-090 | `harness/.agents/memory/recurring-failure-modes.md:1905` |
| `install.sh` overwrites `PROJECT_NAME` on re-staging without `--project-name` | AST-091 | `harness/.agents/memory/recurring-failure-modes.md:1930` |
| Cross-vendor companion exits 0 on configuration failure and caches the false state | AST-095 | `harness/.agents/memory/recurring-failure-modes.md:2048` |
| Fork sub-agents return the coordinator's own narration instead of doing their assigned task | AST-098 | `harness/.agents/memory/recurring-failure-modes.md:2193` |

---

## 6. Verification note — what changed from the brief

Two items in the original starting material did not check out and are not used above:

- **"AST-016 read-only reviewer git-switched the PM's HEAD"** — confirmed accurate at
  `harness/.agents/memory/recurring-failure-modes.md:114`, but redundant with AST-056 for this
  page's six-card budget, so it was left out rather than force a seventh card.
- **"AST-122: 23 real simplify markers across 200 commits, only 1 well-formed `Pass:` line"**
  — does not check out as written. `AST-122` (`recurring-failure-modes.md:3014`) is about
  `Supersedes:` pointer verification and names no marker counts. The "23 real subjects" /
  "200 commits" figures belong to **AST-133** (`recurring-failure-modes.md:3411`): 23 real
  `simplify(increment):` subjects over 200 commits matched 193 times by a `--grep` pattern that
  also caught quoting merge/squash commits — an over-match problem, not a well-formedness
  problem. The "only 1 well-formed `Pass:` line" framing belongs to a different entry,
  **AST-099** (`recurring-failure-modes.md:2231`), which measured `markers=4 wellformed=1` in
  one caught instance and `markers=42 wellformed=36` across a full session. None of the three
  entries states the composite claim as given, so it was dropped rather than repaired into a
  citation that still overstates any single one of them.
- **"AST-074: stale claim keyed on 'assignee set, no branch'; five tickets in-progress with
  zero assignees"** — does not match the ledger. The real AST-074
  (`recurring-failure-modes.md:1302`) is the opposite shape: four tickets stayed
  claimed and in-progress **with a live assignee** after their code had already merged, the
  oldest by a full day. The corrected version is what appears in §3 and §5 above.
