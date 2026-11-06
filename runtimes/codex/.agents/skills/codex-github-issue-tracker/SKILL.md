---
name: codex-github-issue-tracker
description: "Operate an authorized Astragentic GitHub Issues workflow using project-specific labels, identity, dependencies and readback."
---

# GitHub adapter

Read docs/agents/issue-tracker.md for repository, ticket prefix, status labels and
board mapping. Use the available authenticated gh CLI; inspect help/API capability
before unfamiliar writes. Never substitute another repository or invent tracker IDs.
Use body files for multiline content, not shell-interpolated bodies.

GitHub issue number, database ID, node ID and the project's title token are distinct.
Preserve the title token in project references; use the ID type required by the actual
API. Paginate all relevant issues before allocating an ID; a capped first page is not
proof of the maximum. Reconcile ambiguous create results before retrying.

Statuses follow the project's mutually exclusive labels and closed state. An assignee
is a real account, not a unique Builder. Keep dispatch identity and exclusive claim in
the coordinator's Markdown dispatch record; verify branch/worktree ownership. Never clear another attempt's claim.

Use native dependencies/subissues where supported, verifying source and rendered
blocker direction after writes. Read the relation list rather than trusting a lagging
summary immediately after mutation. A migrated missing blocker is UNKNOWN unless the
migration record proves it satisfied. Frontier also considers parent/deferred state.

If a Projects board is configured, its status is a mirror requiring separate verified
writes; lack of board access is not an empty board. Do not initiate credential-scope
changes on the owner's behalf. Report partial writes and reconciliation needs. Only
close/promote issues after verified artifact disposition and existing authorization.
