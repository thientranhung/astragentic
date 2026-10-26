#!/usr/bin/env python3
"""hook-test-run.py — PostToolUse(Bash): record every test run's exit status, so the commit
gate can ask "did a test go RED after the brief and before the first content commit?"

Why (4.5.2): the tdd gate measured a test FILE (4.1.3), and a Builder could write code first,
stage a test beside it and call `mattpocock-skills:tdd` afterwards — 61 of 161 downstream
tickets did (one downstream project, 14 days to 2026-10-26), 15 never called it. A skill call is a line in a
record; a red run is the thing TDD is. The mod cannot see a tool's result (its events are
pre-call), so this hook writes the status and the mod reads the file.

Input: the PostToolUse JSON on stdin (`tool_input.command`, `tool_response.status` — the Bash
tool's exit code; older shapes carry only stdout/stderr, read for `Exit code N`).
Output: one line per matching run appended to /tmp/harness-test-runs/<git toplevel, non-alphanumerics as _>.log:
`<epoch ms>\t<status>\t<command, first 200 chars>`. Never blocks, never prints.

Which commands are test runs: `.astraler/project/test-command-pattern` (one regex) or the
default below. A project whose runner is not listed adds one line there.
"""
import json, os, re, subprocess, sys, time

DEFAULT = (r"(^|[\s;&|(])(go\s+test|pytest|py\.test|python3?\s+-m\s+(pytest|unittest)|vitest|jest|mocha|"
           r"(npm|pnpm|yarn|bun)\s+(run\s+)?test\w*|cargo\s+test|mix\s+test|rspec|phpunit|dotnet\s+test|"
           r"mvn\s+test|gradle\w*\s+test|make\s+test\w*|\./gradlew\s+test|swift\s+test|ctest)\b")


def toplevel(cwd):
    try:
        r = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"], capture_output=True, text=True, timeout=5)
        return os.path.realpath(r.stdout.strip() or cwd)
    except Exception:
        return os.path.realpath(cwd)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return
    cmd = str((payload.get("tool_input") or {}).get("command") or "")
    if not cmd:
        return
    cwd = str(payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    top = toplevel(cwd)
    pat = DEFAULT
    plug = os.path.join(top, ".astraler", "project", "test-command-pattern")
    try:
        with open(plug, encoding="utf-8") as fh:
            first = fh.readline().strip()
        if first:
            re.compile(first); pat = first
    except Exception:
        pass
    if not re.search(pat, cmd):
        return
    resp = payload.get("tool_response")
    status = None
    if isinstance(resp, dict):
        for k in ("status", "exitCode", "code"):
            v = resp.get(k)
            if isinstance(v, int):
                status = v; break
        if status is None:
            text = " ".join(str(resp.get(k) or "") for k in ("stdout", "stderr", "output"))
            m = re.search(r"\bExit code (\d+)\b", text)
            status = int(m.group(1)) if m else (1 if resp.get("isError") or resp.get("is_error") else 0)
    elif isinstance(resp, str):
        m = re.search(r"\bExit code (\d+)\b", resp)
        status = int(m.group(1)) if m else 0
    if status is None:
        status = 0
    d = "/tmp/harness-test-runs"
    os.makedirs(d, exist_ok=True)
    name = re.sub(r"[^A-Za-z0-9]+", "_", top).strip("_")
    with open(os.path.join(d, name + ".log"), "a", encoding="utf-8") as fh:
        fh.write(f"{int(time.time() * 1000)}\t{status}\t{cmd[:200].replace(chr(10), ' ')}\n")


if __name__ == "__main__":
    main()
