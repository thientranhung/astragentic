# Case study — where a Builder's time goes, and why reading dominates (nizzy, 2026-11-27)

Asked by the owner (2026-11-27: «có phải implement thiết kế tdd sẽ lâu hơn», then «có cách tối ưu đọc
code không», then «lưu case study này lại, anh sẽ đi tìm hiểu cách giải quyết»). Kept as evidence for
the owner's own research. Nothing here is a plan: refactoring the project's code is the owner's
decision, and touching it matters (owner: «đụng tới refactor code thì quan trọng đó»).

Rows 45–46 in `docs/audit/2026-11-27-700-field-incidents.md`.

## Population and method

- 63 Builder transcripts of nizzy (`etsy-fulfillment-thanh`) modified since 2026-11-24:
  `~/.claude/projects/*etsy-fulfillment-thanh--claude-worktrees-builder-TRA-*/*.jsonl`.
  95 active hours, median 70.5 active minutes per ticket. 60 of 63 record entries no longer carry
  `kind`, so a few quick tickets may be in the set.
- Active time = the gap after each tool call, capped at 5 minutes, credited to that call's kind.
  The model's thinking before the next call is therefore credited to the call before it.
- Scripts beside this file: `time_by_activity.py` (row 45), `reads.py` and `shell_reads.py`
  (row 46). They read transcripts and the project's `dispatch-record.json` only.

## 1. Time by activity (row 45)

| Activity | Share of active time |
|---|---|
| Reading code (Read, Grep/Glob, grep/rg/sed/cat/git log…) | 42.9% |
| Running tests (incl. waiting for them and reading output) | 14.4% |
| Other shell | 10.4% |
| Review, skills, sub-agents | 4.6% |
| Browser / HTTP checks | 4.5% |
| Editing code | 4.2% |
| Environment, docker, sleep | 3.7% |
| Writing test files | 3.0% |
| git 2.9%, commit 2.2%, build/lint 1.7%, marker gates 1.5% | ~8% |

TDD's own extra: the red run before the first commit (1 of a median 29 test runs per ticket) and
the tdd-order refusal (~1 min, row 31): under 2% of active time. Brief → first red run median
12.7 min; red → first commit 5.1 min; the first test edit came before the first code edit in only
21 of 63 tickets. What red-first catches: `chưa đo`.

## 2. How code is read (row 46)

- Read tool: 4,303 calls over 60 tickets (median 55 per ticket, 20 distinct files); 69% are
  re-reads, and 69% are reads of files the ticket itself edits. The Builder knows WHICH file; the
  cost is finding the place INSIDE it.
- Shell reading is far larger: `grep` 9,541 calls (6.5 MB output), `sed -n <range>` 3,119
  calls (6.9 MB), then `git diff` 536, `git log` 421, `cat` 387.
- 16 source files are 3,000 lines or more. The largest:

| File | Lines |
|---|---|
| `apps/dashboard/src/screens/MasterProducts.jsx` | 7,733 |
| `apps/server/cmd/server/main.go` | 6,584 |
| `apps/dashboard/src/screens/order-items/GuidedSetupFlow.jsx` | 6,014 |
| `apps/dashboard/src/screens/DesignLibraryProduct.jsx` | 4,924 |

  Most re-read in one ticket: DesignLibraryProduct.jsx 101× (TRA-1664), 86× (TRA-1659);
  migration 0161 58× (TRA-1645); revoke_declaration.go (1,418 lines) 55× (TRA-1654);
  MasterProducts.jsx 53× (TRA-1625).

| Tickets | n | Active min (median) | Read calls | Shell reads |
|---|---|---|---|---|
| edit one of the 16 large files | 34 | 115 | 81 | 335 |
| edit none of them | 26 | 55.9 | 34 | 133 |

Correlation, not cause: bigger tickets may be the ones that touch bigger files.

## Open questions for the owner's research

1. Does splitting the largest files cut in-file navigation (grep + `sed -n` per ticket) and active
   time on the tickets that touch them? Measure before and after on the same files.
2. Would symbol navigation (LSP: go-to-definition, references) replace grep + `sed -n` ranges in
   Claude Code on this machine? `chưa đo`.
3. A code map in the brief (nizzy BA's lead): it would name files the Builder already finds
   (69% of reads are of files it edits), so its lever looks small; `chưa đo`.
4. Why 69% re-reads: edits invalidating the earlier read, compaction, or ranged reads of one big
   file? Not separated yet.
