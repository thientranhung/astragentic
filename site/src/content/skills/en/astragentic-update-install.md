---
title: astragentic-update-install
oneLiner: "Check the installed Astragentic version, or install and update it in the current project."
group: upkeep
order: 0
runtimes: [claude]
source: harness/.claude/skills/astragentic-update-install/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

The skill inspects the project, resolves a release tag, stages it and adapts it in the current session. A check-only request permits inspection and reporting, not staging. An explicit install or update request authorizes staging and adaptation.

- **Inspect.** Version evidence is read separately: legacy applied version, Codex installed and adapted versions, and staged releases. Missing state means unknown; staged does not mean adapted.
- **Resolve.** Tags come from `ASTRAGENTIC_REPO` or the canonical repository, never from the project's `origin`. The newest published version tag wins unless the owner names one.
- **Stage.** `get.sh` stages under `.astraler/releases/<version>/` and writes no project file.
- **Adapt.** The session reads `ADAPT-RUNTIME.md` completely and follows the route for its actual runtime.

**Cost.** It never launches another runtime and never stamps completion to bypass unfinished work. It does not edit user-level configuration, commit, publish or deploy unless separately authorized.

## When it is used

| What is in front of you | Reach for |
|---|---|
| "Check the version" | Check-only: inspect and report |
| "Install" or "update Astragentic" | Stage, then adapt in this session |
| A release without `ADAPT-RUNTIME.md` in a Codex session | Leave it staged and say why |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| A fetched release | `.astraler/releases/<version>/` |
| Adapted project files, receipt, version state | As the selected adaptation contract defines |
| A report | Fetched, staged, installed and adapted versions kept apart, plus unresolved conflicts |

## It's working if

- The report distinguishes fetched, staged, installed and adapted.
- Static, mocked and live-session checks are listed as separate evidence.
- No live-startup or enforced-gate claim appears that was not measured.

## Where it fits

It runs on demand, before `dispatch-ticket` has anything new to dispatch under. Release tags are v-prefixed; the updater reads only `refs/tags/v*`.
