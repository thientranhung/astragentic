#!/usr/bin/env python3
"""check-reachability.sh — does the method the docs describe actually exist?

The prior package lost two weeks to an Align phase that lived in a method document and in
no role's contract, so nothing ever ran it. Every check here exists to make that class of
gap fail loudly instead of quietly.

Eleven checks, in both directions:

  1 METHOD -> CONTRACT   every phase the README's role table names is the owning row of
                         exactly one contract, owned by the role the README names.
  2 CONTRACT -> UNIQUE   every phase any contract declares is declared by exactly one.
  3 SKILL -> NAMED       every shipped skill is named by a contract, another skill, or the
                         adaptation prompt. Read the verb literally: this finds a STRING in
                         a document. It cannot tell a skill that runs every session from one
                         nobody has ever invoked, and it goes green over both. A skill whose
                         trigger is a feeling rather than a step passes here and never runs.
  4 REFERENCE -> EXISTS  every payload path and skill name referenced by a contract or a
                         shipped skill resolves. HARD failure: a contract naming a file
                         that does not exist is how the prior package failed.
  5 ROLE -> STARTABLE    every role has a launcher AND a dispatcher that names it. A role
                         nobody can start is the failure that outlived two rewrites: an
                         align phase described for weeks with no contract owning it, and a
                         browser walker shipped across releases that never ran once.
  6 ADDRESS -> CALLABLE  every skill a contract tells an agent to invoke is written in the
                         form that agent can actually use. Checks 1-5 ask whether a thing
                         exists and is reached; none asks whether the address given for it
                         works. A model-invocable skill written as `/name` is an address no
                         agent has a keyboard for, and the Builder that meets one rolls its
                         own substitute rather than reporting a failure (AST-051).

  7 ARTIFACT -> BOTH ENDS every artifact a gate reads is named by the contract that makes
                         it AND by the contract that checks it. A gate whose producer went
                         quiet cannot fail; a rule living only in a skill is read when that
                         skill runs, not when the deciding role decides (AST-051).
  8 WRITES -> REGISTERED  every document a skill declares it WRITES has a registry row, where
                         a human names who reads it. Checks 1-7 all ask whether a thing is
                         named; none asked whether anything reads what we produce, and three
                         skills shipped for weeks writing files nobody was told to open. The
                         owner found them by hand while every check was green (1.6.1).
  9 SHIPPED -> CALLED    every script the payload ships is called from somewhere that reaches
                         a session. A name in a comment or in a printed string is not a call:
                         two agents scoring one repo three ways got 6, 19 and 13 of 22 tools
                         "wired", and the spread was the finding (2.10.0).
 10 ASSERTION -> TRUE    every `Bound:` / `Wired` / `Enforced by` in the ledger resolves. The
                         entries narrate the past and that is correct; those three labels
                         claim the PRESENT, and a false one closes the question instead of
                         leaving it open. `(gone)` retires a citation explicitly.
 11 RULE -> ITS RUNTIME  every always-on rule reaches the runtime each role is actually
                         assigned to in orchestrator.md. `.claude/rules/` is read by Claude
                         and by nothing else, so reassigning one role in a table can silence
                         a tier (AST-138). Project layout only: no package ships that tier.

Runs against this package (payload under harness/) or an adapted project (payload at the
repo root). Exit 0 = every check passed, 1 = at least one finding.
"""
import os
import re
import sys
import json
import glob
import subprocess

# --- locate the payload -----------------------------------------------------------------
# In this package the payload sits under harness/; once adapted into a project it sits at
# the repo root. Detect rather than take a flag, so the same command works in both places.
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
PAYLOAD = os.path.join(ROOT, "harness")
if not os.path.isdir(os.path.join(PAYLOAD, ".agents", "roles")):
    PAYLOAD = ROOT
LAYOUT = "package" if PAYLOAD != ROOT else "project"

ROLES_DIR = os.path.join(PAYLOAD, ".agents", "roles")
SKILL_GLOBS = [
    os.path.join(PAYLOAD, ".claude", "skills", "*", "SKILL.md"),
    os.path.join(PAYLOAD, ".agents", "skills", "*", "SKILL.md"),
]
README = os.path.join(ROOT, "README.md")
PROMPT = os.path.join(ROOT, "prompts", "ADAPT-HARNESS.md")

# A plugin skill is addressed as `<plugin>:<skill>` — that qualified form is what a typed
# command must use, so contracts write it. Every comparison here is against the bare name,
# so strip a known plugin prefix rather than teaching each check about it.
PLUGIN_PREFIXES = ("mattpocock-skills:",)
def unqualify(name):
    for pre in PLUGIN_PREFIXES:
        if name.startswith(pre):
            return name[len(pre):]
    return name

# Paths the project authors during adaptation. The harness references them and does not ship
# them, so their absence in this package is correct. Named, not hidden in a regex — and
# check-requirements.sh is what verifies them in an adapted project.
PROJECT_SIDE_PREFIXES = ("docs/agents/", "docs/adr/")

# Paths every ADAPTED project has and this package's payload directory does not, because the
# installer injects them from the package root rather than shipping them inside `harness/`.
# `check-requirements.sh` is the whole set: install.sh copies it to `harness/scripts/` inside
# the staged release, so a project resolves `scripts/check-requirements.sh` and the package
# tree does not. Named here rather than excluded quietly — a contract citing it is citing a
# real address, and the alternative was to stop citing the one tool that answers for a project.
INSTALLER_INJECTED = {"scripts/check-requirements.sh": "check-requirements.sh"}


def payload_missing(ref):
    """True when `ref` resolves nowhere a project or this package would find it."""
    if os.path.exists(os.path.join(PAYLOAD, ref)):
        return False
    alt = INSTALLER_INJECTED.get(ref)
    return not (alt and os.path.exists(os.path.join(ROOT, alt)))

findings = []
def fail(check, msg, detail=""):
    findings.append((check, msg, detail))

def read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""

# --- inventory --------------------------------------------------------------------------
# Runtime supplements (builder-claude.md, thomas-codex.md, etc.) are role extensions, not
# independent roles. They have no launcher, no dispatcher mention, and no phase table, so
# they must not enter the checks that verify those things (checks 1, 2, 5). Include their
# text in the reference-scanning checks (3, 4, 6, 7) through a separate dict.
_all_role_files = {os.path.basename(p)[:-3]: read(p)
                   for p in sorted(glob.glob(os.path.join(ROLES_DIR, "*.md")))}
RUNTIME_SUFFIXES = ("-claude", "-codex", "-opencode")
roles = {n: t for n, t in _all_role_files.items()
         if not any(n.endswith(s) for s in RUNTIME_SUFFIXES)}
role_supplements = {n: t for n, t in _all_role_files.items()
                    if any(n.endswith(s) for s in RUNTIME_SUFFIXES)}
all_skills = {}
for pattern in SKILL_GLOBS:
    for p in sorted(glob.glob(pattern)):
        base = os.path.basename(os.path.dirname(p))
        if base in all_skills:
            prev_path, prev_text = all_skills[base]
            all_skills[base] = (prev_path, prev_text + "\n" + read(p))
        else:
            all_skills[base] = (p, read(p))

# Which of those does THIS package own? In package layout, all of them. In an adapted
# project the skill directories hold the project's own skills beside the harness's, and a
# checker that cannot tell them apart reports every project skill as an unreachable defect.
# The staged release is the authoritative manifest of what the harness shipped, so read it.
def harness_owned():
    if LAYOUT == "package":
        return set(all_skills)
    applied = ""
    for candidate in (os.path.join(ROOT, ".astraler", "state", "applied-version"),
                      os.path.join(ROOT, ".astraler", "CANDIDATE")):
        if os.path.isfile(candidate):
            applied = read(candidate).strip()
            if applied:
                break
    owned = set()
    for sub in (".claude", ".agents"):
        owned |= {os.path.basename(os.path.dirname(q)) for q in glob.glob(os.path.join(
            ROOT, ".astraler", "releases", applied or "*", "harness", sub, "skills",
            "*", "SKILL.md"))}
    return owned

