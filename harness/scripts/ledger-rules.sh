#!/usr/bin/env python3
"""ledger-rules.sh — derive RULES.md, the rule half of the ledger, from the ledger itself.

WHY THIS EXISTS. Every role is told to reach the ledger through `INDEX.md` and then
`grep -A40 '^### AST-0NN'`. That protocol is right — it keeps a 51k-token file out of every
session — but the 40 lines it returns are roughly a quarter rule and three quarters incident
narrative, because entry size inflated about fifteen-fold across this package's life: the
AST-001…009 group averages 21 words, the AST-070s average 519. Narrative is what makes a rule
survive an argument with an operator who wants to skip it, so it is not waste. It is simply the
wrong shape for a lookup, and until now there was only one shape available.

WHAT IT DOES NOT DO. It does not edit, reorder or remove anything. The ledger stays append-only
and stays the source of truth; this output is derived and disposable, and says so at the top.
Where the two disagree the ledger is right and this file needs regenerating.

Usage:  python3 scripts/ledger-rules.sh [repo-root]
        python3 scripts/ledger-rules.sh --check    # non-zero when RULES.md is stale
"""

import os
import re
import sys

WORDS = 38  # of body per entry: enough for the rule, short of the story


def locate(root):
    for cand in (os.path.join(root, "harness", ".agents", "memory"),
                 os.path.join(root, ".agents", "memory")):
        if os.path.isfile(os.path.join(cand, "recurring-failure-modes.md")):
            return cand
    return None


def render(ledger_text):
    blocks = re.split(r"(?m)^(?=### AST-)", ledger_text)
    rows = []
    for blk in blocks[1:]:
        m = re.match(r"### (AST-\d+) — ([^·\n]+)(?:·\s*([a-z]+))?", blk)
        if not m:
            continue
        aid, title, status = m.group(1), m.group(2).strip(), (m.group(3) or "").strip()
        body = re.sub(r"\s+", " ", " ".join(blk.split("\n")[1:])).strip()
        body = re.sub(r"Bound:.*$", "", body).strip()
        rows.append((aid, title, status, " ".join(body.split()[:WORDS])))

    out = ["# Ledger — rules only", "",
           "**Generated from `recurring-failure-modes.md`; do not hand-edit, rerun "
           "`scripts/ledger-rules.sh`.**", "",
           "One line per entry: the id, the lesson, and the opening of its body — the rule, "
           "without the incident", "that produced it. A `grep -A40` into the full ledger "
           "returns roughly a quarter rule and three", "quarters narrative, which is the right "
           "shape for evidence and the wrong shape for a lookup.", "",
           "**Read the full entry when you need the evidence.** The story is what makes a rule "
           "survive an", "argument, and it is one grep away:", "",
           "```bash", "grep -A40 '^### AST-0NN' recurring-failure-modes.md", "```", "",
           "**Nothing here is authoritative.** The ledger is append-only and this file is "
           "derived; where the", "two disagree the ledger is right and this file is stale.", "",
           "| ID | Lesson | Status | The rule |", "|---|---|---|---|"]
    for aid, title, status, rule in rows:
        out.append("| `%s` | %s | %s | %s |"
                   % (aid, title.replace("|", "\\|"), status, rule.replace("|", "\\|")))
    return "\n".join(out) + "\n", len(rows)


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv[1:]
    root = args[0] if args else os.path.abspath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    mem = locate(root)
    if not mem:
        print("STOP: ledger not found under %s" % root)
        return 1
    ledger = os.path.join(mem, "recurring-failure-modes.md")
    dest = os.path.join(mem, "RULES.md")
    with open(ledger, encoding="utf-8") as fh:
        text, n = render(fh.read())

    if check:
        try:
            with open(dest, encoding="utf-8") as fh:
                current = fh.read()
        except OSError:
            print("STOP: RULES.md is missing — run scripts/ledger-rules.sh")
            return 1
        if current != text:
            print("STOP: RULES.md is stale — run scripts/ledger-rules.sh")
            return 1
        print("ok: RULES.md current (%d entries)" % n)
        return 0

    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("wrote %s (%d entries)" % (dest, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
