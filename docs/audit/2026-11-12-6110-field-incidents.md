# Field incidents after 6.1.10 (batch for the next release)

## J-1 — an owner change of a few lines is cut as a ticket and run as a lane

Owner 2026-11-12, upstream pane: "anh sửa UI nhẹ chỉ thay đổi vài dòng code thì nó cũng cắt tạo ticket … đem đi
thực hiện vòng code, review, merge → đao to búa lớn"; then: "phải nhận biết được cái nào là ticket, cái nào đơn
giản thì đẩy quick-dev … đang gọi là quick-builder đó".

Window: 2026-10-27 (4.6.0, the `quick` label) to 2026-11-12. Dollar figures are Sonnet list price over the
lane's own transcripts; every lane of 20 lines or fewer ran on `claude-sonnet-5`.

| số đo | nguồn |
|---|---|
| nizzy: 126 first-parent merges; 127 issues created, labelled quick 29, full 91, none 7 | `git log --first-parent --merges --since=2026-10-27`; `gh issue list --json labels` |
| merged tickets of 20 non-test lines or fewer that ran as a Builder lane: nizzy 6 of 100 lanes (median 118 model calls, 10 min of pane, $6.6), inception 12 of 194 (median 88 calls, 6 min, $3.6); UI files only: 1 and 3 | `git diff --numstat <merge>^1 <merge>` minus the project's test pattern, joined to `~/.claude/projects/*worktrees-builder-<id>` |
| nizzy, the 5 of those labelled `quick`: median 114 calls, 8 min, $5.8 | same, keyed on the tracker label |
| nizzy tickets of 100 non-test lines or fewer, issue created to merge commit: median 56 min, shortest 4 (n=19) | `createdAt` against the merge's commit date |
| TRA-1428 (17 lines, 3 files, "light yellow around the expanded item table"): an issue, a record entry, a Builder pane, and 20 tool calls in the dispatcher's pane naming the ticket over 9 min; the dispatcher wrote the 17 lines itself inside the Builder's worktree (15:51:59 to 15:52:44Z) and merged at 15:53:37Z, before the pane's review bell at 15:58:00Z; issue closed with "Fixed by Thomas on the owner's word (fast path)" | nizzy root transcript `acd20170…`, 2026-11-12 |
| root sessions that edited code inside a Builder worktree, 30 days: nizzy 1 ticket, inception 0 | Edit/Write and in-place rewrites under `.claude/worktrees/builder-*` in root transcripts |
| lines in the payload that let the dispatcher send a change anywhere but a ticket: 0; lines that forbid it: 2 (`thomas.md` "Nor is the Quick Builder", `quick-builder.md` "Thomas never dispatches you") | payload at v6.1.10 |
| quick-builder sessions in 30 days: nizzy 9, inception 0 | `2026-11-12-619-field-incidents.md` |
| dispatcher-pane dollars per small ticket (cut, claim, dispatch, merge, write-back) | chưa đo; one trace above |
| a live Thomas session opening a Quick Builder pane and landing a change; the same on Orca | chưa đo; static only: staleness exit 0 (thomas.md 2050/2150), reachability exit 0, tests/codex 72 OK |

Layer: upstream. The lane existed (quick-builder, 4.3.0) and only the owner could open it; a request made
in Thomas's pane had one legal route, a ticket.

Fix (role and skill text; no mod, guard or checker change):

- `thomas.md` § Not a ticket: a change the owner judges by looking at the result (a colour, a label,
  spacing, copy, a data row, off the risky paths of `builder.md` § A quick ticket) is not a ticket. Thomas
  opens a Quick Builder pane, sends the owner's words, answers its before/after for him. Work the pane
  returns as needing the loop becomes a ticket. Fifth line in the agent file's compaction list.
- `dispatch-ticket` § Not a ticket (both mirrors): the pane recipe for Herdr and Orca. No issue, claim,
  worktree, record entry, brief or marker; tab `quick-builder`, no `ASTRA_DISPATCH`, so the mod sees the pane
  exactly as it sees an owner-opened one (`whoAmI` returns null); model from the `builder-quick` row.
- `quick-builder.md`: opened by the owner or by Thomas; when Thomas sent the task he stands in for the owner
  (before/after and the word before the commit go to him over SendMessage).
- `ba.md`: a look-and-see change is named a quick-builder change, not a ticket; on the owner's yes the BA
  sends Thomas his words.
- Codex: `roles/thomas.md` carries the recognition rule and cuts nothing; the pane stays owner-opened
  (`launch.py quick-builder`), because the Codex dispatch path has no unrecorded owner-role launch.

Bound on the lane, unchanged: `hook-git-guard.py` quick gate (ops/* branch, `--ff-only`, push to base only),
planted in `selftest.sh` (a guard with the gate off lets `git rebase main` through). No size checker added:
no field number for one.

Not covered: a Thomas-opened pane runs unattended under `--dangerously-skip-permissions` (the owner-opened
one is permissioned and attended); it carries no lane key, so no TURN-END bell, no watchdog and no
`refused-in-dispatched-panes` list apply, and a stalled pane is silent until Thomas reads it. The two launch
commands in the skill have not been executed: one real launch on Herdr and one on Orca before any tag. The
skill tells Thomas to give the word only when his base equals origin's and no merge of his waits unpushed
(TRA-1428: his local merge sat unpushed 15:53:37 to 15:56:29Z, and the pane pushes the base from the root).
A rule saying every change is a ticket: none found in the payload's role, rule and skill text, nor in
nizzy's or inception's CLAUDE.md, AGENTS.md, rules, roles and overlays (grep, 6 patterns); the ticket was the
only route the payload gave, not a rule a project added.

Assumptions stated to the owner: the role keeps the name `quick-builder` (a rename touches the guard, the mod,
the Codex launcher, the README and every project's tab); the three-way call is no ticket / `quick` ticket /
`full` ticket, the first Thomas's, the other two the cutter's.

Closes on: nizzy or inception, after upgrade, count of owner changes of 20 lines or fewer that landed
through a Quick Builder pane against those cut as tickets, and minutes from the owner's message to main.
