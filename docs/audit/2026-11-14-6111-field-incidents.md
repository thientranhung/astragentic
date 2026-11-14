# Field incidents after 6.1.11 (batch for the next release)

## K-1 — Thomas opens Orca panes from the ticket checkout after a compaction; the owner cannot see them

Recurrence of I-5 (`2026-11-10-610-field-incidents.md`), on the Claude lane this time. Owner 2026-11-14,
upstream pane: "gần đây hay bị lỗi này", with nizzy Thomas's own account: after a compaction it pointed
`--worktree` at the ticket's worktree, ran `orca worktree activate`, and two Builders (TRA-1449, TRA-1444)
were left running where he could not watch them.

| số đo | nguồn |
|---|---|
| nizzy root session `99caf986`: `orca terminal create` naming the base checkout 28 of 28 (2026-11-12 17:25Z to 11-13 18:24Z); compaction at 19:20:49Z; naming the ticket or gate checkout 15 of 15 (19:27Z to 23:58Z: 9 Builder, 6 QA) | `~/.claude/projects/*etsy-fulfillment-thanh/99caf986*.jsonl`, Bash tool calls deduplicated by id, `$W` read from the same command; `compact_boundary` rows |
| compactions in that session: 3 (03:00Z, 11:18Z, 19:20Z); the form flipped after 1 | same |
| `orca worktree activate` on ticket checkouts: 1 command, a loop over the Builder checkouts, 22:03:51Z | same |
| the base-form recipe and "Never `worktree activate` a ticket worktree" were installed when it happened | nizzy `.claude/skills/dispatch-ticket/ORCA.md` lines 28 and 46, applied-version 6.1.11 |
| creates naming the base, both projects, since 6.1.1 reached them: 219 commands; inception 0 off-base | root transcripts of nizzy and inception from 2026-11-10 14:00Z |
| the same form in Codex rollouts, 2026-11-10 to 11-14: 0 found, 2 creates parsed in all | `~/.codex/sessions/2026/11/1[0-4]`; the parser's coverage of Code Mode calls is chưa đo |
| how many of the 15 panes the owner looked for and missed | chưa đo; the owner names 2 and "terminal trống" once |
| the refusal in a live Orca session | chưa đo; stub engine and transcript replay only |

Layer: upstream. The rule was prose in a skill file; a session that has compacted does not carry it, and
nothing between the model and the shell knew the rule.

Fix (dispatch mod, Claude lane): the dispatcher's Bash hook reads the value of `--worktree` on
`orca terminal create` and `orca worktree activate`, with a `$VAR` set in the same command put in its
place. A value under `.claude/worktrees/` is refused; the refusal prints the base form with the session's
own root. It sits above the dispatcher claim, so a refused create leaves no record entry. No skill or role
text changed.

| proof | result |
|---|---|
| planted in `selftest.sh` `orcadisp`: 3 wrong forms (`W=` literal, `W=$(pwd)/…` with a `\` continuation, `worktree activate` in a loop) and 1 base form whose `--command` carries the checkout path and claude's own `--worktree` | 6.1.11 mod: `pass:ran` ×4, entry claimed. This mod: `deny:held` ×3, `pass:ran`, no entry for the refused two |
| replay of the real commands through the transpiled mod | the 15 creates and the activate: refused 16 of 16 (6.1.11 mod: 0 of 16). The 219 base-form commands: 211 run and 8 refused on both mods, the same 8, by guards that predate this one |
| `claude plugin validate` on the mod | exit 0, 45 type warnings before and after (see K-2) |

Not covered: Codex (no mod; `DISPATCH.md` § Orca stays prose, 0 occurrences found). A variable set by an
unquoted command substitution that contains a space (`W=$(git rev-parse --show-toplevel)/…`) is not
resolved and passes. A pane already created from a ticket checkout cannot be reattached (I-5): it stays
unseen until it closes.

Downstream, by hand: nothing. nizzy's two unseen panes finish and hand back as usual.

## K-2 — `claude plugin validate` (2.1.323) type-checks the mod: 45 warnings, exit 0

| số đo | nguồn |
|---|---|
| 45 warnings: 27 possibly-null, 5 + 5 argument or assignment types, 4 `setTimeout`/`clearTimeout` undeclared, 2 possibly-undefined, 1 index type, 1 comparison with no overlap | `claude plugin validate harness/.claude/skills/astragentic-dispatch`, Claude Code 2.1.323 |
| `register.tsx` pushes a row with `state: 'dead'`; `BoardRow` in `types/index.d.ts` has no `'dead'`; the board paints it red, the dispatcher band's `alarmOf` does not count it | `register.tsx` (the `dead` push, the board row, `alarmOf`) |
| whether the band should alarm on a dead lane | chưa đo |

Open. Not fixed in this batch.
