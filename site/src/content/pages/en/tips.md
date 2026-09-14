---
title: "Tips for running several agents"
description: "Six techniques for running several agents: git worktree, pnpm, portless, a QA walk in a real browser, a runtime of its own for each worktree, and a role kit distilled to markdown."
---

Astragentic builds the parallelism at the coordination layer: Thomas dispatches several tickets and
several Builders work at once. But that whole layer stands on an assumption about your machine —
that three agents running at the same time do not step on each other. A machine does not give you
that by default.

The first five techniques are what closes the gap. Astragentic ships none of them; they are all
existing tools, and each section says which pain it answers.

Those five are ordered by how much you have to hold in your head. The first is the foundation the
rest of the page rests on. The middle three stand on their own: one tool each, one concrete pain
each, usable even if you never do the others. The fifth is where they combine — it is the hard one,
and it only makes sense once the other four have been read.

The sixth stands on a different axis, and it is last for that reason rather than for difficulty.
The first five are about the machine an agent runs on; the last is about what the agent reads when
it starts work.

## git-worktree

**The pain.** You are halfway through something and need a quick look at another branch. The usual
path is `git stash`, `git switch`, look, come back, `git stash pop` — plus a reinstall if the two
branches disagree about dependencies. Multiply that by **three agents working at once** and it stops
being an annoyance and becomes impossible: there is one working directory, and `HEAD` can only point
at one thing.

The obvious way round is to clone the repository three times. That works, and you pay for it with
three copies of the history, three fetches, and three places for remotes to drift apart.

**The technique.** `git worktree` gives you **several working directories from one repository**.
Each checks out its own branch with its own `HEAD` and its own index, while **sharing one object
database**.

```bash
git worktree add ../app-tra-142 -b builder/TRA-142   # new directory, new branch
git worktree list                                     # who is where, on which branch
git worktree remove ../app-tra-142                    # hand it back when done
```

Three properties set it apart from cloning repeatedly, and they are the part that surprises people
who have not used it:

- **It is cheap.** A new worktree costs the checked-out files, not another copy of the history.
  Inside `.git/worktrees/<name>` there is a `HEAD`, an `index`, `refs` and `logs` — and **no
  `objects`**. The object database stays in the main checkout and every worktree reads from it.
- **A branch can be checked out in exactly one worktree.** Try it in a second and git refuses:
  `fatal: 'feature-a' is already used by worktree at ...`. That sounds like a restriction, but with
  several agents it is precisely what you want — two Builders **cannot** take the same branch, and
  it is git saying no rather than a convention somebody has to remember.
- **The main checkout is left alone.** You stay on `main`. Nobody runs `git switch` under your feet
  and nobody stashes on your behalf.

Put the three together and you get what a team of agents needs: **one checkout per Builder, and
inside it that Builder is the sole writer.** Nobody moves anybody else's `HEAD`.

**Trade-off.** One directory per piece of work in flight, and a cleanup step when it ends — a
worktree deleted by hand without `git worktree remove` leaves an orphaned registration, and only
`git worktree prune` clears it. And a worktree's `.git` is a *file* rather than a directory, which
comes back to bite in the last section if you put the repo in a container.

**And here is the limit this whole page is about.** `git worktree` isolates the **working tree**. It
does not isolate what that tree starts: the database, `node_modules`, the ports. The other four
sections are about exactly that gap.

## pnpm

**The pain.** One `git worktree` per Builder means one checkout per Builder, which means a full
`node_modules` per checkout — a few hundred MB every time. Once that number starts to matter, people
do the one thing that breaks the isolation: share one `node_modules` across worktrees. And at that
point the worktrees are not isolated at all, because two branches are reading one dependency tree.

What is worth noticing is that it dies of **an economic decision**, not a technical one. Nobody
weighs it up and concludes that sharing is right; they just begrudge the disk.