HARNESS_OWNED = harness_owned()
# Ownership is decided by the staged release. With no release to read, this run cannot tell
# harness skills from the project's — say so, because falling back silently to "everything
# is ours" is how the false findings this check was fixed for come back (AST-038).
ATTRIBUTION = "release manifest"
if not HARNESS_OWNED:
    HARNESS_OWNED = set(all_skills)
    ATTRIBUTION = "NONE — no staged release found, treating every skill as harness-owned"
    # ABSENCE IS A FINDING, not a footnote. Printing the fallback was not enough: the run
    # continued and could still exit 0, and a clean verdict under "everything is ours" is a
    # DIFFERENT CLAIM from a clean verdict under the manifest — same word, same exit code.
    # Measured 2026-08-20: an adaptation session copied a release's payload into its worktree
    # without committing the release ARCHIVE, the glob came up empty, and the checker flagged
    # that project's OWN skills as broken references. A round earlier the same fallback was
    # silently active and happened to trip on nothing, so it reported all checks OK — true by
    # accident, not by a working mechanism, which is the worse of the two outcomes because
    # nobody investigates a pass (AST-118).
    fail("0", "no staged release manifest for the applied version — ownership is unknown, "
              "so every verdict below is about a guess rather than about the harness",
         "commit .astraler/releases/<applied-version>/ alongside the payload it installed; "
         "only the CURRENT applied release needs to be present")
PROJECT_OWNED = set(all_skills) - HARNESS_OWNED
skills = {n: v for n, v in all_skills.items() if n in HARNESS_OWNED}

# Skills installed at user level are legitimate references a project skill may name.
USER_SKILLS = {os.path.basename(os.path.dirname(q))
               for pat in (os.path.expanduser("~/.claude/skills/*/SKILL.md"),
                           os.path.expanduser("~/.agents/skills/*/SKILL.md"))
               for q in glob.glob(pat)}

if not roles:
    print(f"No role contracts under {ROLES_DIR} — nothing to check.", file=sys.stderr)
    sys.exit(2)

