#!/usr/bin/env python3
"""check-reachability.sh — does the method the docs describe actually exist?

The prior package lost two weeks to an Align phase that lived in a method document and in
no role's contract, so nothing ever ran it. Every check here exists to make that class of
gap fail loudly instead of quietly.

Eight checks, in both directions:

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

Runs against this package (payload under harness/) or an adapted project (payload at the
repo root). Exit 0 = every check passed, 1 = at least one finding.
"""
import os
import re
import sys
import json
import glob

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
    "resolving-merge-conflicts", "improve-codebase-architecture",
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
# A name is resolvable when anything on this machine actually provides it.
KNOWN = set(all_skills) | PLUGIN | USER_SKILLS

# Kebab-case tokens that are vocabulary rather than skill references. Each is here because
# it appears in backticks and looks like a skill name; the list stays short on purpose,
# because a long one would mean this check has stopped discriminating.
NOT_A_SKILL = {
    # Vocabulary from the two payload documents added to `sources`: the projects the tracker
    # contract cites as its evidence base, and an orchestrator config key. Skill-shaped, and
    # none of them is a skill.
    "etsy-fulfillment-thanh", "workspace-app-inception", "builder-target",
    # Triage labels. Skill-shaped, and the vocabulary lives in docs/agents/triage-labels.md.
    "needs-triage", "ready-for-agent",
    # A project make target, cited as the AST-115 example.
    "db-down",

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
    "builder-tra-123",
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
        if not os.path.exists(os.path.join(PAYLOAD, ref)):
            fail("4", f"{src} references {ref}, which does not exist in the payload")

    # 4a-bis. Script invocations inside fenced blocks. A path a contract tells someone to RUN
    # is not always backticked — the one that was wrong sat in a ```bash fence, where 4a has
    # never looked.
    for ref in sorted(set(re.findall(r"(?m)^\s*(?:bash\s+|sh\s+|python3\s+)?((?:scripts|tools)/[A-Za-z0-9_./-]+\.(?:sh|py))\b", text))):
        if not os.path.exists(os.path.join(PAYLOAD, ref)):
            fail("4", f"{src} invokes {ref}, which does not exist in the payload")
    # 4b. skill-shaped tokens
    for tok in sorted(set(re.findall(r"`([a-z][a-z0-9:]*(?:-[a-z0-9]+)+)`", text))):
        tok = unqualify(tok)
        if tok in KNOWN or tok in NOT_A_SKILL:
            continue
        fail("4", f"{src} names '{tok}', which is neither a shipped skill nor a plugin skill",
             "a retired name, a typo, or vocabulary to add to NOT_A_SKILL in this script")
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
    for prof in sorted(set(re.findall(r"--profile ([a-z][a-z0-9-]*)", text))):
        if not os.path.exists(os.path.join(PAYLOAD, ".codex", "profiles",
                                           f"{prof}.config.toml")):
            fail("4", f"{src} launches `--profile {prof}`, "
                      f"but .codex/profiles/{prof}.config.toml is absent from the payload",
                 "check-requirements.sh reports this template as missing rather than WARN-able")

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
    # The review state was invisible to every reader of CONTEXT.md, including nine plugin
    # skills that load it. It now has its own file, and a named reader: the owner, via Thomas.
    ("glossary review state",       r"docs/agents/CONTEXT-review\.md|UNREVIEWED",
                                                              "bootstrap-glossary", ["thomas"]),
    # A produced DOCUMENT is an artifact too, and this row is the one that survived the
    # 1.6.1 cull: three sibling skills wrote files that no contract and no plugin skill was
    # told to read, and every check here went green because each was NAMED. `CONTEXT.md`
    # differs by being read — by the plugin, not by us — so its verifier is a plugin skill
    # and is checked against the installed copy when there is one.
    ("CONTEXT.md",                  r"CONTEXT\.md",           "bootstrap-glossary",
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
    print("Not scanned, and check 4 does not speak for it: the failure-mode ledger's "
          "historical `Bound:` provenance. A live project measured five citations there to "
          "a file that had been deleted, while check 4 reported clean — the scope line is "
          "part of the verdict, not a footnote to it.")
    sys.exit(0)

for check, msg, detail in findings:
    print(f"  [FAIL {check}] {msg}")
    if detail:
        print(f"            → {detail}")
print(f"\n{len(findings)} finding(s). A phase or skill nothing reaches will not run.")
sys.exit(1)
