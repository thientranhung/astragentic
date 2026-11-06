---
name: codex-reconcile-tracker
description: "Read-only comparison of Astragentic tracker state against current Git, worktrees and dispatch evidence to report drift."
---

# Read-only reconciliation

Fetch tracker IDs/status/assignee first, including never-merged in-flight work. Read
project prefix and base explicitly. Inspect Git subjects with exact ticket boundaries,
branches, ancestry/unmerged commits, worktrees and current dispatch/pane state. A body
mention is not implementation evidence. A matching subject is still only a clue:
partial fixes, reverts and forward references require inspection.

Report lagging (integrated but tracker open), phantom-done (tracker complete without
verified integration), stale claim (assigned with no confirmed worker/artifact) and
unclaimed in-progress. Distinguish a healthy branch with unmerged work from drift.
A stale-looking record does not prove a process is dead; inspect its actual handle.

Report each class, including none or unmeasured, with evidence and proposed disposition.
Also state coverage limits: missed IDs, incomplete pagination, parent/dependency gates,
board mirrors and unverifiable external integration. This skill writes nothing to
Git or tracker. Any repair is a separate authorized action after the report.
