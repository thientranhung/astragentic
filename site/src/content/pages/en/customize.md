---
title: "Customise the scaffold to the way you work"
description: "Astragentic is a scaffold, not a product: install it into a repo, then change it to fit how you work — and the one doing the changing can be an agent."
---

Astragentic is not a product you use as delivered. It is a **scaffold**: a frame built to be
altered. A role is a file, a skill is a folder, a hook is a script — nothing in it is locked, and no
part has to stay as it is for the rest to run.

That matters because **everyone works with AI differently**, and no single shape is right for
everyone. This page is two things: getting the scaffold into a repo, and then making it yours.

## install

The installer deliberately **does not edit your project**. `./install.sh` stages an immutable
release into `.astraler/releases/<version>` and stops there. Integration is done by an agent running
inside your repo, after it has read the real build command, agent config and Git state.

I split it in two because an installer that copies over things will always copy over the wrong
thing. It cannot tell what belongs to the harness, what belongs to the project, and what belongs to
you.

**Trade-off.** You have to run an extra agent session and read what it intends to do, rather than
typing one command and walking away.

## customize

One Astragentic checkout serves **many projects**. You edit in that checkout rather than in each
repo, then release and reinstall. The path is always one way: checkout → release → project.

```bash
# in your Astragentic checkout
vim .agents/roles/builder.md          # edit a role's contract
echo "2.9.0" > VERSION                # mark a new release
vim RELEASE-NOTES.md                  # record what you changed
./install.sh /path/to/project         # stage the new release into a project
```

Inside the project the adaptation step compares the new release against the running one and **keeps
the files that belong to you**, such as `orchestrator.md` — where you declare which role runs on
which runtime, which model, at which effort.

Three depths of change, lightest first:

- **Change the infrastructure.** Swap the tracker, swap the runtime, add a review step of your own.
  One line in `orchestrator.md` or a different tracker adapter; no role is touched.
- **Change the shape of the team.** Five roles is the default, not a rule. Cut it to two agents —
  one representative and one builder — if the full SDLC loop is more than your work needs.
- **Change the method.** A skill is a folder holding a procedure written in prose. Rewriting one
  changes how the team does that job, and it takes effect at the next dispatch.

**Trade-off.** You own your fork. A later Astragentic release will not carry your changes, and the
adaptation step will ask you wherever the two disagree.

## agent-customize

Here is what separates this from an ordinary scaffold: **the one doing the customising does not have
to be you.**

All of Astragentic is text — contracts in prose, skills in prose, hooks as short scripts. No
binaries, no config schema to learn, no generated file that breaks when edited by hand. A coding
agent can read all of it, and change all of it.

So the fastest way to customise is often to open a session inside the Astragentic checkout itself
and describe how you want to work:

> Read `.agents/roles/` and `.agents/skills/`. I work alone, there are no milestones, and I want to
> see the diff before every merge. Cut this to two roles, drop the milestone gate, and add a
> required step that puts the diff in front of me. Tell me which files you plan to change before
> you change them.

The agent reads the scaffold, proposes a diff, you approve it. It knows `orchestrator.md` is yours
and must not be overwritten. It knows a role is a contract rather than a prompt. Those things are
written in the files it is reading.

**Trade-off.** An agent is confident even when it is wrong. Read the diff before accepting it, and
do not let it edit `VERSION` or `RELEASE-NOTES.md` on your behalf — those two are where your own
decisions are recorded.

## self-repair

The scaffold is not only changed by hand. It also **repairs itself over time**, and the mechanism is
a ledger.

Every time something breaks, the incident is written as one line in an append-only file with a fixed
id, never renumbered and never deleted. A line that yields a rule puts that rule **into a file agents
actually read** — a role contract, a skill, a hook. Next time the whole team behaves differently, not
because anyone remembered, but because the text changed.

That is the closed loop: a failure, a line in the ledger, a rule in a contract, different behaviour
at the next dispatch. The ledger is the scaffold's long-term memory; the contracts are where that
memory takes effect.

### The loop closes at merge

Not at the end of a sprint, and not when somebody remembers. Thomas's contract says it directly:
**write the lesson at merge**, and the merge commit carries a `Ledger:` line naming what went in.

`Ledger: none` is valid. **Its absence is not.** That distinction carries the weight: "this one
taught us nothing" is a conclusion, while no line at all is a step that was skipped — and from the
outside those look identical unless the declaration is required.

### When it reaches an agent

There is no build step and nobody reloads anything. A promoted rule is written straight **into a
file the agent reads at the start of its session** — a role contract, a skill, a hook. Each role's
system prompt is only a few lines, and one of them is an instruction to read its own contract. The
next session opens already carrying the new rule.

A hook covers the rest: after a session compacts, the contract is re-armed, because what sits
outside the system prompt is the first thing compaction summarises away.

Exactly one thing is generated: a **rules index**, derived from the ledger, one line per entry —
the rule without the story around it. It exists because lookup and evidence want different shapes:
read the full entry when you need to know what happened, read the index when you only need to know
what the rule is. That file states on its face that it is derived and not authoritative.

A line that has not yielded a rule yet stays in the ledger rather than being filtered out. An open
record is more honest than a ledger containing only the things already solved.

**Trade-off.** The ledger grows and never shrinks. It is not meant to be read end to end — it is
what you consult when a rule in a contract makes you wonder *why is this here*.

## brownfield

The four skills below exist because real repositories are rarely clean.

- **`bootstrap-glossary`.** Pulls the domain vocabulary out of the code itself; every term carries
  the file it was read from and is marked unconfirmed until the owner says otherwise. The rule is to
  quote, not invent: a glossary an agent imagined but wrote confidently is more dangerous than no
  glossary.
- **`batch-triage`.** Works an inherited backlog in one pass rather than one ticket at a time.
- **`legacy-testing`.** Cuts a seam into code that offers nothing to hold on to.
- **`untangle`.** For a repository with no module boundaries left to improve, where one clean
  restructure produces a diff nobody can review.

**Trade-off.** Common to all four: this is work that has to finish before the first ticket can run.