# Plugin skills are legitimate references that this payload does not ship. Read the
# installed manifest when it is there; fall back to the names the method depends on, so
# the check still runs on a machine without the plugin installed.
PLUGIN_FALLBACK = {
    "triage", "wayfinder", "to-questionnaire", "ask-matt", "grill-with-docs", "to-spec",
    "to-tickets", "implement", "code-review", "grilling", "tdd", "codebase-design",
    "domain-modeling", "research", "prototype", "diagnosing-bugs", "wizard",
    "implement-spec", "pr", "retro", "improve-codebase-architecture",
    "setup-matt-pocock-skills", "handoff", "teach", "grill-me", "wait-what",
    "writing-for-agents",
}
def plugin_skills():
    manifest = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
    try:
        with open(manifest, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return set(PLUGIN_FALLBACK)
    for name, installs in (data.get("plugins") or {}).items():
        if name.split("@")[0] != "mattpocock-skills":
            continue
        for entry in installs or []:
            manifest_path = os.path.join(entry.get("installPath", ""),
                                         ".claude-plugin", "plugin.json")
            try:
                with open(manifest_path, encoding="utf-8") as fh:
                    return {s.rsplit("/", 1)[-1] for s in json.load(fh).get("skills", [])}
            except (OSError, ValueError):
                continue
    return set(PLUGIN_FALLBACK)

PLUGIN = plugin_skills()
# A Claude Code mod ships as `.claude/skills/<name>/.claude-plugin/plugin.json` with no
# SKILL.md: the engine auto-loads a plugin from a project skills folder. It is shipped payload
# that a contract names, so it resolves. Counting only SKILL.md failed every doc that named the
# dispatch mod.
SHIPPED_MODS = {os.path.basename(os.path.dirname(os.path.dirname(p))) for p in
                glob.glob(os.path.join(PAYLOAD, ".claude", "skills", "*", ".claude-plugin", "plugin.json"))}
# A shipped mod's `agents/*.md` declare subagent types (`<mod>:<name>`), measured 2.19.0: a
# contract or skill names one in backticks the way it names a skill, and it resolves.
SHIPPED_AGENTS = {os.path.basename(p)[:-3] for p in
                  glob.glob(os.path.join(PAYLOAD, ".claude", "skills", "*", "agents", "*.md"))}
# A name is resolvable when anything on this machine actually provides it.
KNOWN = set(all_skills) | PLUGIN | USER_SKILLS | SHIPPED_MODS | SHIPPED_AGENTS

# Kebab-case tokens that are vocabulary rather than skill references. Each is here because
# it appears in backticks and looks like a skill name; the list stays short on purpose,
# because a long one would mean this check has stopped discriminating.
# A PROJECT DECLARES ITS OWN VOCABULARY, AT A PATH NO RELEASE WRITES. Every project has
# skill-shaped tokens of its own — a container name, a queue, a feature flag — written in
# backticks in its own contracts. Until 2.10.0 the only way to silence one was to edit the set
# below, which is PAYLOAD: the next release overwrites it, so the project does that work again
# every upgrade, and the error text was telling projects to do exactly that — two owners for
# one path, neither able to see the other (`AST-132`). 2.7.15 correctly removed two downstream
# project names from this set because the
# payload names no project — and left projects with nowhere to put them.
#
# So the same split this release ships for tracker status: the package owns the check, the
# project owns its vocabulary, at `.astraler/project/not-a-skill.txt` — one token per line,
# `#` comments allowed. Absent is an empty socket, not a fault. Measured on the first real
# project to run this: one Docker container name in a contract kept its reachability gate
# permanently red, and a gate that cannot go green is a gate people stop reading.
def project_vocabulary():
    path = os.path.join(ROOT, ".astraler", "project", "not-a-skill.txt")
    out = set()
    for line in read(path).splitlines():
        tok = line.split("#", 1)[0].strip().strip("`")
        if tok:
            out.add(tok)
    return out


NOT_A_SKILL = {
    # An orchestrator config key. Skill-shaped, and not a skill. (Two downstream project names
    # sat here until 2.7.15, because tracker-contract.md named them — the payload names no
    # project, so both the citation and this allowance are gone.)
    "builder-target",
    # Triage labels. Skill-shaped, and the vocabulary lives in docs/agents/triage-labels.md.
    "needs-triage", "ready-for-agent",

    "no-secrets-in-exports", "expand-contract", "recent-unwrapped", "code-map",
    "agent-not-idle", "agent-not-found", "agent-prompt-stalled", "read-only",
    "cross-vendor", "single-provider", "gate-arm", "wontfix-with-a-recorded-reason",
    "claude-plugins-official", "mattpocock-skills", "claude-sonnet-4-6", "openai-codex",
    "issue-tracker", "triage-labels", "check-requirements", "install", "uninstall",
    # CLI subcommands and flags that happen to be kebab-case.
    "adversarial-review", "send-text", "send-keys", "gate-diff", "no-focus",
    "allowed-tools", "dangerously-skip-permissions", "project-name", "optional-too",
    "applied-version",
    # Dispatch naming convention, not a skill. It has shipped in dispatch-ticket since 2.3.2
    # and this check has been red upstream ever since — papered over by a local edit
    # downstream that never came back (AST-116).
    "builder-abc-123",
    # Frontmatter keys quoted in prose about how skills are reached.
    "disable-model-invocation",
    # A triage LABEL that to-tickets writes at creation. Named in the frontier audit precisely
    # because a dispatcher must not read it as a blocker (AST-057).
    "ready-for-agent",
    # An AGENT, not a skill — named in builder.md as the substitute a Builder must NOT
    # reach for when the simplify invocation errors (AST-055). Naming it is the point.
    "code-simplifier",
    # A field in orchestrator.md's Workspace identity table, not a skill — the herdr
    # workspace name Thomas resolves before any dispatch.
    "workspace-label",
    # A tracker STATUS LABEL on GitHub, named in the adapter beside `backlog` and `todo`,
    # which are single words and do not reach this list.
    "in-progress",
    # An MCP SERVER, not a skill — the Linear adapter names it so a session reaches Linear
    # through its tools rather than shelling out to a CLI.
    "linear-server",
}
# The project's own tokens join the payload's. Union, never replacement: a project cannot
# silence the package's vocabulary by declaring its own.
PROJECT_VOCAB = project_vocabulary()
NOT_A_SKILL |= PROJECT_VOCAB

# --- 1. METHOD -> CONTRACT --------------------------------------------------------------
# The README's role table is the method's own statement of who drives what. Parse the
# backticked names out of each row and require the matching contract to own them. Counting
# TABLE ROWS matters here: a bare grep for `code-review` hits all four contracts, and three
# of those are handoff mentions rather than ownership.
readme = read(README)
method_rows = {}
if readme:
    section = readme.split("## The method", 1)[-1].split("\n## ", 1)[0]
    for line in section.splitlines():
        if not line.startswith("|") or line.startswith("|---") or "Session" in line:
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 3:
            continue
        role = re.sub(r"[*`]", "", cells[0]).split("—")[0].strip().lower()
        named = [unqualify(x) for x in re.findall(r"`([a-z0-9:-]+)`", cells[2])]
        named = [x for x in named if x in KNOWN]
        if named:
            method_rows[role] = named
else:
    fail("1", f"README not found at {README}, so the method's own role table cannot be read")

# Phases each contract OWNS: rows of its PHASE table, second column.
#
# Scoped to that table by heading, not "every table in the file". The comment here always
# said "leading phase table"; the code scanned every row in the contract, and passed only
# because no other table happened to carry a bare backticked token in column 2. 2.3.28 gave
# each contract a Load table whose column 2 IS such a token, and `untangle` — offered to two
# roles, owned by neither — read as a phase two contracts both owned (FAIL 2).
owned = {}          # phase -> [role, ...]
for role, text in roles.items():
    in_phase_table = False
    for line in text.splitlines():
        if line.startswith("#"):
            in_phase_table = bool(re.match(r"#+\s+Phases\b", line, re.I))
            continue
        if not in_phase_table:
            continue
        if not line.startswith("|") or line.startswith("|---"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2:
            continue
        m = re.fullmatch(r"`([a-z0-9:-]+)`", cells[1])
        if m:
            owned.setdefault(unqualify(m.group(1)), []).append(role)

for role, phases in sorted(method_rows.items()):
    for phase in phases:
        holders = owned.get(phase, [])
        if not holders:
            fail("1", f"method gives '{phase}' to {role}, no contract owns it",
                 "this is the prior package's failure exactly: a phase that will never run")
        elif role not in holders:
            fail("1", f"method gives '{phase}' to {role}, but {'/'.join(holders)} owns it")

# --- 2. CONTRACT -> UNIQUE --------------------------------------------------------------
for phase, holders in sorted(owned.items()):
    if len(holders) > 1:
        fail("2", f"'{phase}' is owned by {len(holders)} contracts: {', '.join(holders)}",
             "two roles both believing they own a phase is how it runs twice or not at all")

# --- 3. SKILL -> REACHED ----------------------------------------------------------------
reachers = {"contract " + r: t for r, t in roles.items()}
reachers.update({"skill " + n: t for n, (_, t) in skills.items()})
prompt_text = read(PROMPT)
if prompt_text:
    reachers["the adaptation prompt"] = prompt_text
# A project routes its own skills from its entry docs, and the harness's from contracts.
# Both are legitimate reachers, so read whichever exist.
for entry in ("AGENTS.md", "CLAUDE.md"):
    body = read(os.path.join(ROOT, entry))
    if body:
        reachers[entry] = body

for name in sorted(skills):
    found = [src for src, text in reachers.items()
             if src != "skill " + name and re.search(rf"`?\b{re.escape(name)}\b`?", text)]
    if not found:
        fail("3", f"skill '{name}' is reached by nothing",
             "name it in the contract of the role that uses it, or drop it")

# --- 4. REFERENCE -> EXISTS -------------------------------------------------------------
sources = {f"contract {r}": t for r, t in roles.items()}
sources.update({f"supplement {r}": t for r, t in role_supplements.items()})
sources.update({f"skill {n}": t for n, (_, t) in skills.items()})
# Project-owned skills are the project's to maintain; this checker verifies the harness.
# Payload documents that are neither a role nor a skill were scanned by nothing: the tracker
# contract and the orchestrator both name paths, and a wrong one there is as dead as a wrong
# one in a contract. Measured: tracker-contract.md prescribed `tools/project-status-sync.sh`,
# a directory this package does not have, while check 4 reported clean.
for _doc in ("tracker-contract.md", "orchestrator.md"):
    _p = os.path.join(PAYLOAD, ".agents", _doc)
    if os.path.isfile(_p):
        sources[f"document {_doc}"] = read(_p)

for src, text in sorted(sources.items()):
    # 4a. payload-relative paths
    # SCOPE, stated rather than implied. This matches PAYLOAD-SHAPED paths only. Widening it
    # to every backticked `a/b` token was tried and reverted: it fired on model ids
    # (`opencode-go/deepseek-v4-flash`), on placeholders (`provider/model`), on API fragments
    # and on the worked examples inside bootstrap-glossary — eleven findings, one real. A
    # checker that cries wolf is read past, which is the failure this package keeps paying for.
    # `tools` is in the list because a contract prescribed `tools/project-status-sync.sh`, a
    # directory this package does not have, and nothing saw it.
    for ref in sorted(set(re.findall(
            r"`((?:\.agents|\.claude|\.opencode|\.codex|scripts|tools|docs)/[A-Za-z0-9_./-]+)`", text))):
        if ref.endswith("/") or "<" in ref or ref.count("*"):
            continue
        # PROJECT-SIDE, by design: authored during adaptation, not shipped, so absence here is
        # correct. Named, not hidden in a regex — an unstated exclusion reads as a passed check.
        if ref.startswith(PROJECT_SIDE_PREFIXES):
            continue
        if payload_missing(ref):
            fail("4", f"{src} references {ref}, which does not exist in the payload")

    # 4a-bis. Script invocations inside fenced blocks. A path a contract tells someone to RUN
    # is not always backticked — the one that was wrong sat in a ```bash fence, where 4a has
    # never looked.
    for ref in sorted(set(re.findall(r"(?m)^\s*(?:bash\s+|sh\s+|python3\s+)?((?:scripts|tools)/[A-Za-z0-9_./-]+\.(?:sh|py))\b", text))):
        if payload_missing(ref):
            fail("4", f"{src} invokes {ref}, which does not exist in the payload")
    # 4b. skill-shaped tokens.
    #
    # NOT ON THE ORCHESTRATOR. That file is a CONFIG table whose values the project chooses:
    # `workspace-label` is a lowercase hyphenated name in backticks, which is character-for-
    # character the shape of a skill reference. Scanning it here fired on a project called
    # `legacy-proj` the moment it upgraded — AST-038's exact shape, a checker that cannot tell
    # project content from package content firing on every adopted repo. 4a still runs over it,
    # because a wrong PATH there is a real defect and paths are not ambiguous this way.
    if src == "document orchestrator.md":
        continue
    for tok in sorted(set(re.findall(r"`([a-z][a-z0-9:]*(?:-[a-z0-9]+)+)`", text))):
        tok = unqualify(tok)
        if tok in KNOWN or tok in NOT_A_SKILL:
            continue
        fail("4", f"{src} names '{tok}', which is neither a shipped skill nor a plugin skill",
             "a retired name, a typo, or this project's own vocabulary — declare it in "
             ".astraler/project/not-a-skill.txt (one token per line), which no release "
             "overwrites. Do NOT edit NOT_A_SKILL in this script: it is payload, so the next "
             "release overwrites your edit and you do it again (AST-132)")
    # 4c. launcher argv. `claude --agent X` resolves from .claude/agents/, and
    # `opencode --agent X` resolves from .opencode/agents/. Each runtime resolves from its
    # own directory ONLY, so a claude launcher naming an agent that exists only under
    # .opencode/ (or vice versa) will fail at dispatch with "agent not found".
    for m_agent in re.finditer(r"(claude|opencode)\s+--agent\s+([a-z][a-z0-9-]*)", text):
        runtime, agent = m_agent.group(1), m_agent.group(2)
        if agent.startswith("<"):
            continue
        adapter_dir = ".claude" if runtime == "claude" else ".opencode"
        if not os.path.exists(os.path.join(PAYLOAD, adapter_dir, "agents", f"{agent}.md")):
            fail("4", f"{src} launches `{runtime} --agent {agent}`, "
                      f"but {adapter_dir}/agents/{agent}.md does not exist in the payload",
                 f"{runtime} resolves the agent definition from {adapter_dir}/agents/; "
                 "an adapter in another runtime's directory does not help")
    for agent in sorted(set(re.findall(r"--agent ([a-z][a-z0-9-]*)", text))):
        if agent.startswith("<"):
            continue
        if re.search(rf"(claude|opencode)\s+--agent\s+{re.escape(agent)}", text):
            continue
        has_claude = os.path.exists(os.path.join(PAYLOAD, ".claude", "agents", f"{agent}.md"))
        has_opencode = os.path.exists(os.path.join(PAYLOAD, ".opencode", "agents", f"{agent}.md"))
        if not has_claude and not has_opencode:
            fail("4", f"{src} launches `--agent {agent}`, "
                      f"but neither .claude/agents/{agent}.md nor "
                      f".opencode/agents/{agent}.md exists in the payload",
                 "claude and opencode resolve the agent definition from the cwd; "
                 "this dispatch cannot start on either runtime")
    # `--profile <role>` is an address that CANNOT resolve from a repository. `codex --help`:
    # it layers `$CODEX_HOME/<name>.config.toml`, a machine-local path this payload cannot ship
    # and no adaptation writes since 2.12.0. A launcher written this way starts a pane with the
    # base user config and no role contract, and Codex reports nothing (AST-146).
    for prof in sorted(set(re.findall(r"--profile ([a-z][a-z0-9-]*)", text))):
        fail("4", f"{src} launches `--profile {prof}`, an address outside the repository",
             "codex --profile layers $CODEX_HOME/<name>.config.toml only; pass the role file "
             f'instead: -c developer_instructions="$(cat .codex/profiles/{prof}.md)"')
    # The address that replaced it must resolve like any other payload path. Literal citations
    # only; the launcher itself is written with a `<role>` placeholder, and a check keyed to
    # that string can never fire — which is how the first version of this shipped, silent.
    # The table-driven half below is the one that answers for the launcher.
    for prof in sorted(set(re.findall(r"\.codex/profiles/([a-z][a-z0-9-]*)\.md", text))):
        if not os.path.exists(os.path.join(PAYLOAD, ".codex", "profiles", f"{prof}.md")):
            fail("4", f"{src} launches with .codex/profiles/{prof}.md, "
                      "which is absent from the payload",
                 "the launcher would pass an empty developer_instructions and Codex would "
                 "accept it in silence")

# 4c. Every role the orchestrator puts on Codex — actively or as a fallback — must have the
# file its launcher cats. BOTH tables, because a fallback row is a launch path: it is the form
# the launcher takes on the day the active runtime is down, which is the worst moment to find
# out the role has no contract. The pane starts anyway: Codex accepts an empty
# `developer_instructions` in silence, so this cannot be left to be noticed at runtime.
_orch = read(os.path.join(PAYLOAD, ".agents", "orchestrator.md"))
for _m in re.finditer(r"^\|\s*([a-z][a-z0-9-]*)\s*\|\s*codex\s*\|", _orch, re.M):
    _role = _m.group(1)
    if not os.path.exists(os.path.join(PAYLOAD, ".codex", "profiles", f"{_role}.md")):
        fail("4", f"orchestrator.md puts {_role} on codex, but "
                  f".codex/profiles/{_role}.md is absent from the payload",
             "the launcher cats that file into developer_instructions; without it the pane "
             "starts with no role contract and Codex reports nothing")

# --- 5. ROLE -> STARTABLE ---------------------------------------------------------------
# Checks 1-4 verify that what exists is consistent. None of them asks the question that
# actually killed two capabilities: can this role be STARTED? A role needs two things — a
# written launcher, and a dispatcher whose contract names it. Missing either, it is correct,
# valuable and unreachable.
DISPATCHER = "thomas"      # the resident router is launched by the owner, not dispatched
launcher_text = "\n".join(t for _, t in skills.values())
dispatcher_text = roles.get(DISPATCHER, "")

for role in sorted(roles):
    if role == DISPATCHER:
        continue
    has_launcher = bool(re.search(rf"--(agent|profile)\s+{re.escape(role)}\b", launcher_text))
    named_by_dispatcher = bool(re.search(rf"\b{re.escape(role)}\b", dispatcher_text, re.I))
    if not has_launcher:
        fail("5", f"role '{role}' has no launcher in any shipped skill",
             f"nothing states how to start it; add it to dispatch-ticket's launcher matrix")
    if not named_by_dispatcher:
        fail("5", f"role '{role}' is never named by contract '{DISPATCHER}'",
             "the dispatcher's contract decides what gets dispatched; a role it does not "
             "name is a role that never runs, however correct its own contract is")

# --- 6. ADDRESS -> CALLABLE ---------------------------------------------------------------
# Two ways to reach a skill, and they are not interchangeable. A skill carrying
# `disable-model-invocation: true` is reachable ONLY as text arriving as a user turn, so a
# contract writes `/name`. Every other skill is reachable by the model, so a contract writes
# the Skill-tool form. Giving an agent the wrong one fails silently: it cannot invoke, and
# it substitutes its own work rather than reporting the gap.
#
# Claude Code ships two kinds of built-in and only one is a skill. `/compact` and `/clear`
# are CLI commands with no Skill-tool path at all, so their bare names ARE their addresses;
# `simplify` and friends are bundled skills the model can invoke. Conflating them is what
# produced AST-051, so they are separate sets here.
CLI_LOCAL = {"compact", "clear", "resume", "cost", "doctor", "help", "login", "logout",
             "status", "vim", "terminal-setup", "fast", "loop"}
BUILTIN_SKILL = {"simplify", "code-review", "verify", "commit", "pr", "commit-push-pr", "go",
                 "security-review", "init", "schedule", "update-config", "run"}

# A plugin skill's own frontmatter is the authority on which kind it is. Read it where the
# plugin is installed; fall back to the flow skills the method names, so a machine without
# the plugin still runs this check rather than passing it vacuously.
USERONLY_FALLBACK = {
    "wayfinder", "grill-with-docs", "to-spec", "to-tickets", "implement", "triage",
    "to-questionnaire", "ask-matt", "improve-codebase-architecture", "handoff", "teach",
    "grill-me", "wait-what", "setup-matt-pocock-skills",
}
def plugin_invocability():
    """({skill name: True if user-invoked only}, where that came from).

    The plugin nests its skills under <version>/skills/<category>/<name>/, and both those
    middle segments move between releases — so walk rather than spell the depth out.
    """
    out = {}
    for skill_md in glob.iglob(os.path.expanduser(
            "~/.claude/plugins/cache/*/mattpocock-skills/**/SKILL.md"), recursive=True):
        out[os.path.basename(os.path.dirname(skill_md))] = (
            "disable-model-invocation: true" in read(skill_md))
    if out:
        return out, f"plugin frontmatter ({len(out)} skills read)"
    return ({n: True for n in USERONLY_FALLBACK},
            "fallback list — plugin not installed, built-ins still checked")

INVOCABILITY, ADDR_SOURCE = plugin_invocability()

def user_only(name):
    """True = only a typed user turn reaches it. None = not a skill we can classify."""
    if name in CLI_LOCAL:
        return True
    if name in INVOCABILITY:
        return INVOCABILITY[name]
    if name in BUILTIN_SKILL:
        return False
    return None

# A `/name` occurrence only counts where a slash follows a backtick or opens a line inside a
# fenced block. Matching a bare slash anywhere hits every path in the payload — the sweep
# that corrupted three references the last time it was tried (AST-047).
SLASH = re.compile(r"(?:`|^)/((?:[a-z0-9-]+:)?[a-z][a-z0-9-]{2,})", re.M)
SKILLCALL = re.compile(r"""Skill\(\s*skill\s*[:=]\s*["']([a-z][a-z0-9:-]{2,})["']""")
ADDR_OK = "<!-- addr-ok"

addr_sources = {os.path.join(ROLES_DIR, f"{n}.md"): t for n, t in roles.items()}
addr_sources.update({os.path.join(ROLES_DIR, f"{n}.md"): t for n, t in role_supplements.items()})
addr_sources.update({p: t for p, t in skills.values()})

for path, text in sorted(addr_sources.items()):
    for lineno, line in enumerate(text.splitlines(), 1):
        if ADDR_OK in line:
            continue
        for name in SLASH.findall(line):
            bare = unqualify(name)
            # A plugin command typed bare resolves only while nothing else claims the word.
            # 1.4.1 qualified every one of them by hand; this is what keeps them qualified.
            if bare in INVOCABILITY and bare == name:
                fail("6", f"{os.path.basename(path)}:{lineno} writes `/{name}` unqualified",
                     f"a plugin command needs its plugin: `/mattpocock-skills:{name}`, since "
                     f"a bare name resolves only until something else claims it (AST-050)")
            if user_only(bare) is False:
                fail("6", f"{os.path.basename(path)}:{lineno} addresses `{bare}` as "
                          f"`/{name}`, but the model can invoke it",
                     f"an agent has no keyboard: write `Skill(skill: \"{bare}\")`, or mark "
                     f"the line `{ADDR_OK}: ... -->` if it names the skill without invoking it")
        for name in SKILLCALL.findall(line):
            bare = unqualify(name)
            if user_only(bare) is True:
                fail("6", f"{os.path.basename(path)}:{lineno} calls `{bare}` through the "
                          f"Skill tool, but it is user-invoked only",
                     "the call fails and the agent substitutes its own work: write "
                     f"`/{name}` and arrange for it to arrive as a user turn")

# --- 7. ARTIFACT -> PRODUCED AND VERIFIED -------------------------------------------------
# A gate is only as real as the artifact it reads. Two ways it goes quiet, and both have
# happened here: the producer stops producing (AST-051 — a Builder handed an unusable
# address rolled its own pass and left no marker), or the verifier never held the rule in
# the first place (the marker check lived in `dispatch-ticket`, read at dispatch, while the
# check must happen at handback — so Thomas's own contract never carried it).
#
# Each artifact needs BOTH halves named in the contracts that own them. Naming it in a
# skill is not enough: a skill is read when invoked, a contract every time the role starts.
#
# The registry is explicit and that is this check's honest limit — it catches a half that
# goes missing, not an artifact nobody ever registered. A new gate needs a line here, and
# `simplify(increment):` is in the ledger precisely because it had no line.
# Where each half must live is a judgement, so the registry records it rather than deriving
# it. A contract is loaded every time its role starts; a skill is read only when invoked. So
# a check that fires long after its dispatch belongs in the CONTRACT — that is exactly what
# the marker got wrong. A check that fires inside the skill's own run may live in the SKILL.
ARTIFACTS = [
    # (artifact, regex, producer, verifiers — each a role contract or a shipped skill)
    ("simplify(increment): marker", r"simplify\(increment\)", "builder", ["thomas", "rin"]),
    # The marker's subject proves a commit happened, never which pass wrote it. A Builder
    # whose invocation errored substituted another tool, committed the same subject, and
    # every check downstream read as satisfied (AST-055). The `Pass:` line in the body is
    # the half that can disagree with a substitute, so it needs its own producer/verifier
    # row — a second artifact, not a detail of the first.
    ("simplify pass provenance", r"`Pass:`|Pass: Skill\(", "builder", ["thomas", "rin"]),
    ("browser evidence",            r"browser evidence",      "builder", ["rin"]),
    ("gate file",                   r"GATE_FILE",             "rin",     ["review-with-rin"]),
    ("ledger line",                 r"`Ledger:`",             "thomas",  ["rin"]),
    # The dispatch record was named as durable state by `thomas.md` and defined by nothing —
    # no path, no shape, no owner — while four rules read it: the write-set overlap check,
    # cleanup's exact IDs, a later session finishing a dispatch, and the Builder identity on
    # every tracker whose assignee cannot hold one. Registered so a producer that goes quiet
    # fails here rather than at the next collision.
    ("dispatch record",             r"\.astraler/state/dispatch-record\.json|dispatch record",
                                                              "dispatch-ticket", ["thomas"]),
    # A walk that never ran and a walk that found nothing are the same silence downstream.
    # Registering both halves means a producer going quiet fails here (AST-045/057/135).
    ("qa walk report",              r"\.astraler/state/gate-history/walk-<artifact-key>-<short-sha>\.md|walk report|COVERAGE GAPS",
                                                              "dispatch-qa-walk", ["thomas"]),
    ("qa verified-clean list",      r"qa-verified-clean\.md|verified-clean",
                                                              "qa",              ["dispatch-qa-walk"]),
    # `untangle` wrote to "where this project keeps its architecture notes" — no path, no
    # reader, invisible to check 8 precisely because it had no path (the AST-071 shape).
    ("untangle boundaries",         r"docs/agents/boundaries\.md|boundaries this pass",
                                                              "untangle",        ["shaper"]),
    # The review state was invisible to every reader of GLOSSARY.md, including nine plugin
    # skills that load it. It now has its own file, and a named reader: the owner, via Thomas.
    ("glossary review state",       r"docs/agents/GLOSSARY-review\.md|UNREVIEWED",
                                                              "bootstrap-glossary", ["thomas"]),
    # A produced DOCUMENT is an artifact too, and this row is the one that survived the
    # 1.6.1 cull: three sibling skills wrote files that no contract and no plugin skill was
    # told to read, and every check here went green because each was NAMED. `GLOSSARY.md`
    # differs by being read — by the plugin, not by us — so its verifier is a plugin skill
    # and is checked against the installed copy when there is one.
    ("GLOSSARY.md",                 r"GLOSSARY\.md",          "bootstrap-glossary",
                                                              ["plugin:domain-modeling"]),
    # The frontier write-back has no commit to grep — its artifact is tracker state, which
    # this script cannot see. So the registry binds the two halves that ARE readable: the
    # role that must do it at merge, and the audit that finds the merges where it did not
    # happen. Naming a skill in a contract clears check 3 and makes nothing run; this is
    # what keeps the backstop attached to a moment instead of to someone noticing (AST-057).
]
PLUGIN_UNREAD = []
def holder(name):
    """Text of a role contract (including supplements), a shipped skill, or an installed plugin skill."""
    if name in roles:
        # Merge the base contract with all its runtime supplements so artifact checks
        # see the full text across base + supplements.
        merged = roles[name]
        for sn, st in role_supplements.items():
            if sn.startswith(name + "-"):
                merged += "\n" + st
        return merged, "contract"
    if name in skills:
        return skills[name][1], "skill"
    if name.startswith("plugin:"):
        # A verifier outside this payload. Read the installed copy when present; when it is
        # absent say so in the verdict rather than passing — an unreadable verifier is an
        # unverified one, and this axis exists because green lines outran their evidence.
        bare = name.split(":", 1)[1]
        for pat in (f"~/.claude/plugins/cache/*/*/*/skills/*/{bare}/SKILL.md",
                    f"~/.claude/plugins/cache/*/*/skills/*/{bare}/SKILL.md"):
            hits = glob.glob(os.path.expanduser(pat))
            if hits:
                return read(hits[0]), "plugin skill"
        PLUGIN_UNREAD.append(bare)
        return "", "plugin skill (not installed)"
    return None, None

for label, pattern, producer, verifiers in ARTIFACTS:
    rx = re.compile(pattern, re.I)
    for who, part in [(producer, "producer")] + [(v, "verifier") for v in verifiers]:
        text, kind = holder(who)
        if text is None:
            fail("7", f"'{label}' names {part} '{who}', which is neither a contract nor a "
                      f"shipped skill", "the registry in this script has gone stale")
        elif kind == "plugin skill (not installed)":
            pass   # named in the verdict's scope line instead of silently passing
        elif not rx.search(text):
            fail("7", f"'{label}': {kind} '{who}' is its {part} and never names it",
                 "a gate whose producer went quiet cannot fail, and a verifier that does "
                 "not carry the rule will not apply it")

# --- 8. WRITES -> REGISTERED --------------------------------------------------------------
# Checks 1-7 all ask whether a thing is NAMED. None asked the question that cost this package
# three skills: a skill wrote a document, and nobody was ever told to read it. 1.6.1 removed
# `extract-standards`, `module-boundaries` and `code-scout` for exactly that, and the owner
# found all three by hand because every check was green.
#
# So: a skill that declares it WRITES a path must appear in the ARTIFACTS registry above,
# where a human states who reads it. This does not verify the reader — check 7 does that for
# rows whose readers are readable. It verifies that no writer escapes the registry unnoticed.
#
# SCOPE, stated because this axis is about overclaiming: it reads `## N. Write \`path\``
# headings only. A skill that writes without that heading, or one whose consumer names the
# artifact in prose rather than by path, is invisible here — `batch-triage` asked for "the
# code map" in words for weeks and a filename grep called it an orphan (AST-069's shape).
WRITE_RX = re.compile(r"^#{2,3} *[0-9]*\.? *Write +`([^`]+)`", re.M)
REGISTERED = " ".join(f"{a[0]} {a[1]}" for a in ARTIFACTS)
writes_seen = 0
for sname in sorted(skills):
    for m in WRITE_RX.finditer(skills[sname][1]):
        art = m.group(1)
        writes_seen += 1
        if art.replace(".", "\\.") not in REGISTERED and art not in REGISTERED:
            fail("8", f"skill '{sname}' writes '{art}', which no ARTIFACTS row covers",
                 "a document with a producer and no named reader is the defect 1.6.1 "
                 "removed three skills for; add a row naming who reads it, or stop writing it")

# --- 9. SHIPPED -> CALLED ------------------------------------------------------------------
# The owner's acceptance rule (2026-09-03): a tool nobody calls does not exist, and enriching it
# is meaningless. "Called" means named from one of the surfaces that actually reach a session —
# session context (a role contract, a skill and its companion files, a subagent definition on
# any runtime, the orchestrator, the tracker contract, a prompt, the README), a runtime hook,
# the installer, or transitively a script one of those calls.
# Measured before this axis existed: `reap-worktree-processes.sh` shipped four releases with no
# call site at all, while the hook that fired at the right moment ran a hardcoded docker line
# instead. Every check above asks whether a SKILL is reachable; none asked it of a SCRIPT.
#
# Package layout only: in an adapted project `scripts/` also holds the project's own tooling,
# wired in ways this payload cannot see, and flagging those would be exactly the over-claim
# check 8's scope note warns about.
#
# TWO THINGS THIS CHECK GOT WRONG UNTIL 2.10.0, AND THEY FAIL IN OPPOSITE DIRECTIONS. Both were
# found by two agents auditing one downstream repo and disagreeing three times about how many of
# its tools were wired: substring-with-a-narrow-surface said 6 of 22, substring-with-plugs said
# 19, mention-filtering-with-a-narrow-surface said 13. The spread was the finding; no one of the
# numbers was. So this check now pins BOTH halves, because fixing either alone turns a
# false-clean into a false-alarm rather than into an answer.
#
#   TOO NARROW — the surface set. It listed the two hook registration files and stopped, while
#   its own failure message named "a VCS hook" as a valid call site and no git-hook directory
#   was ever read. It also never looked at `.astraler/project/`, which is where an adapted
#   project is TOLD to put enforcement, precisely because `scripts/` is payload a release
#   overwrites. A check that cannot see the place the method sends you scores every project
#   that followed the method as an orphan farm.
#
#   TOO WIDE — a name is not a call. A tool named in a comment, or inside a string a script
#   PRINTS as advice, is documentation. Measured downstream: one tool appeared three times
#   inside another script — two comments and one `note "... (reap with tools/X if ...)"` — and
#   a substring test read that as a call site. Worse, one of those comments said the logic was
#   "reimplemented near-identically" in the other file, so the co-occurrence was evidence of
#   DUPLICATION being read as evidence of wiring.
#
# The distinction is applied where it belongs and nowhere else. A CONTEXT surface — a contract,
# a skill, the README — legitimately reaches a session by being read, so a script named there is
# reachable by mention: that is the whole mechanism. An EXECUTION surface (a hook file, a plug,
# a git hook, the installer) and a script-to-script edge both claim the thing is RUN, and there
# a mention proves nothing.
COMMENT_LINE = re.compile(r"^\s*(#|//)")
PRINTS_PROSE = re.compile(r"^\s*(note|echo|printf|warn|info|say|die|cat)\b")


def executable_text(text):
    """`text` with the lines that can only document, not run, removed.

    Deliberately crude and deliberately conservative: it drops whole lines rather than parsing
    shell, so a real call sharing a line with an echo survives. Over-keeping is the safe error
    — it can only leave this check as permissive as it was before 2.10.0, never stricter than
    the evidence supports."""
    keep = []
    for line in text.splitlines():
        if COMMENT_LINE.match(line) or PRINTS_PROSE.match(line):
            continue
        keep.append(line)
    return "\n".join(keep)


scripts_seen = 0
pkg_root = os.path.normpath(os.path.join(PAYLOAD, ".."))
if LAYOUT != "project":
    script_files = sorted(glob.glob(os.path.join(PAYLOAD, "scripts", "*.sh")) +
                          glob.glob(os.path.join(PAYLOAD, "scripts", "*.py")))
else:
    # In a project, `scripts/` also holds the project's own tooling, wired in ways this payload
    # cannot see — flagging those would be the over-claim check 8's scope note warns about. So
    # the set under test is exactly the scripts THIS PACKAGE SHIPPED, read from the newest
    # staged release beside the project. That is knowable without the package, and it is the
    # set an upgrade is answerable for.
    staged = sorted(glob.glob(os.path.join(ROOT, ".astraler", "releases", "*", "harness",
                                           "scripts", "*")))
    shipped_names = {os.path.basename(p) for p in staged
                     if p.endswith(".sh") or p.endswith(".py")}
    # PACKAGE-ONLY tools are run by the package (install.sh runs selftest.sh as its staging
    # gate) and have no call site in a project by design; in a project they are not under
    # test. Named here rather than hidden: a tool on this list that gains a project call site
    # comes off it. Measured downstream: selftest.sh "passed" only through a substring match on
    # project prose, then failed the moment that prose was restored to the payload's text.
    PACKAGE_ONLY = {"selftest.sh"}
    script_files = [os.path.join(PAYLOAD, "scripts", n)
                    for n in sorted(shipped_names - PACKAGE_ONLY)
                    if os.path.isfile(os.path.join(PAYLOAD, "scripts", n))]

if script_files:
    scripts_txt = {os.path.basename(q): read(q) for q in script_files}
    scripts_seen = len(scripts_txt)
    context_surfaces, exec_surfaces = {}, {}
    for q in (glob.glob(os.path.join(PAYLOAD, ".agents", "roles", "*.md")) +
              glob.glob(os.path.join(PAYLOAD, ".agents", "skills", "*", "*.md")) +
              glob.glob(os.path.join(PAYLOAD, ".claude", "skills", "*", "*.md")) +
              [os.path.join(PAYLOAD, ".agents", "orchestrator.md"),
               os.path.join(PAYLOAD, ".agents", "tracker-contract.md")] +
              glob.glob(os.path.join(pkg_root, "prompts", "*.md")) +
              [os.path.join(pkg_root, "README.md")] +
              ([os.path.join(ROOT, "AGENTS.md"), os.path.join(ROOT, "CLAUDE.md")]
               if LAYOUT == "project" else [])):
        if os.path.isfile(q):
            context_surfaces["context " + os.path.relpath(q, pkg_root)] = read(q)
    # A shipped mod's hooks module runs scripts the way a hook does (ledger-rules.py from
    # register.tsx); it is an execution surface, and until 2.20.1 it was not read, so a script
    # called only from the mod scored as an orphan (found downstream on a pristine payload).
    exec_paths = ([os.path.join(PAYLOAD, ".claude", "settings.json"),
                   os.path.join(PAYLOAD, ".codex", "hooks.json")] +
                  glob.glob(os.path.join(PAYLOAD, ".claude", "skills", "*", "hooks", "*.ts")) +
                  glob.glob(os.path.join(PAYLOAD, ".claude", "skills", "*", "hooks", "*.tsx")) +
                  glob.glob(os.path.join(PAYLOAD, ".claude", "agents", "*")) +
                  glob.glob(os.path.join(PAYLOAD, ".codex", "agents", "*")) +
                  glob.glob(os.path.join(PAYLOAD, ".opencode", "agents", "*")) +
                  [os.path.join(pkg_root, "install.sh")])
    if LAYOUT == "project":
        # Where an adapted project is told to put enforcement, plus every VCS hook this
        # repository actually uses — `core.hooksPath` first, since a project that sets it has
        # made `.git/hooks` dead, and `.githooks/` by convention.
        exec_paths += glob.glob(os.path.join(ROOT, ".astraler", "project", "*"))
        exec_paths += glob.glob(os.path.join(ROOT, ".githooks", "*"))
        exec_paths += glob.glob(os.path.join(ROOT, ".github", "workflows", "*"))
        exec_paths += [os.path.join(ROOT, "Makefile")]
        try:
            hp = subprocess.run(["git", "-C", ROOT, "config", "core.hooksPath"],
                                capture_output=True, text=True, timeout=5)
            if hp.returncode == 0 and hp.stdout.strip():
                hd = hp.stdout.strip()
                if not os.path.isabs(hd):
                    hd = os.path.join(ROOT, hd)
                exec_paths += glob.glob(os.path.join(hd, "*"))
        except Exception:
            pass
    for q in exec_paths:
        if os.path.isfile(q):
            rel = os.path.relpath(q, pkg_root)
            body = read(q)
            # A JSON hook registration has no shell comments and its whole content is the
            # command; stripping prose lines there would only lose signal.
            exec_surfaces["exec " + rel] = body if q.endswith(".json") else executable_text(body)

    wired = {}
    for name in scripts_txt:
        for label, text in list(context_surfaces.items()) + list(exec_surfaces.items()):
            if name in text:
                wired[name] = label
                break
    grew = True
    while grew:                      # transitive: called by a script that is itself called
        grew = False
        for name in scripts_txt:
            if name in wired:
                continue
            for w in list(wired):
                # `executable_text`, not the raw body: a script that merely MENTIONS another in
                # a comment has not called it, and reading that as a call is how an orphan
                # scored as wired.
                if w != name and w in scripts_txt and name in executable_text(scripts_txt[w]):
                    wired[name] = f"script {w} (itself via {wired[w]})"
                    grew = True
                    break
    for name in scripts_txt:
        if name not in wired:
            fail("9", f"scripts/{name} is shipped and nothing calls it",
                 "name its call site — a role contract, a skill, a runtime hook, a project "
                 "plug under .astraler/project/, a VCS hook, the installer, or a script one of "
                 "those calls — in the same commit, or delete it: an orphan is not improved by "
                 "being documented (2.7.15). A mention in a comment or in a printed string is "
                 "documentation, and this check no longer accepts one as a call site")
# --- 10. LEDGER ASSERTION -> STILL TRUE ---------------------------------------------------
# The ledger's narrative is about the PAST and must stay that way: an entry naming a role file
# from a generation that has been renamed away is history told correctly, and "fixing" it would
# falsify the record. But some lines in it are not narrative. `Bound:` names where a rule is
# enforced RIGHT NOW, and `Wired`/`Enforced by` make the same claim about a tool. Those are
# present-tense assertions, and a present-tense assertion that is no longer true is worse than
# silence, because it closes the question: a reader who sees `Bound:` stops looking for the
# enforcement, and a reader who sees "Wired" stops asking whether anything calls it.
#
# Both halves were measured on one downstream repo on 2026-09-16: `Bound:` pointing at three
# `.claude/rules/*.md` files that existed nowhere in the tree, and a ledger line reading
# "Wired 2026-08-29" about a tool with no call site anywhere. Check 4 reported clean over both,
# and said so in its own scope line rather than growing to cover them — a rot entry converted
# into a footnote. This check is that footnote being paid off.
#
# SCOPE, stated because it is the part that decides the verdict: only the assertion labels are
# read, never prose. A path under a project-authored prefix is checked in a project and skipped
# here, because the package genuinely does not ship one. Everything else must resolve.
# WHICH LEDGERS. The payload's own, always. And in a project, every other `.md` in the memory
# directory — because the project's ledger is named in its entry doc rather than at a fixed
# path, and the measurement that produced this check came from exactly such a file: a line
# reading `"Wired 2026-08-29"` about a tool with no call site, in a project-owned ledger of
# 11,000 lines. A check that read only the payload ledger would have missed the finding it
# exists for. `INDEX.md` and `RULES.md` are generated FROM a ledger, so scanning them would
# report every citation twice.
_GENERATED = {"INDEX.md", "RULES.md"}
LEDGERS = [os.path.join(PAYLOAD, ".agents", "memory", "recurring-failure-modes.md")]
if LAYOUT == "project":
    LEDGERS += [q for q in sorted(glob.glob(os.path.join(ROOT, ".agents", "memory", "*.md")))
                if os.path.basename(q) not in _GENERATED and q not in LEDGERS]
# A citation resolves if the file exists ANYWHERE in the tree under test, because the same
# payload is read in three layouts and the prefix differs in each: `harness/x` in the package,
# `x` in an adapted project, and a staged release FLATTENS `prompts/` to its root — so a
# `Bound:` line naming `prompts/ADAPT-HARNESS.md` is correct and still fails a prefix match
# there. What this check is for is a file that exists nowhere.
#
# The skip list is anchored to the tree under test rather than matched as a substring. A bare
# `"releases" in path` test was excluding EVERY file when the tree under test was itself a
# staged release — the check then reported the whole ledger as rot, and the installer refused
# to ship. Measured 2026-09-16; the case that caught it is `staged installer` in selftest.sh.
_SKIP_ROOTS = tuple(os.path.normpath(os.path.join(pkg_root, d)) for d in (
    "node_modules", ".git", "dist", os.path.join(".astraler", "releases"), "site"))
PAYLOAD_BASENAMES = set()
for _base, _dirs, _files in os.walk(pkg_root):
    _n = os.path.normpath(_base)
    if any(_n == r or _n.startswith(r + os.sep) for r in _SKIP_ROOTS):
        _dirs[:] = []
        continue
    _dirs[:] = [d for d in _dirs if d not in ("node_modules", ".git")]
    PAYLOAD_BASENAMES.update(_files)
ASSERTS = re.compile(r"(?:^|\s)(Bound:|Wired\b|Enforced by:?)", re.M)
# `*` IS IN THE CLASS BECAUSE ITS ABSENCE EXCUSED A WHOLE CITATION SHAPE. The pattern requires
# both backticks, so `harness/.codex/profiles/*.config.toml` matched nothing at all: not a
# resolved binding, not a finding, not even a counted assertion. Two entries carried that shape
# while the files behind it were renamed out of the payload, and check 10 — the check whose one
# job is that a `Bound:` line is true NOW — stayed green over both. Measured by planting the
# same citation twice, once with a literal name and once with a star: the first failed, the
# second was invisible (AST-147).
CITED_PATH = re.compile(r"`([A-Za-z0-9_.][A-Za-z0-9_./*-]*\.(?:md|sh|py|json|toml))`")
ledger_asserts = 0
for _ledger in LEDGERS:
    if not os.path.isfile(_ledger):
        continue
    _rel = os.path.relpath(_ledger, ROOT)
    lines = read(_ledger).splitlines()
    for i, line in enumerate(lines):
        if not ASSERTS.search(line):
            continue
        # An assertion may wrap; take the line and any continuation up to the next blank.
        block = [line]
        j = i + 1
        while j < len(lines) and lines[j].strip() and not ASSERTS.search(lines[j]):
            block.append(lines[j])
            j += 1
            if len(block) > 6:      # a paragraph is prose, not a citation list
                break
        blob = "\n".join(block)
        # An explicitly retired binding. The ledger's entries are about the past, and a file
        # named by one can be legitimately gone; what must not happen is the claim staying in
        # the present tense. `(gone)` is the retirement, written at the citation rather than
        # on the entry, so a line that binds one live file and one dead one keeps the live
        # half under this check instead of being excused wholesale.
        retired = {m.group(1) for m in re.finditer(CITED_PATH.pattern + r"\s*\(gone\)", blob)}
        for ref in CITED_PATH.findall(blob):
            if ref in retired:
                continue
            ledger_asserts += 1
            # `AGENTS.md` and `CLAUDE.md` are the project's entry docs: the harness binds
            # rules to them and ships neither, exactly like docs/agents/.
            if (ref.startswith(PROJECT_SIDE_PREFIXES)
                    or ref in ("AGENTS.md", "CLAUDE.md")) and LAYOUT != "project":
                continue
            stripped = ref[len("harness/"):] if ref.startswith("harness/") else ref
            if "*" in ref:
                # A glob binds a SET. It is live while the set is non-empty and rot the moment
                # it is empty, which is what a renamed-away file leaves behind.
                if any(glob.glob(os.path.join(base, cand))
                       for base in (ROOT, PAYLOAD, pkg_root)
                       for cand in (ref, stripped)):
                    continue
                fail("10", f"the ledger asserts a live binding to {ref}, which matches no file",
                     "a globbed `Bound:` is a claim that the SET is non-empty. Repoint it or "
                     f"mark it `(gone)` ({_rel} line {i + 1})")
                continue
            if any(os.path.exists(os.path.join(base, cand))
                   for base in (ROOT, PAYLOAD, pkg_root)
                   for cand in (ref, stripped)):
                continue
            # A `Bound:` list writes the directory once and then shorthand —
            # `.agents/roles/thomas.md, builder.md, rin.md` — and a skill is cited as
            # `codex-arm/SKILL.md` wherever it lives. Neither is a rot claim, and failing them
            # would bury the two findings that are real under thirty that are not. What this
            # check is for is a file that exists NOWHERE, so resolve by basename before
            # calling it gone.
            base = os.path.basename(ref)
            if base == "SKILL.md":
                # Every skill file is named SKILL.md, so a basename match would excuse any
                # citation at all. The distinctive part is the directory.
                if os.path.basename(os.path.dirname(ref)) in all_skills:
                    continue
            elif base not in ("README.md", "AGENTS.md", "CLAUDE.md") and base in PAYLOAD_BASENAMES:
                continue
            fail("10", f"the ledger asserts a live binding to {ref}, which does not exist",
                 "`Bound:`/`Wired`/`Enforced by` are claims about the PRESENT. Repoint it at "
                 "the file that carries the rule today, or say plainly that the binding is "
                 "gone — narrative about the past stays as it is, an assertion about now does "
                 f"not ({_rel} line {i + 1})")

# --- 11. RUNTIME REASSIGNMENT -> RULES FOLLOW ---------------------------------------------
# 2.9.0's rule: anything the payload ships for a role or a moment is declared for EVERY runtime
# that can carry it. This check is that rule pointed at the one surface the package cannot see
# from inside itself — the project's always-on tier.
#
# The trap it exists for, measured downstream on 2026-09-16: a project with six rules in
# `.claude/rules/`, five of them named in no Codex profile and no OpenCode adapter, and all five
# roles currently assigned to `claude` — so nothing was leaking and nothing was red. It is a
# loaded trap rather than a live wound: the day the owner edits one runtime cell in
# `orchestrator.md`, five always-on rules stop reaching the agent, silently, and the only
# signal is behaviour nobody attributes to a config edit weeks earlier.
#
# Package layout ships no `.claude/rules/`, so this is a project-layout check by construction,
# and it says so rather than passing quietly.
rules_checked = 0
if LAYOUT == "project":
    ADAPTER_FOR = {
        "codex": os.path.join(ROOT, ".codex", "profiles", "%s.md"),
        "opencode": os.path.join(ROOT, ".opencode", "agents", "%s.md"),
        "claude": os.path.join(ROOT, ".claude", "agents", "%s.md"),
    }
    orch = read(os.path.join(ROOT, ".agents", "orchestrator.md"))
    # ONLY the Active assignments table. The file also carries a Fallback providers table, and
    # a fallback is a per-session degradation the orchestrator says is "never written back into
    # this file" — reading it as an assignment reports every role as running on a runtime it is
    # not on. Found by this check's own fixture, which is the only reason it is not shipping
    # that way.
    sect = re.search(r"^##\s*Active assignments\s*$(.*?)(?=^##\s|\Z)", orch, re.M | re.S)
    assigned = {}
    if sect:
        for m in re.finditer(r"^\|\s*([a-z][a-z0-9-]*)\s*\|\s*(claude|codex|opencode)\s*\|",
                             sect.group(1), re.M):
            assigned[m.group(1)] = m.group(2)
    rule_files = sorted(glob.glob(os.path.join(ROOT, ".claude", "rules", "*.md")))
    for rf in rule_files:
        stem = os.path.basename(rf)[:-3]
        for role, runtime in sorted(assigned.items()):
            # Claude reads `.claude/rules/` itself; no adapter has to repeat it.
            if runtime == "claude":
                continue
            adapter = ADAPTER_FOR[runtime] % role
            rules_checked += 1
            if stem not in read(adapter):
                fail("11", f"role '{role}' runs on {runtime}, which never sees "
                           f".claude/rules/{stem}.md",
                     f"`.claude/rules/` is read by Claude and by nothing else. Carry the rule "
                     f"into {os.path.relpath(adapter, ROOT)} in the same wording, or name this "
                     f"role an exception with the reason — a surface that is silent is not an "
                     f"exception, it is an omission wearing one (AST-138)")

# --- report -----------------------------------------------------------------------------
print(f"Reachability check — {LAYOUT} layout, payload at {os.path.normpath(PAYLOAD)}")
print(f"  {len(roles)} contracts · {len(skills)} harness skills · "
      f"{len(owned)} owned phases · {len(PLUGIN)} plugin skills known")
if LAYOUT == "project":
    print(f"  ownership from: {ATTRIBUTION}")
print(f"  invocability from: {ADDR_SOURCE}")
print()
if not findings:
    print("  [OK] 1 every phase the method names is owned by the contract it names")
    print("  [OK] 2 every declared phase is declared exactly once")
    print("  [OK] 3 every HARNESS skill is NAMED by something — which is not evidence any of"
          " them has ever run" +
          (f" ({len(PROJECT_OWNED)} project-owned skill(s) not examined)" if PROJECT_OWNED else ""))
    print("  [OK] 4 every path and skill referenced BY THE SCANNED FILES exists")
    print("  [OK] 5 every role has a launcher and a dispatcher that names it")
    print("  [OK] 6 every skill is addressed in the form its caller can actually use")
    print("  [OK] 7 every gate artifact has both a producer and a verifier")
    print(f"  [OK] 8 every document a skill declares it writes is in the artifact registry"
          f" ({writes_seen} write heading(s) read)")
    if scripts_seen:
        print(f"  [OK] 9 every shipped script is called from session context, a skill, a runtime"
              f" hook, a project plug, a VCS hook, the installer, or a wired script"
              f" ({scripts_seen} scripts, 0 orphans"
              + (", payload-shipped only" if LAYOUT == "project" else "") + ")")
    else:
        print("  [--] 9 shipped-script call sites: no staged release under .astraler/releases/,"
              " so the payload-shipped set cannot be named and nothing was scored")
    print(f"  [OK] 10 every live `Bound:`/`Wired`/`Enforced by` in the ledger still resolves"
          f" ({ledger_asserts} assertion citation(s) read; `(gone)` marks a retired one)")
    if LAYOUT == "project":
        print(f"  [OK] 11 every always-on rule reaches the runtime each role is assigned to"
              f" ({rules_checked} rule/role pair(s) off Claude)")
    else:
        print("  [--] 11 always-on rules vs assigned runtimes: this package ships no"
              " .claude/rules/ tier; the check runs where that tier exists")
    if PLUGIN_UNREAD:
        print("  verifier(s) outside this payload and NOT read this run: "
              + ", ".join(sorted(set(PLUGIN_UNREAD)))
              + " — install the plugin to check them")
    print(f"\nAll reachability checks passed. Scope: {len(roles)} contracts, "
          f"{len(skills)} skills, the tracker contract, the orchestrator, "
          f"the adaptation prompt and the README role table.")
    # Named in the verdict rather than left to the regex. Paths under these prefixes are
    # authored by the project during adaptation; their absence HERE is correct, and
    # check-requirements.sh is what answers for them in an adapted repo.
    print("  Not checked, by design: " + ", ".join(PROJECT_SIDE_PREFIXES)
          + " — project-authored, verified by check-requirements.sh instead.")
    if PROJECT_OWNED:
        # Named inside the verdict, not above it. A project skill this run never opened is
        # exactly what a reader takes the green to cover, and a new skill lands here on the
        # run right after it is written — which is when someone is looking for reassurance.
        print(f"Not examined, and no check above speaks for them: "
              f"{len(PROJECT_OWNED)} project-owned skill(s) — "
              f"{', '.join(sorted(PROJECT_OWNED))}.")
    print("Check 10 now covers what this scope line used to excuse: the ledger's `Bound:` "
          "provenance went unscanned for four releases while a live project carried five "
          "citations to a deleted file and check 4 reported clean. A rot entry written up as "
          "a footnote is still a rot entry. What check 10 still cannot do is tell a binding "
          "that RESOLVES from the right one — it reads existence, not correctness.")
    sys.exit(0)

for check, msg, detail in findings:
    print(f"  [FAIL {check}] {msg}")
    if detail:
        print(f"            → {detail}")
print(f"\n{len(findings)} finding(s). A phase or skill nothing reaches will not run.")
sys.exit(1)
