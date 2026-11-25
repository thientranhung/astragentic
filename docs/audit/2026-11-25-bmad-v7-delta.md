# BMAD v7 delta against the 2026-10-29 distillation

Date 2026-11-25. Read from a clone of `bmad-code-org/BMAD-METHOD`; nothing installed, nothing copied
into `harness/`. `docs/bmad-distilled/` and `docs/bmad-distilled-latest/` stay as pinned.

## What "v7 is out" means

| Fact | số đo | nguồn |
|---|---|---|
| No v7 tag or GitHub release | newest tag `v6.12.4` (2026-10-14) | `git tag --sort=-creatordate`, `gh release list` |
| npm still ships v6 | last version `6.12.4` | `npm view bmad-method versions` |
| v7 exists as `v7.0.0-alpha.1 - 2026-11-12` | changelog heading on `origin/dev` only | `git show origin/dev:CHANGELOG.md` |
| `main` stops at 2026-11-12 | HEAD `e435a225` | clone |
| `dev` is ahead of `main` | 51 commits, 522 files, +19,529 / −9,574 | `git log origin/main..origin/dev`, `--shortstat` |
| Since our pin `61e01f82` (2026-10-18) on `main` | 29 commits, 669 files, +17,209 / −4,547 | `git diff --shortstat` |

Install is now `npx skills add …/skills/<module> --skill '*'` or the Claude Code / Codex marketplaces at
`bmad-code-org/bmad-plugins`; the npm installer serves v6.12 only.

## The engineering core barely moved

Lines changed on `main` from `61e01f82` to `e435a225`, renames folded (`git diff -M50% --numstat`):

| Skill | +/− | What changed |
|---|---|---|
| bmad-build | +23 / −16 | description; "a loaded run document that lists test files: the plan runs them, a failure blocks completion"; YAML quoting |
| bmad-build-auto | +14 / −11 | same |
| bmad-code-review, bmad-review, bmad-deep-recon | +3 each | module path only |
| bmad-retrospective | +11 / −6 | reads run folders |
| bmad-agent-po | +202 / −72 | offer retrospective before closing an epic; Outcome carries no empty signal sentence; "each `Done when` check is testable" |

Where the volume went: founder +3,151, shard-pro +2,177, core `bmad` setup +1,777, facilitate +1,718,
advanced-elicitation +1,286 (rebuilt), agent-pm +1,061, toolsmith +1,032.

On `dev`, the commits that touch building and review:

- `f48c50a2` build: the coding agent waits for its checks, stops a stuck one and shuts down servers
  before it reports. Verification runs the narrowest tests over the changed files, and the full suite
  only when the project asks. The plan takes the simplest design, and names under **Never** the later
  ticket of the epic that covers nearby work. The 1,600-token split gate is dropped.
- `31116843` build: a `before_implement` hook for ATDD. Red tests are saved skipped, and a task
  unskips each one and sees it fail before code is written.
- alpha.1 Breaking: review depth is a lever and the build defaults to `quick`. The **Acceptance
  Auditor is removed**, and `quick_lenses` / `thorough_lenses` replace `review_layers`.
- `65aceb73` state lives in the document; the shared memlog script is removed.
- `16749b18` agents answer instead of showing a menu.

## Already in the harness — no action

| BMAD v7 item | Harness counterpart | số đo | nguồn |
|---|---|---|---|
| ATDD before implement, red seen before code | tdd gate asks for a red run (4.5.2) | nizzy commit: "Red-first regression test added … confirmed RED against the pre-fold ordering" | nizzy `git log --since=2026-11-01` |
| `retired.toml`, setup deletes retired skills | `astragentic.sh doctor` retired-name check | 0 retired skill dirs: nizzy 25 tracked, inception 24, each one payload or project-own | `git ls-files .claude/skills` in both, against `harness/.claude/skills` |
| Answer, never a menu | HALT menus stripped at the 10-29 distillation | — | `docs/bmad-distilled-latest/README.md` |
| Cold reader does not reopen settled items | the arm does not re-report findings already in the handback | 1 nizzy commit line ("not re-reported here per the arm's own instruction") | nizzy git log |
| State in the document, no memlog | the harness never used memlog | — | — |

## Candidates — chưa đo, measurement first

None of these goes in a plan until it has a harness-side number.

| # | v7 idea | Harness place | What to count | nguồn to read |
|---|---|---|---|---|
| M1 | Acceptance Auditor removed; review defaults to quick | `astra-review` intent axis on full tickets | **measured, keep the axis** — see below | Builder transcripts |
| M2 | Verification: narrowest tests; wait for checks, stop the stuck one, stop servers before reporting | builder.md test step; 6.1.27 background hold | full-suite runs per ticket and their wall time; listeners or children left after the handback | Builder transcripts; hook log |
| M3 | Plan names the later ticket that owns nearby work under **Never** | Builder plan / brief | merged diffs that touch a file a later open ticket of the same spec names | git log + tracker per merge |
| M4 | Elicitation brief: target, purpose, settled list, method, sized return; findings kept out of the next round | `astra-adversarial-lens` at spec scope | **measured, nothing to cut** — see below | Shaper transcripts |
| M5 | `bmad-eval` trigger matrix across a whole install | descriptions of the astra-* skills | wrong-skill loads per session: `Skill` calls whose skill is not the one the role's flow names | `skills_run`, transcripts |
| M6 | `bmad-shard-pro` for long documents | nizzy DESIGN.md (1,211 lines) read by UI tickets | tokens read from DESIGN.md per UI ticket | transcripts |
| M7 | Facilitate `opening`: read the records before anyone speaks from memory | BA, `astra-ux` | 6.1.27 already makes the BA use the real case; count first | BA transcripts after 6.1.27 |

## Measurements (2026-11-25)

