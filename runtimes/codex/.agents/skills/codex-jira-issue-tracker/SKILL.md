---
name: codex-jira-issue-tracker
description: "Operate an authorized Astragentic Jira workflow with live transition discovery, preserved descriptions and verified dependency direction."
---

# Jira adapter

Read project tracker settings for site/cloudId, project key, identity and workflow.
Use available Atlassian connector tools or the project's installed CLI after inspecting
its actual interface. Do not invent a connector or reuse IDs from another project.
Quote project keys in JQL and paginate. Request only needed fields for frontier reads.

Discover valid transitions from the current issue immediately before changing status;
never write a remembered numeric transition. Report unavailable workflow states instead
of creating substitute labels. Use status category for machine comparisons, keeping
human names separate. Resolve real accountId for assignee; it is not a worker identity.
The coordinator's Markdown dispatch record and Git arbitrate same-account claims.

For description edits read the complete current field, patch programmatically and
preserve Unicode/sections; whole-field replacement from memory loses content. Check
concurrent edits before write. For dependencies inspect available link types, apply
the intended direction and verify the issue's rendered 'is blocked by' wording.
Do not infer correctness from echoing your request payload.

Frontier includes unfinished blockers, parent readiness and explicit deferrals.
After authorized completion, transition newly ready items and read back. Treat workflow
administration and paid/enriched tooling as separate scope. Reconcile partial writes
or uncertain creates before retrying; report drift rather than hiding it.
