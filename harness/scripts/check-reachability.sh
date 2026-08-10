#!/usr/bin/env python3
"""check-reachability.sh — does the method the docs describe actually exist?

The prior package lost two weeks to an Align phase that lived in a method document and in
no role's contract, so nothing ever ran it. Every check here exists to make that class of
gap fail loudly instead of quietly.

Four checks, in both directions:

  1 METHOD -> CONTRACT   every phase the README's role table names is the owning row of
                         exactly one contract, owned by the role the README names.
  2 CONTRACT -> UNIQUE   every phase any contract declares is declared by exactly one.
  3 SKILL -> REACHED     every shipped skill is named by a contract, another skill, or
                         the adaptation prompt. A skill nothing reaches is dead weight or
                         a phase that will never run.
  4 REFERENCE -> EXISTS  every payload path and skill name referenced by a contract or a
                         shipped skill resolves. HARD failure: a contract naming a file
                         that does not exist is how the prior package failed.

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
roles = {os.path.basename(p)[:-3]: read(p)
         for p in sorted(glob.glob(os.path.join(ROLES_DIR, "*.md")))}
skills = {}
for pattern in SKILL_GLOBS:
    for p in sorted(glob.glob(pattern)):
        skills[os.path.basename(os.path.dirname(p))] = (p, read(p))

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
KNOWN = set(skills) | PLUGIN

# Kebab-case tokens that are vocabulary rather than skill references. Each is here because
# it appears in backticks and looks like a skill name; the list stays short on purpose,
# because a long one would mean this check has stopped discriminating.
NOT_A_SKILL = {
    "no-secrets-in-exports", "expand-contract", "recent-unwrapped", "code-map",
    "agent-not-idle", "agent-not-found", "agent-prompt-stalled", "read-only",
    "cross-vendor", "single-provider", "gate-arm", "wontfix-with-a-recorded-reason",
    "claude-plugins-official", "mattpocock-skills", "claude-sonnet-4-6", "openai-codex",
    "issue-tracker", "triage-labels", "check-requirements", "install", "uninstall",
    # CLI subcommands and flags that happen to be kebab-case.
    "adversarial-review", "send-text", "send-keys", "gate-diff", "no-focus",
    "allowed-tools", "dangerously-skip-permissions", "project-name", "optional-too",
    "applied-version", "module-boundaries-md", "gen-code-map",
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
        named = [t for t in re.findall(r"`([a-z0-9-]+)`", cells[2]) if t in KNOWN]
        if named:
            method_rows[role] = named
else:
    fail("1", f"README not found at {README}, so the method's own role table cannot be read")

# Phases each contract OWNS: rows of its leading phase table, second column.
owned = {}          # phase -> [role, ...]
for role, text in roles.items():
    for line in text.splitlines():
        if not line.startswith("|") or line.startswith("|---"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 2:
            continue
        m = re.fullmatch(r"`([a-z0-9-]+)`", cells[1])
        if m:
            owned.setdefault(m.group(1), []).append(role)

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

for name in sorted(skills):
    found = [src for src, text in reachers.items()
             if src != "skill " + name and re.search(rf"`?\b{re.escape(name)}\b`?", text)]
    if not found:
        fail("3", f"skill '{name}' is reached by nothing",
             "name it in the contract of the role that uses it, or drop it")

# --- 4. REFERENCE -> EXISTS -------------------------------------------------------------
sources = {f"contract {r}": t for r, t in roles.items()}
sources.update({f"skill {n}": t for n, (_, t) in skills.items()})

for src, text in sorted(sources.items()):
    # 4a. payload-relative paths
    for ref in sorted(set(re.findall(r"`((?:\.agents|\.claude|scripts)/[A-Za-z0-9_./-]+)`", text))):
        if ref.endswith("/"):
            continue
        if "<" in ref or ref.count("*"):
            continue
        if not os.path.exists(os.path.join(PAYLOAD, ref)):
            fail("4", f"{src} references {ref}, which does not exist in the payload")
    # 4b. skill-shaped tokens
    for tok in sorted(set(re.findall(r"`([a-z][a-z0-9]*(?:-[a-z0-9]+)+)`", text))):
        if tok in KNOWN or tok in NOT_A_SKILL:
            continue
        fail("4", f"{src} names '{tok}', which is neither a shipped skill nor a plugin skill",
             "a retired name, a typo, or vocabulary to add to NOT_A_SKILL in this script")
    # 4c. launcher argv. `claude --agent X` resolves X from .claude/agents/ RELATIVE TO THE
    # CWD, so a named agent with no definition fails at dispatch with "agent not found" —
    # the same dangling-reference class as 4a, just written as argv instead of a path.
    for agent in sorted(set(re.findall(r"--agent ([a-z][a-z0-9-]*)", text))):
        if agent.startswith("<"):
            continue
        if not os.path.exists(os.path.join(PAYLOAD, ".claude", "agents", f"{agent}.md")):
            fail("4", f"{src} launches `--agent {agent}`, "
                      f"but .claude/agents/{agent}.md is absent from the payload",
                 "claude resolves the agent definition from the cwd; this dispatch cannot start")
    for prof in sorted(set(re.findall(r"--profile ([a-z][a-z0-9-]*)", text))):
        if not os.path.exists(os.path.join(PAYLOAD, ".codex", "profiles",
                                           f"{prof}.config.toml")):
            fail("4", f"{src} launches `--profile {prof}`, "
                      f"but .codex/profiles/{prof}.config.toml is absent from the payload",
                 "check-requirements.sh reports this template as missing rather than WARN-able")

# --- report -----------------------------------------------------------------------------
print(f"Reachability check — {LAYOUT} layout, payload at {os.path.normpath(PAYLOAD)}")
print(f"  {len(roles)} contracts · {len(skills)} shipped skills · "
      f"{len(owned)} owned phases · {len(PLUGIN)} plugin skills known")
print()
if not findings:
    print("  [OK] 1 every phase the method names is owned by the contract it names")
    print("  [OK] 2 every declared phase is declared exactly once")
    print("  [OK] 3 every shipped skill is reached")
    print("  [OK] 4 every referenced path and skill exists")
    print("\nAll reachability checks passed.")
    sys.exit(0)

for check, msg, detail in findings:
    print(f"  [FAIL {check}] {msg}")
    if detail:
        print(f"            → {detail}")
print(f"\n{len(findings)} finding(s). A phase or skill nothing reaches will not run.")
sys.exit(1)
