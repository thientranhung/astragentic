---
title: astragentic-dispatch
oneLiner: "The Claude Code mod that makes a dispatched pane record itself, run its brief as a user turn and report its turn end."
group: adapter
order: 0
runtimes: [claude]
source: harness/.claude/skills/astragentic-dispatch/hooks/register.tsx
rented: false
lang: en
updated: 2026-11-22
harness: v6.1.19
---

## What it does

`astragentic-dispatch` (plugin v1.0.3) is a Claude Code mod. It removes three dispatch steps that had no lock and were skipped in production: writing the dispatch record, arming the watcher, and typing the slash command into the pane.

- **Self-record.** A pane whose tab label is `ticket:`, `spec:`, `qa:` or `resident:` writes its own tab and pane ids into `.astraler/state/dispatch-record.json` at session start.
- **Brief as a user turn.** A dispatcher message starting with `/` runs through `$.command.run`; anything else through `$.prompt.submit`. The pane answers RECEIVED at once.
- **Turn end as a bell.** When a turn that a dispatcher message started ends, the pane sends TURN-END and the dispatcher is woken and shown the board.

**Measurement.** The wake takes under one second from turn end, against the 67 s gap of pane-state polling.

**Cost.** It is a bell, not proof: TURN-END says a turn ended, never that the work is right, so verifying by artifact stays the dispatcher's job. It cannot report a pane whose process died.

## Gates on the brief

The brief is the one moment every dispatch passes through, so checks sit on it: an unclaimed ticket is not sent, and a UI brief without Glance, States and Criteria is not sent. The mod blocks `ScheduleWakeup` inside a dispatched pane (4.6.1) and refuses commands that cross hosts, since a session has one host.

## It's working if

- Every live dispatch shows as a line above the dispatcher's prompt.
- A new pane has a record entry before the brief is sent.
- TURN-END arrives after each turn a dispatcher message started.

## Where it fits

It ships four review subagents: `astra-adversarial-lens`, `astra-slice-reviewer`, `astra-test-architect` and `astra-ui-lens`. It sits under `dispatch-ticket` and `dispatch-ticket-claude`, which describe the launcher and the refused steps.