### M1 — the intent axis of astra-review: keep it

The method:
- Builder transcripts modified since 2026-11-01: 485 sessions with an intent-lens Agent call,
  480 tickets (nizzy 243, inception 237).
- Each lens report was read from the Agent result. For background runs it came from
  `<session>/subagents/agent-<id>.jsonl`.
- An evenly spaced sample of 40 tickets (20 per project) was judged by 4 Sonnet readers against
  the Builder's own triage text.
- Scripts: `/tmp/astra-measure-scripts/extract.py`. Bundles: `/tmp/astra-m1-bundles/`.

| Count | nizzy (20) | inception (19 readable) | total | nguồn |
|---|---|---|---|---|
| intent findings raised | 42 | 29 | 71 | lens reports |
| acted on (patch or decision_needed, with evidence) | 24 | 12 | 36 (51%) | Builder text |
| acted, and raised by no other lens | 17 | 8 | 25 | Builder text; uniqueness unreadable on 2 tickets |
| tickets with ≥ 1 unique acted finding | 10 / 20 | 5 / 19 | 15 / 39 (38%) | — |
| worst unique finding on those tickets | 1 high, 7 medium, 2 low | 3 medium, 2 low | 1 high, 10 medium, 4 low | — |

The one high: nizzy TRA-1493. The fix could not be reached live, because the entry gate never
mounts the flow. It went to Thomas as `decision_needed`.

Most unique findings are verification gaps: a criterion's test does not prove it, or proves it at
the wrong surface. BMAD's reason to drop its auditor does not carry over: on 38% of sampled tickets
this axis is the only lens that finds an acted-on defect.

Full scan for dropped intent findings: 4 of 480 tickets (5 findings). The worst is nizzy TRA-1607,
where criterion 1 was "partially met" and the Builder closed the axis as "no findings". It is row 26
of `2026-11-22-6120-field-incidents.md`. It did not ship as a product defect: bulk Fulfill calls the same
`reloadOrders()` (nizzy `OrdersScreen.jsx:1412`). The fix, a `Findings: n` line per lens carried into the close line,
is in the next batch (uncommitted). IN-284 and IN-346, flagged at first in this sample, were
not drops: the lens itself called those items acceptable.

Limits:
- The built-in code-review result is not in the bundle, so uniqueness against it is judged from
  the Builder text only.
- A Sonnet reader judged; there was no second judge.

### M4 — spec-scope adversarial lens: no noise to cut

| Count | số đo | nguồn |
|---|---|---|
| Shaper/spec sessions that name `astra-adversarial-lens` since 6.1.22 | 7 sessions in 5 dirs (inception spec-1122, spec-1122b, IN-504; nizzy tra-1617, tra-1631) | `grep -l` over `~/.claude/projects/*spec-*|*shaper-*` |
| handbacks with a filled `Spec read:` line | 1 (inception IN-504): 7 returned, 7 confirmed, 7 changed the spec | transcript grep |

0 unconfirmed findings means the "settled list" has nothing to remove. n=1, so recount after 10
spec runs. The 4 other sessions wrote no `Spec read:` line; whether the lens ran there is chưa đo.

### TEA since `59c164c` (v3.4.0 → v4.5.0, 42 commits, +19,146 / −3,794)

Most of it is CLI hardening (`tea-enforce`, `tea-trace`, `tea-test-review`, eval-quality
engine bumps) and v7 wiring.

What touches the method:
- red mode can skip and report criteria it cannot test (`unusable_criteria`, #509)
- Trace gate thresholds come from config (#526)
- `tea-enforce` rules: hard waits, tautological asserts, skipped or focused tests

The same shapes, counted in downstream test files since 2026-11-01:

| Shape added in test files | nizzy (319 merges) | inception (797 first-parent commits) | nguồn |
|---|---|---|---|
| hard wait (`setTimeout(r, n>0)`, `time.Sleep`, `waitForTimeout`) | 28 lines | 21 lines | `git log --first-parent -m -p` |
| skipped or focused test (`.skip(`, `.only(`, `t.Skip`, `xit(` …) | 1 line | 11 lines | same |

Joined with transcripts: does a file that gained a hard wait appear within 300 characters of "flak" or
"intermittent"? (`/tmp/astra-measure-scripts/flaky.py`)
- nizzy: 4 of 11 such files. The most mentioned is `credential_changed_at_integration_test.go`, 42
  lines; repeated context in transcripts inflates the raw count.
- inception: 1 of 7.
- Of the 8 test files mentioned most often near "flaky" in each project, only 1 is a hard-wait file
  (nizzy's top one). Inception's top three (OrganicBankTab 183, ProjectWeek 165, KeywordDetail 59)
  have none.

So hard waits are not where most flakiness talk comes from, and nothing here justifies a hard-wait
rule. A mention is not a measured flake; a real flake rate would need test re-runs, which are
chưa đo.

### `3f77ec84` Sally onto facilitate

This is an engine move. It also deletes 5 linters (`check_doc.py` 352, `check_ids.py` 458,
`lint_arch.py` 347, `scan_repo_readiness.py` 523, `word_metrics.py` 105 lines). Nothing for
`astra-ux` / `astra-ui` has a harness-side number. The deletion agrees with the
no-meta-machinery ruling.

## Out of scope

Founder module; bmad-ingest; party-mode panels; walkthrough moves; tickets.py, Shortcut store and the
ticket tree (the harness uses the project tracker); Toolsmith memory agents; the facilitate document
catalog (PRFAQ, BRD, pitch …). The harness ships only astra-* names (ruling 2026-10-29).

## Not read (chưa đọc)

- the agent-pm and agent-analyst templates in detail (`2d1680fb`, `6e53b50b`)
- the five Toolsmith quality lenses and the `bmad-eval` case format
