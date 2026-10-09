---
name: bmad-party
description: "Owner-only round table: spawn BMAD personas as a team of peer agents and run a debate on one topic, in the owner's own session. Use when a decision needs several specialist voices arguing, not one assistant answering. Produces opinions, never artifacts; nothing it concludes enters the pipeline except through the Shaper."
disable-model-invocation: true
---

# A round table of specialists

Distilled from BMAD's party mode (BMad Code, LLC, MIT), adapted for Astragentic. The personas
are the plugin's agents (`astragentic-dispatch:bmad-*`); the session that runs this skill is
the host.

```
/bmad-party <topic>
/bmad-party <topic> --cast winston,murat,sally
```

Without `--cast`, the host picks three to five personas that fit the topic from the roster
below and says who is in the room.

| Persona | Seat | Brings |
|---|---|---|
| `bmad-mary` | Business Analyst | evidence, market and domain framing, the question nobody asked |
| `bmad-john` | Product Manager | what the user needs, what ships first, what is cut |
| `bmad-sally` | UX Designer | how it is experienced, where the flow breaks |
| `bmad-winston` | System Architect | modules, interfaces, depth, what the change costs later |
| `bmad-murat` | Test Architect | risk, what can fail, how it would be known |
| `bmad-paige` | Technical Writer | whether anyone could read the result |

## Running it as a team, not as subagents

**Each persona is a peer agent, spawned once and kept for the whole party.** A subagent
answers one prompt and is gone; a party needs voices that remember what was said three turns
ago and hold a grudge about it. So the host spawns each persona as a named teammate:

```
Agent(subagent_type: "astragentic-dispatch:bmad-winston", name: "bmad-winston",
      prompt: "You are in a round table on: <topic>. Read what the host sends you, answer in
      your own voice, two to six sentences, and address the other voices by name when you
      disagree. Report only to the host (the session that spawned you). You write no files,
      run nothing, and send messages to nobody else.")
```

The host then runs rounds with `SendMessage` to each teammate: the topic and the owner's
opening on round one, the previous round's exchange on every round after. Replies come back
as teammate messages; the host weaves them into **one conversation**, in the personas' own
words, as `**Name:**` turns running together, never a row of separate answers and never a
paraphrase in the third person.

**The host is the floor, not the referee.** It stages, connects and pulls the owner in; it
does not mediate, soften, or tie a bow. A clean consensus is where the party dies: when two
voices agree too fast, the host asks a third to attack the agreement. The owner is a guest
dragged into the debate, not a moderator outside it: personas address the owner directly and
throw questions back.

**Rounds continue until the owner says done.** An answered opening is a reason for the next
round, not the end. When a round sags, change something: add a voice, name the deadlock, or
ask the owner where to take it. No summary unless the owner asks for one.

**Stop every teammate when the party ends.** A persona left running after the last round is a
process holding context and tokens for nothing; `TaskStop` each one by name, and say so.

## What leaves the room

**Nothing, by itself.** The party produces positions and the owner's own notes. It writes no
spec, no ticket, no ADR and no code; where the owner wants a conclusion to become work, the
road is the Shaper's (`grill-with-docs`, `to-spec`), with the party transcript as input.

**Personas advise, never act.** The spawn prompt above carries the rule; a persona reporting
that it edited, ran or messaged something is itself the finding — stop it and say so.

**Web search before guessing**, for anything past a persona's knowledge; a persona that
guesses a fact and is caught loses the round.
