#!/usr/bin/env python3
"""usage-report.py — what the harness cost and what it ran, counted from Claude Code transcripts.

Usage:
  scripts/usage-report.py [--project <substring>] [--days N] [--by role|ticket|skill|gate|subagent|all]

Reads ~/.claude/projects/<dir>/*.jsonl (and <session>/subagents/*.jsonl) whose directory name
contains --project (default: the current repo's directory name). Every assistant message carries
`usage` as the API billed it; every tool_use block names the tool. Nothing here is estimated
except the dollar column, priced at Sonnet 5 / Opus 5.5 list rates by `message.model`.

Why this exists (4.1.0): the field audit of 2026-10-18 needed three hand-written scripts to
answer "what ran, how often, at what context"; the rule since then is that no plan item goes
to the owner without a count and its source. This is the count. Sources it cannot see: hook
passes (only denials reach the transcript), UI chips and toasts, advisor calls.
"""
import argparse, collections, glob, json, os, statistics, sys, time

RATES = {  # $/M tokens: (input, cache_read, cache_write, output)
    "sonnet": (2.0, 0.20, 2.5, 10.0),
    "opus": (4.0, 0.20, 5.0, 20.0),
    "fable": (10.0, 0.25, 12.5, 50.0),
    "haiku": (0.10, 0.01, 0.125, 0.50),
}
GATE_PREFIXES = ("astragentic-dispatch:", "hook-git-guard", "PreToolUse:Bash hook error")


def family(model):
    m = (model or "").lower()
    for k in RATES:
        if k in m:
            return k
    return "sonnet"


def role_of(path, dir_name):
    if "builder-" in dir_name or "ticket-" in dir_name:
        return "builder"
    if "spec-" in dir_name or "shaper" in dir_name:
        return "shaper"
    if "qa-" in dir_name or "gate-" in dir_name:
        return "qa"
    return "thomas"


