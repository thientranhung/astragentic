---
term: Worktree
oneLiner: "One checkout per ticket, so two agents never share a HEAD."
order: 7
related: [claim, brief, gate, cross-vendor-arm]
diagram: parallel-lanes
updated: 2026-09-04
---

**A worktree is a separate git checkout for one ticket, so the [Builder](/dictionary/role) working it never shares a HEAD with anyone else.**

`dispatch-ticket` puts the sequence in a fixed order — the [claim](/dictionary/claim) comes first, then the branch, then the worktree: `git worktree add -b <ticket-branch> <worktree-path> <base>`. The worktree path is always absolute and inside the repo, at `.claude/worktrees/<branch-slug>`, and it's created with `--detach` where the arm needs a throwaway one for spec or slice scope. The Builder is the sole writer inside it; Thomas, Rin, another Builder — everyone else reads. That's the actual isolation boundary, and it's what makes several tickets run on the frontier at once without one agent's `git switch` moving another's HEAD out from under it.

The part that's easy to get wrong is what a worktree actually holds. A worktree carries tracked git content and nothing else — it does not isolate a database container, a background process, or anything a tool writes to a fixed path outside the checkout. That gap is why cleanup needed its own script: `release-worktree-resources.sh` reaps processes rooted in the worktree by real cwd, and `.astraler/project/cleanup-worktree.sh` releases whatever else a project's own tooling allocated. Removal itself is `git worktree remove`, never `rm -rf` — a raw delete leaves the registration behind in `.git/worktrees/`, and the next `add` at that path refuses.

## Why it matters here

Astragentic chose one worktree per dispatch instead of one shared checkout because the failure mode of the alternative was concrete: agents sharing a checkout move HEAD under each other, and a read-only reviewer once `git switch`ed the checkout it was only supposed to inspect. The cost is real too — each worktree is disk (a full checkout, not a symlink), it needs a script-run cleanup step rather than a plain delete, and if that cleanup is skipped, orphaned processes and stale registrations pile up quietly until the next `add` collides with one.

## Seen in:

- `harness/.agents/skills/dispatch-ticket/SKILL.md` (creation, isolation contract, cleanup)
- `harness/.agents/roles/thomas.md` (claim before worktree, cleanup ordering)
- `harness/.agents/roles/builder.md` (sole-writer rule)
- `harness/.agents/skills/dispatch-ticket/CLEANUP.md`
- `RELEASE-NOTES.md` — "Residency by real cwd, adopted downstream-first"

## Usage:

"Why is the merge stuck?" — "Two Builders on one checkout, one of them did `git switch` mid-review. Fresh worktree per ticket, that's the whole fix."
