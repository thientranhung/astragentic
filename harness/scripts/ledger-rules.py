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

Usage:  python3 scripts/ledger-rules.py [repo-root]
        python3 scripts/ledger-rules.py --check    # non-zero when RULES.md is stale
"""

import os
import re
import sys

# A rule is a SENTENCE, not a word count. The first version took 38 words and cut AST-011 at
# "Codex end-of-p" and AST-012 at "The surviving core:" — precisely where the rule began. A
# digest four contracts consult BEFORE the ledger cannot end mid-clause, and its freshness
# check cannot see that, because byte-freshness says nothing about semantic completeness.
MAX_CHARS = 320
_SENT = re.compile(r"(?<=[.!?])\s+")

# Status modifiers, strongest last: an entry whose body says it was superseded is superseded,
# whatever the header's first word says. Two entries were reading `promoted` while their own
# text began "Superseded by".
_STATUSES = ("open", "proposed", "promoted", "closed", "reverted", "superseded", "withdrawn")


def summarise(body):
    """Whole sentences up to a budget. Returns (text, truncated)."""
    sentences = _SENT.split(body)
    out, n = [], 0
    for sent in sentences:
        sent = sent.strip()
        if not sent:
            continue
        if out and n + len(sent) > MAX_CHARS:
            return " ".join(out), True
        out.append(sent)
        n += len(sent) + 1
        if n >= MAX_CHARS:
            return " ".join(out), len(sentences) > len(out)
    return " ".join(out), False


def status_of(header, body):
    """Every modifier the entry carries, superseded/reverted winning over promoted."""
    found = [w for w in _STATUSES if re.search(r"\b%s\b" % w, header, re.I)]
    for strong in ("superseded", "reverted", "withdrawn"):
        if re.search(r"\b%s\b" % strong, body[:400], re.I) and strong not in found:
            found.append(strong)
    if not found:
        return ""
    for strong in ("withdrawn", "reverted", "superseded"):
        if strong in found:
            return strong
    return found[-1]


def locate(root):
    for cand in (os.path.join(root, "harness", ".agents", "memory"),
                 os.path.join(root, ".agents", "memory")):
        if os.path.isfile(os.path.join(cand, "recurring-failure-modes.md")):
            return cand
    return None


def render(ledger_text):
    blocks = re.split(r"(?m)^(?=### AST-)", ledger_text)
    rows, truncated = [], []
    for blk in blocks[1:]:
        header = blk.split("\n", 1)[0]
        m = re.match(r"### (AST-\d+) — ([^·\n]+)", header)
        if not m:
            continue
        aid, title = m.group(1), m.group(2).strip()
        body = re.sub(r"\s+", " ", " ".join(blk.split("\n")[1:])).strip()
        body = re.sub(r"Bound:.*$", "", body).strip()
        rule, cut = summarise(body)
        if cut:
            rule += " …"
            truncated.append(aid)
        rows.append((aid, title, status_of(header, body), rule))

    out = ["# Ledger — rules only", "",
           "**Generated from `recurring-failure-modes.md`; do not hand-edit, rerun "
           "`scripts/ledger-rules.py`.**", "",
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
    if truncated:
        out.append("")
        out.append("*Entries whose rule did not fit and end with `…`: %s. Read those in the "
                   "ledger.*" % ", ".join("`%s`" % t for t in truncated))
    return "\n".join(out) + "\n", len(rows)


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv[1:]
    # Walk up to the payload rather than assuming a depth: `../..` is right under
    # `harness/scripts/` and one level too high in an adapted project, where this printed
    # "ledger not found" pointing at the repo's parent directory.
    if args:
        root = args[0]
    else:
        root = os.path.dirname(os.path.abspath(__file__))
        while root != "/":
            if locate(root):
                break
            root = os.path.dirname(root)
        else:
            root = os.getcwd()
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
            print("STOP: RULES.md is missing — run scripts/ledger-rules.py")
            return 1
        if current != text:
            print("STOP: RULES.md is stale — run scripts/ledger-rules.py")
            return 1
        print("ok: RULES.md current (%d entries)" % n)
        return 0

    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("wrote %s (%d entries)" % (dest, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
