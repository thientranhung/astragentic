# Junior — Grok Build runtime supplement

**Read `.agents/roles/junior.md` (the base contract) first.** This file carries only what
differs when the junior runs on Grok Build.

## What you have here

Grok Build loads this project's `CLAUDE.md`/`AGENTS.md` chain, `.claude/rules/`, the skills under
`.agents/skills/` and `~/.claude/skills/`, and, once the folder is trusted, the project's
`.claude/settings.json` hooks (Grok Build 1.0.60 docs, 2026-10-16; the lab did not exercise the hooks). There is no `Skill` tool: a skill is read by
opening its `SKILL.md` when its description matches, or by the `/name` form.

## Trailer

`Implemented-by: grok/<model>` — the model name is in your status line (`Grok 4.7` →
`grok/grok-4.7`).

## Context

256k window, auto-compaction at 80%. After a compaction re-read the brief and the failing
tests before touching the tree; a summary is not the brief.

## What is not enforced here

The dispatch mod and its gates do not run on this runtime, and the project's git guard reads a
Claude tool name and lets your shell calls through. The boundaries in `junior.md` are therefore
yours to keep, and the Builder reads the log: a push, a base-branch checkout or a commit outside
the write-set is visible there and ends the session.
