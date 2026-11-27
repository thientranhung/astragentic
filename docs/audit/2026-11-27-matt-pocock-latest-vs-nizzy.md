# Matt Pocock skills (latest) against nizzy's 2026-11-27 proposals

Source pulled 2026-11-27: `github.com/mattpocock/skills` main `6f7f783` (2026-11-25), plugin 1.3.2.
Against the local 1.3.2 cache, only `domain-modeling/GLOSSARY-FORMAT.md` and `chief-of-staff` differ;
every engineering skill read below is byte-identical. `docs/matt-pocock-distilled/` was made from
1.3.1 and covers seven skills; the ones that bear on this batch (`implement-spec`,
`improve-codebase-architecture`, `retro`, `software-factory`) are not in it.

Owner, 2026-11-27, in this session: «tôn trọng các góp ý của Nizzy Project và nâng cấp để giải
quyết». nizzy's rulings D and E came relayed from its BA, with the owner's words quoted.

## How Matt handles each problem

| nizzy proposal | nizzy number | What Matt does | Matt source |
|---|---|---|---|
| D. Drop simplify from the Builder | nizzy re-measured here: 1,224 `simplify(increment)` commits in 705 merges since 10-01 (20% of 6,095 commits), 661 empty (54%). inception: 660 of 5,208 commits, 226 empty (34%). Simplify plus what follows it is 27–29% of active time (BA, 238 transcripts; includes the tail after the marker) | **No simplify step exists.** `implement`: tdd at seams, typecheck and single test files often, the full suite once at the end, then `code-review`, then commit. Tidiness is the Standards axis of `code-review`: Fowler smells including Duplicated Code, Speculative Generality and Middle Man, all judgement calls. `retro`: "the review agent should be responsible for imposing coding standards, not the implementation agent", because the implementer has the most context pressure | `engineering/implement`, `engineering/code-review` §3, `engineering/retro` § Implementation vs Review |
| Slice gate gets a cross-ticket reuse lens; its findings become ONE cleanup ticket per slice | one guard built three times (TRA-1671, 1695, 1699) | `implement-spec`: every ticket of a spec lands on one **integration branch**; after the last ticket, ONE `code-review` over the whole branch, and "fix all issues raised … in a single fresh implementer subagent". `software-factory` example "The codebase drifts": an architecture task scans recent changes and "files them as one ticket"; a human picks. `improve-codebase-architecture` scopes by hot spots in recent history (YAGNI) | `engineering/implement-spec` step 7, `in-progress/software-factory/EXAMPLE-TASKS.md`, `engineering/improve-codebase-architecture` §1 |
| Gate cadence keyed to the unit of work and to each release diff, with the count only as a backstop | last three nizzy gates mixed unrelated topics; add-as-variant (TRA-1663/1680/1672/1682/1700) spans several gates | The review unit is **the spec**: `implement-spec` reviews when the spec's frontier is empty, not after N merges. `software-factory`: "cap every loop of runs at a few tries before a human" is the only count | `engineering/implement-spec` steps 6–7, `software-factory` § Start slow |
| Fold a finding into an open ticket on the same feature, as a new criterion, instead of a new ticket | slice gate cut 133 of 708 new tickets since 10-01 | Review fixes do not become tickets: they go to one fresh implementer on the same integration branch. `to-tickets` sizes a ticket to one fresh context window and wants it demoable on its own; a finding is not that | `implement-spec` step 7, `to-tickets` § vertical-slice-rules |
| "slice" misnames a batch review | owner and agents stumble (BA) | Matt's `slice` is a vertical slice, one ticket's end-to-end cut. A review over merged tickets has no name of its own; it is `code-review` on the integration branch | `to-tickets` §3 |
| (d) a code-map slot in the brief | `chưa đo` (TRA-1668: queries.sql read 35×, from the BA, not re-measured) | `implement-spec` step 2: an optional **exploration subagent** writes its notes OUTSIDE the repo, "accessible by all future subagents", so implementers implement instead of exploring. Briefs carry **context pointers**, not copies. `to-tickets` keeps file paths OUT of tickets ("they go stale fast") | `implement-spec` step 2, `chief-of-staff` § Delegate, `to-tickets` §5 |
| B. Lighten the in-Builder review | not decided; review fixed defects on about 37% of tickets (BA) | Review stays per change (`implement`) AND once per spec (`implement-spec`). Matt keeps both | — |

## What this means for Astragentic

1. D agrees with Matt: no implementer-side tidy pass, standards are the reviewer's job, and
   `astra-review` already carries a standards axis. Simplify goes; the marker gate it fed goes with it.
   What else rode on `simplify(increment)` (conflicted-merge STOP, cover, the default kind of
   `check-simplify-markers.sh`) has to move to the marker that stays (`arm(ticket)`, the review lens
   record) or be dropped with a number. That list comes before any deletion.
2. Cross-ticket tidiness belongs to the batch review (slice gate) as one more lens. Its findings
   become ONE cleanup ticket per batch, run through the normal Builder → review → QA flow. Same
   shape as Matt's single fresh implementer after the spec review.
3. Cadence: fire the batch review when a unit of work closes (a spec/effort's tickets all merged)
   and on every staging/prod release diff. "More than 10 merges" stays, but only as the backstop.
4. Findings fold into an open or in-flight ticket of the same feature as a new criterion. A new
   ticket only when no such ticket is open.
5. Naming: say "integration review" in prose. The marker literal `arm(slice)` stays, because the
   checker and the mod key on it.
6. (d): `chưa đo` upstream. Matt's answer (exploration notes outside the repo, pointers in the
   brief) is the shape to test once the per-path Read counts exist.
