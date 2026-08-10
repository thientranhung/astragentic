---
name: codex-dispatch-headless
description: Explicit Codex-only exception for visibility=headless implementation. Use only when the owner or the prompt explicitly requests headless; a normal ticket dispatch goes to dispatch-ticket.
---

# Codex headless Builder — an explicit exception

Preconditions, all three: the request says `visibility=headless`, the task is bounded, and
an isolated worktree already exists. Any one of them absent routes back to `dispatch-ticket`,
whose default is the visible Herdr pane.

Spawn the `codex-headless-builder` agent with the worktree, branch, base, ticket,
acceptance criteria, owner intent, validation commands and artifact contract. Print the
resolved exception before spawning:

```text
role=codex-headless-builder
runtime=codex
topology=headless
ticket=<ticket id>
worktree=<absolute-path>
branch=<branch>
```

The headless author cannot approve its own work. Thomas still verifies the artifact,
dispatches Rin's milestone gate, and owns merge and cleanup.