**The technique.** [pnpm](https://pnpm.io) installs packages into a single content-addressable store
and **hardlinks** them into each project's `node_modules` instead of copying. N `node_modules`
directories but almost one copy of bytes on disk — so the question "is a fourth worktree worth it"
stops being asked.

**One thing said plainly.** pnpm is usually not chosen for worktree reasons — it tends to predate
the multi-worktree problem entirely. What is true to say is this: pnpm's store-and-hardlink property
is what lets the multi-worktree model pay for its disk. An inherited benefit, not a weighed
decision. Presenting it as deliberate would be prettifying the story.

Three properties, ordered by how much they bear on several worktrees:

- **Disk.** npm copies, so three worktrees cost three times the real space. pnpm hardlinks, and
  three checkouts read from one store.
- **`node_modules` is not flat.** pnpm does not hoist, so a package can only import what it
  declares. Across worktrees sitting on different commits, that blocks a whole class of "works in
  this worktree, breaks in that one" caused by differing dependency graphs rather than by code.
- **Install scripts are off by default.** Running one means naming it, which makes allocating
  `node_modules` explicit.

**Trade-off.** What npm and yarn have that pnpm does not is the flat `node_modules` that tolerates a
package declaring its dependencies incompletely. pnpm exposes those packages instead. That is a
feature, but it is a real cost the day you pull in an old dependency.

**A trap when the repo is bind-mounted into a container.** pnpm puts its store on the same
filesystem as the directory it hardlinks into. If `node_modules` is a named volume while the parent
is a bind mount, those are two filesystems, so pnpm ignores the store you mounted and relocates it
inside the working tree. Measured result: the mounted volume empty, and a few hundred MB of store
landing in the host's working tree as an untracked directory. Shadow the path pnpm **actually
chooses**, not the one the documentation names.

## portless

**The pain.** Two dev servers cannot share a port. Three worktrees running at once is three ports,
and somebody has to choose three numbers, write them down somewhere, and remember them. That is
manual configuration, and manual configuration is what people forget.

Letting the runtime assign random ports ends the collisions but hands you an address nobody can
type: not memorable, not bookmarkable, not pasteable into a ticket. And a URL you cannot type
yields no browser evidence at all.

**The technique.** [portless](https://portless.sh) is a background proxy that
holds port 443 for the machine and maps the name `https://<name>.localhost` onto a localhost port.
It replaces hardcoded ports and the job of remembering port numbers.

With several worktrees it solves exactly one thing: when the runtime assigns a random port to each
stack, something has to give humans and browsers a **stable address** pointing at that random port.

The declaration is one file next to `package.json`:

```json
{
  "name": "myapp",
  "apps": {
    "apps/dashboard": { "name": "myapp" },
    "apps/server":    { "name": "api.myapp" }
  }
}
```

**There are two modes, and the common documentation is thin on the second.** `run` mode is for a
dev server running directly on the machine: portless launches it and supplies `PORT` and `HOST`
through the environment, so the dev server has to read both. `alias` mode is for a containerised
stack, where launching *through* portless is no longer possible — Docker assigns the port first,
and you then register a static alias pointing the name at the port just published.

The naming convention for several worktrees fits on one line, and is worth copying:

```make
DEV_SITE := $(if $(filter main,$(DEV_SLUG)),myapp,myapp-$(DEV_SLUG))
```

`main` keeps the bare name deliberately; every other branch is suffixed. Somebody opening the
familiar URL always lands on main and never wanders into a Builder's half-finished stack. A small
detail, but it separates the address for a human from the address for an agent.

**Trade-off.** A machine-wide daemon holding port 443. Every lifecycle operation on it needs sudo,
which means a TTY, which a background agent does not have — so it has to ask a person. That is a
real operational constraint.

**Four known failures.** `502` is the only symptom when the port drifts, with no clearer error —
the check is to compare the port in `portless list` against the one the framework prints, every
time. A proxy inside a proxy gives `508 Loop Detected` unless the inner one sets `changeOrigin:
true`. A duplicate route reporting "already registered by a running process" means an old process
is still alive, so clear it rather than reaching for `--force`. And killing portless's parent
process does not kill the child dev server, so an orphan keeps holding the route.

**One thing that must never go through portless: the CDP port of an automation browser.** A CDP
client calls `http://127.0.0.1:<port>/json` directly and cannot travel through a name proxy. The
confusion is easy because both are "localhost ports", but portless serves **your app** while the
CDP port is **the browser's debug socket**.

**Who does not need it.** Anyone who cannot give a daemon port 443 for the whole machine, and any
shared machine. For a team with one app on one port, portless is a convenience rather than a need.
It becomes a need exactly when port numbers stop being predictable — which is exactly when you
give each worktree its own runtime.

## browser-qa

**The pain.** An agent reports the ticket done, tests green, diff clean. But the button does not
click because a transparent overlay sits on top of it, or the image does not load because the path
is only wrong once rendered. No test catches it, because no test renders. And a health check answers
an easier question than the one that needed asking: "is the process alive" is not "can a user finish
the job".

**The technique.** A QA agent drives the running product as a user would — through the interface, the journey, the
API contract and the data as they actually appear — instead of reading the diff. It writes an
evidence file the next station can read back.

The tooling splits in two, and **how the roles are split is the part that matters**.

### OmniLogin holds the state

**[OmniLogin](https://omnilogin.net)** is a browser that keeps a profile: cookies, localStorage, installed extensions,
fingerprint, proxy. A clean Chrome launched fresh each run holds none of that, so every journey
behind a login screen is unreachable.

It exposes a local HTTP API to find a profile by name, ask whether it is already open, and open it.
On opening, it returns the **real CDP port** for that launch. That port **changes with every
launch** — remembering the old number is a bug; read it back from the response.

### agent-browser only drives

**[`agent-browser`](https://agent-browser.dev)** is a CLI that attaches to a running browser over CDP and drives it. In this
model it must **never launch a browser of its own**: the moment it does, that is a fresh Chrome with
no login, and every observation made through it is fiction.

So the division of roles fits in one sentence: **state in OmniLogin, control in agent-browser.**
Reverse it — let agent-browser hold the login — and you lose the fingerprint along with the reason
OmniLogin exists.

Three layers of separation when several agents share one browser, and they need telling apart:

- **`--session <name>`** separates the current page and that session's command context. It does
  **not** separate Chrome's set of tabs — CDP exposes one target set for the whole process. Do not
  confuse it with `--session-name`, which is only a key for saved auth state and separates nothing.
- **`--pin-tab`** binds the session to its own tab. The value of the flag is not isolation but
  **turning a silent fallback into an error**: when the bound tab is closed, the next command fails
  with `tab_gone` rather than quietly drifting onto somebody else's tab. It does not make your tab
  private — another agent can still see it, drive it and close it.
- **The daemon** is shared machine-wide and shuts itself down after an hour idle. Worktree cleanup
  must **not** kill it, for the same reason it must not kill a shared container: it cannot be
  attributed to any one worktree.

### One walk

```bash
# 0. The right binary first. A missing flag is a stop, not a case for "being careful".
agent-browser --help | grep -- --pin-tab || { echo "STOP: binary too old"; exit 1; }

# 1-3. Is the browser alive, is the profile open, and what is the REAL port for this launch.
#      Never reuse the port number from last time.

# 4. Is CDP real, and what is the user agent at the browser layer. Note it for step 6.
curl -fsS "http://127.0.0.1:<port>/json/version"

# 5. Attach. `connect`, one --session per agent, with --pin-tab.
agent-browser --session <ticket> --pin-tab connect <port>

# 6. Three proofs. Failing one means stopping and discarding every earlier observation.
agent-browser --session <ticket> eval "navigator.userAgent + ' webdriver=' + navigator.webdriver"
#    (1) matches the UA from step 4   (2) contains no Headless   (3) webdriver=false

# 7-8. Take a tab of your own, then go to your own worktree's stack.
agent-browser --session <ticket> tab new
agent-browser --session <ticket> open "https://myapp-<branch>.localhost/<route>"

# 9-10. Read the accessibility tree with refs, act on a ref, then read again.
agent-browser --session <ticket> snapshot -i
agent-browser --session <ticket> click @ref

# 11. Assert something semantic, not "the page loaded".
agent-browser --session <ticket> screenshot <path>.png
```

**Step 0 comes before step 1** because the wrong binary makes every later step meaningless without
saying so.

**Step 6 cannot be skipped even when step 4 came back green**, because the two ask different
questions: "where do I intend to connect" and "where is the page actually running".

**Refs expire on every navigation**, including an SPA route change or opening and closing a modal.
Take the snapshot again; do not reuse an old ref.

**A React trap:** a CDP-level `click @ref` does not fire React's `onClick`, and `fill ""` does not
fire `onChange`. For a real click, `eval` a `.click()` on the element; to clear an input, use keys —
`Control+a` then `Delete`.

### Five ways it breaks, and only one to fear

| What died | Symptom |
|---|---|
| Browser closed or signed out | The local API does not answer. Stop, and **never fall back to another browser**. |
| The profile closed but the app is alive | The status query says "not open". Reopening gives a new port, which has to be read back. |
| The `agent-browser` daemon died | The next command rebuilds it. But the tab binding is session state, so check the tab again. |
| Somebody else closed your tab | A `tab_gone` error. This is the **most valuable** failure here — it replaces a quiet action on the wrong page with a loud error. Rebind; never retry blind. |
| Attached to the wrong browser | **No symptom at all.** The commands run, the page loads, the result looks reasonable. |

The first four announce themselves. The fifth does not, and the whole discipline above exists for
exactly that one. It is also why checking with `curl` and then acting through the browser proves
nothing — the two commands may be talking to two different browsers. Verify with the same tool you
are about to act with.

For the same reason, a conclusion that **"the tool does not support this flag" can be wrong**: a
machine can carry two CLI versions with the older one resolving first in the shell. Check for the
flag at the start of every session, on every machine.

### The evidence, and one rule worth copying

What it leaves behind is **a file committed on the branch**: screenshots, the path walked, the exact
strings seen, and the CDP port and user agent so the next station knows which browser the evidence
came from. Not an assertion in a pane, because an assertion is not something the next station can
check.

**And this is where the last section starts to be necessary.** Browser evidence
demands a running stack per person. While standing one up is expensive, the step gets skipped, and
the reason for skipping sounds entirely reasonable. Measured once, in a Builder's own words:

> no local stack was running in this worktree; standing one up is a multi-step job

That is precisely the cost the next section removes.

**One rule worth copying.** A rule a careful operator still forgets within an hour needs a required
field blocking the launch, not a sentence living somewhere else. Here it is a required field in the
dispatch brief with no blank form: either this ticket needs browser evidence and here is the
journey to walk, or it explicitly does not and here is why.

**Who does not need it.** A product with no user-facing surface. A team with automated visual
regression already dense enough. And a team that cannot accept an agent driving a real logged-in
session — a legitimate concern, answered here with read-only by default, writes permitted per run,
and one clear rule: the rule is about **data**, not about environment. Data derived from production
is production data wherever it runs.

Some doors do not open, and should not be forced: a marketplace with a bot-detection layer in front
and no account for an agent. The terms-of-service risk lands on somebody's real account, and evidence
obtained by evading only proves that you evaded.

## runtime-per-worktree

**The pain.** You dispatch two tickets to two Builders, one worktree each. The code separates
cleanly — that is what `git worktree` is good at. But both run migrations against one database,
both bind the same port, both write into one `node_modules`. The second Builder breaks the first
one's environment and nobody gets a signal, because nothing errors: two processes sharing one
resource is legal behaviour.

`git worktree` isolates the **working tree**. It does not isolate what that tree starts.

**The technique.** Give each worktree a runtime of its own, and **derive that runtime's name from
the branch** rather than letting somebody choose it.

The second half is the part that matters. Isolating by making each person name their own resources
and pick their own ports in a config file turns isolation into **something you have to remember** —
and what you have to remember, someone eventually forgets, with a silent symptom. Derived from the
branch there is nothing to forget: changing branch changes the runtime, and no file is edited.

**The rule, and this is the part that travels to any stack: isolate mutable state, share
content-addressed state.** Packages and build artifacts are keyed by their own hash, so two branches
wanting two versions get two different keys rather than fighting over one place. Sharing them is
safe structurally, not safe by luck.

### One implementation, to picture it

Astragentic **does not ship** this part and holds no opinion about your stack. The database, the
container runtime, the package manager — those are the project's choices. What follows is **one
example**, from a project using Docker Compose, Postgres and pnpm, so the principle above can be
seen written down. If your project uses Podman, or runs Postgres on the host, or has no database at
all, the principle does not change; only the details do.

In that example the Compose project name is derived from the branch, and Compose prefixes the
project name onto containers, networks and volumes — so one differing name separates four things at
once:

| Runtime | Per worktree | Shared |
|---|---|---|
| Database | Its own Postgres container and volume. Not a schema on a shared server. | The test cluster is the opposite: one container for the machine, isolated inside by templates keyed to the migration set hash. |
| `node_modules` | Two copies: the host one from `pnpm install` in the worktree, and the in-container one as a named volume shadowing the bind mount. | The pnpm store, build cache and module cache, declared `external: true`. |
| FE/BE ports | Nobody picks a port. Compose declares only the in-container port; Docker assigns the outside one. | — |

```make
DEV_SLUG := $(shell git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' \
              | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$$//' | cut -c1-40)
DEV_SLUG := $(if $(filter head,$(DEV_SLUG)),$(shell git rev-parse --short HEAD),$(DEV_SLUG))
DEV_PROJECT := myapp-dev-$(DEV_SLUG)
```

`builder/TRA-686` becomes `builder-tra-686`, and a detached HEAD falls back to the short SHA so the
name stays stable for that checkout.

### Two other answers, and why not

**One database per worktree on a shared Postgres.** Cheaper, and still right for the test cluster.
But `CREATE DATABASE` does not isolate what is cluster-global: roles and passwords. One `ALTER ROLE`
is cluster-wide. A separate instance leaves no shared layer to step on.

**One shared dev stack, and you queue for it.** The cost is not the waiting. It is that people do
not queue — they skip the step.

### Two details easy to miss once containerised

Neither depends on a particular stack; anyone putting a repo into a container meets both.

**Do not give the project a fixed name.** The project name is what gives each worktree its own
resources, and it has to come from the one place that knows which worktree the caller is standing
in. A hardcoded name in config puts every worktree back into one project.

**A worktree's `.git` is a *file*, not a directory.** It holds a host-side absolute path into the
main checkout's `.git/worktrees/<name>`, and a bind mount does not carry that path. Any tooling
shelling out to `git` inside the container fails. The fix is to mount the common git dir read-only
and point `GIT_DIR` at it, both derived from git itself:

```make
DEV_GIT_COMMON := $(shell cd "$$(git rev-parse --git-common-dir)" && pwd)
DEV_GIT_REAL   := $(shell cd "$$(git rev-parse --git-dir)" && pwd)
DEV_GIT_DIR    := $(if $(filter $(DEV_GIT_COMMON),$(DEV_GIT_REAL)),/gitcommon,/gitcommon/worktrees/$(notdir $(DEV_GIT_REAL)))
```

`--git-dir` differing from `--git-common-dir` is how git itself tells a main checkout from a linked
worktree. Use that comparison; do not guess at the shape of the path.

**Trade-off.** The real constraint is not disk, it is RAM. On disk each worktree costs roughly
540–650 MB of volumes, with about 2 GB shared across the machine — not a limit on any modern drive.
RAM is: running two full `-race` test suites at once can make both fail. Anyone adopting this model
has to answer one question first — how many parallel stacks the machine's memory can carry. An
advisory token lock whose `take` exits non-zero while somebody else holds it is enough to queue the
one thing that needs queueing.

**A known leak.** Cleanup only removes volumes when there are containers left to remove. A Builder
who politely stops its stack before handing back leaves zero containers, the condition reads false,
`down -v` is skipped, and the volumes are orphaned while the cleanup stamp still records success. If
you rebuild this model, have cleanup remove volumes **by project name** rather than by the presence
of a container.

**Who does not need it.** A team of one on one branch at a time: this whole mechanism buys exactly
one thing, concurrency, and without concurrency it is only cost. A team whose dev environment holds
no mutable state does not need it either — dynamic ports are enough. And a team running CI on a
clean runner every time does not have this problem at all: it is only real when several checkouts
live on one machine.

## bmad-distilled

**Pain point.** You open a session and ask a large question: design the architecture for this part,
write the PRD for that feature, put together a test strategy. The answer arrives on time, reads
well, and has no shape to it. It is the answer of a general assistant, not of somebody who does
that job.

The familiar fix is to describe the method inside the prompt: follow these steps, ask these
questions first, produce an artifact in this form. It genuinely works, and it costs two things. You
retype it every session, and this retyping is not the last one — the method drifts and nobody
notices, because there is no original to compare against.

The heavier fix is to install a whole method framework. Now you have the original, but you have
taken on a second system to keep alive: its own resolver, its own config file, its own upgrade
cycle, standing beside the harness you already run.

**The technique.** Distil the method down to markdown, and let it live in the project's own `docs/`.

[`docs/bmad-distilled/`](https://github.com/thientranhung/astragentic/tree/main/docs/bmad-distilled)
is a distilled [BMAD](https://bmadcode.com): one `roster.md` naming eight roles, and `capabilities/`
holding 44 files, one per workflow. The personas are quoted verbatim from the original's
`customize.toml`; all the install machinery — the python resolver, `memlog.py`, `config.yaml`, the
headless JSON — is gone. There is nothing left to install.

Calling it is one line in a prompt:

> Play Winston in `docs/bmad-distilled/roster.md`, following
> `docs/bmad-distilled/capabilities/architecture.md`. Design the architecture for: …

Three properties:

- **It is context, not machinery.** The files sit in the repo, so any agent that opens the repo can
  read them — Claude Code, Codex, OpenCode, no adapter needed. Nothing has to stay running, and no
  upgrade can break it.
- **Token cost is the design constraint.** A framework loads the whole set into context. Here a
  capability is a file, so you pay for exactly the part you need: an ordinary session is one role
  plus one or two capabilities. That is also why it is cut into files rather than gathered into one
  large document.
- **The roles have names.** Mary analyses, John writes the PRD, Winston designs, Amelia implements,
  Murat tests. A name does the same job here that it does in Astragentic: it keeps an agent from
  drifting out of its role across a long context.

**It does not replace the method Astragentic runs on.** The main road is mattpocock-skills, and that
method is wired into each role's contract: the Shaper runs grill → to-spec → to-tickets, the Builder
runs implement. `bmad-distilled` is what you reach for in a session standing outside that road —
when there is no ticket to dispatch yet, and you want a roundtable on a design decision before it
becomes a spec:

> Use `capabilities/party-mode.md` and have Winston, Amelia and Murat debate this decision.

**Trade-off.** This is a snapshot. It does not track upstream, so a fix in BMAD does not find its
way here on its own, and you own your distilled copy exactly the way you own your fork of the
harness.

More importantly: **a role kit is prompt level, not contract level.** No hook and no gate makes the
agent follow the file it just read. It improves the shape of an answer; it does not prove a step
ran. Wherever proof is what you need, it still has to be a contract, a receipt and a gate.

**Who does not need this.** Anyone with one well-scoped task: a role kit only adds tokens. And
anyone running the full harness loop, where the role's contract already does this job and carries
the enforcement a role kit does not have.

## one-shape

Three of the four techniques share one shape, and if this page carries away a single sentence it
should be this one: **turn something you have to remember into something that is derived.**

The project name comes from the branch. The port comes from Docker. `GIT_DIR` comes from git. The
domain comes from the branch. No env file changes when you switch branch, so there is no step left
to forget.

The last section has that shape too, one layer up: a method retyped into the prompt every session
is something to remember, while a file in `docs/` is something to read.

That is also why these belong on an Astragentic page rather than in a list of tips.
Coordinating several agents makes a demand that working alone does not: everything has to be right
**without anybody remembering**, because the one doing the remembering is no longer a person.