def ticket_of(dir_name):
    # The key after the lane prefix, not the first key-shaped token: a transcript directory
    # encodes the whole cwd, and "/2.DEV/2.PRIVATE/" read as ticket DEV-2 for every call.
    import re
    m = re.search(r"(?:builder|ticket|spec|shaper|qa|gate)-([A-Z][A-Z0-9]*-[0-9]+)", dir_name)
    return m.group(1) if m else "-"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=os.path.basename(os.getcwd()))
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--by", default="all")
    a = ap.parse_args()
    since = time.time() - a.days * 86400
    base = os.path.expanduser("~/.claude/projects")
    files = []
    for d in glob.glob(os.path.join(base, "*")):
        if a.project not in os.path.basename(d):
            continue
        files += glob.glob(os.path.join(d, "*.jsonl")) + glob.glob(os.path.join(d, "*", "subagents", "*.jsonl"))
    files = [f for f in files if os.path.getmtime(f) >= since]
    if not files:
        print(f"no transcripts for project '{a.project}' in the last {a.days} days under {base}")
        return 1

    per_role = collections.defaultdict(lambda: {"calls": 0, "ctx": [], "in": 0, "cr": 0, "cw": 0, "out": 0, "usd": 0.0})
    per_ticket = collections.defaultdict(lambda: {"calls": 0, "ctx": [], "usd": 0.0, "skills": collections.Counter(), "agents": 0})
    skills = collections.Counter(); gates = collections.Counter(); agents = collections.Counter()
    seen = set()
    for f in files:
        dir_name = os.path.basename(os.path.dirname(f) if "/subagents/" not in f else os.path.dirname(os.path.dirname(os.path.dirname(f))))
        role = role_of(f, dir_name); ticket = ticket_of(dir_name)
        for line in open(f, errors="replace"):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            m = o.get("message") if isinstance(o.get("message"), dict) else None
            if not m:
                continue
            c = m.get("content")
            if m.get("role") == "assistant" and m.get("usage"):
                mid = m.get("id")
                if mid in seen:
                    continue
                seen.add(mid)
                u = m["usage"]; inp = u.get("input_tokens", 0); cr = u.get("cache_read_input_tokens", 0)
                cw = u.get("cache_creation_input_tokens", 0); out = u.get("output_tokens", 0)
                r = RATES[family(m.get("model"))]
                usd = (inp * r[0] + cr * r[1] + cw * r[2] + out * r[3]) / 1e6
                pr = per_role[role]; pr["calls"] += 1; pr["ctx"].append(inp + cr + cw)
                pr["in"] += inp; pr["cr"] += cr; pr["cw"] += cw; pr["out"] += out; pr["usd"] += usd
                pt = per_ticket[ticket]; pt["calls"] += 1; pt["ctx"].append(inp + cr + cw); pt["usd"] += usd
            if isinstance(c, list):
                for b in c:
                    if b.get("type") == "tool_use":
                        n = b.get("name", ""); inp = b.get("input") or {}
                        if n == "Skill":
                            skills[inp.get("skill", "?")] += 1; per_ticket[ticket]["skills"][inp.get("skill", "?")] += 1
                        elif n in ("Agent", "Task"):
                            agents[inp.get("subagent_type", "?")] += 1; per_ticket[ticket]["agents"] += 1
                    elif b.get("type") == "tool_result":
                        cc = b.get("content"); txt = cc if isinstance(cc, str) else " ".join(x.get("text", "") for x in cc if isinstance(x, dict)) if isinstance(cc, list) else ""
                        # Anchored at the start of the result: a `cat` of the hook log quotes
                        # these prefixes mid-text and is not a refusal the model received.
                        head = txt.lstrip()
                        first = head.split("\n")[0]
                        if first.startswith("<tool_use_error>"):
                            first = first[len("<tool_use_error>"):]
                        if any(first.startswith(p) for p in GATE_PREFIXES):
                            gates[first[:70]] += 1

    def med(xs):
        return int(statistics.median(xs)) if xs else 0

    print(f"usage-report · project '{a.project}' · last {a.days} days · {len(files)} transcript files · {len(seen)} model calls")
    if a.by in ("role", "all"):
        print("\n## by role\n| role | calls | median context | input | cache read | cache write | output | est $ |\n|---|---|---|---|---|---|---|---|")
        for role, v in sorted(per_role.items(), key=lambda kv: -kv[1]["usd"]):
            print(f"| {role} | {v['calls']:,} | {med(v['ctx']):,} | {v['in']:,} | {v['cr']:,} | {v['cw']:,} | {v['out']:,} | {v['usd']:,.0f} |")
    if a.by in ("ticket", "all"):
        print("\n## by ticket (top 15 by $)\n| ticket | calls | median context | subagents | skills | est $ |\n|---|---|---|---|---|---|")
        for tk, v in sorted(per_ticket.items(), key=lambda kv: -kv[1]["usd"])[:15]:
            sk = ", ".join(f"{k}×{n}" if n > 1 else k for k, n in v["skills"].most_common(6))
            print(f"| {tk} | {v['calls']:,} | {med(v['ctx']):,} | {v['agents']} | {sk} | {v['usd']:,.0f} |")
    if a.by in ("skill", "all"):
        print("\n## skills (Skill tool calls)\n| skill | calls |\n|---|---|")
        for k, n in skills.most_common(): print(f"| {k} | {n} |")
    if a.by in ("subagent", "all"):
        print("\n## subagents (Agent tool spawns)\n| type | spawns |\n|---|---|")
        for k, n in agents.most_common(): print(f"| {k} | {n} |")
    if a.by in ("gate", "all"):
        print("\n## refusals seen by the model (first line of the tool result)\n| refusal | count |\n|---|---|")
        for k, n in gates.most_common(25): print(f"| {k} | {n} |")
    print("\nNot visible here: hook passes, UI chips/toasts, advisor calls, RECEIVED acks. Dollar column is a list-price estimate.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
