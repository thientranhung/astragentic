#!/usr/bin/env python3
"""hook-test-run.py — PostToolUse(Bash) AND PostToolUseFailure(Bash): record every test run's
exit status, so the commit gate can ask "did a test go RED after the brief and before the first
content commit?"

THE FAILURE EVENT IS THE ONE THAT MATTERS (4.5.3). PostToolUse fires only when the tool
succeeds; a Bash call that exits non-zero goes to PostToolUseFailure, whose payload carries
`error` (first line `Exit code N`) instead of `tool_response`. 4.5.2 registered only the first,
so no red run was ever logged and every honest Builder was refused at its first content commit
(one downstream project, 2026-10-26, probed: `go test ./does-not-exist/...` exit 1 → no line).
Both events now run this script; the same settings.json entry, twice.

Why (4.5.2): the tdd gate measured a test FILE (4.1.3), and a Builder could write code first,
stage a test beside it and call the tdd skill afterwards — 61 of 161 downstream
tickets did (one downstream project, 14 days to 2026-10-26), 15 never called it. A skill call is a line in a
record; a red run is the thing TDD is. The mod cannot see a tool's result (its events are
pre-call), so this hook writes the status and the mod reads the file.

Input: the hook JSON on stdin (`tool_input.command`; on success `tool_response.status` — the
Bash tool's exit code, older shapes carry only stdout/stderr, read for `Exit code N`; on failure
`error`, read for `Exit code N`, else 1). A background launch (`tool_response.backgroundTaskId`
or `tool_input.run_in_background`) has no exit code yet: logged `background`, never 0.
Output: one line per matching run appended to /tmp/harness-test-runs/<git toplevel, non-alphanumerics as _>.log:
`<epoch ms>\t<status>\t<command, first 200 chars>`. Never blocks.

A MASKED STATUS IS NOT A STATUS (4.5.3). Measured downstream (one ticket, the first under 4.5.2):
`bash tools/selftest.sh > log 2>&1; echo "EXIT=$?"; grep FAIL log` really failed, the Bash tool
reported the trailing grep's 0, the hook logged 0, and the first content commit was refused
twice for "no RED run" — five turns re-running a test that had gone red. When the matched test
command is followed by `;`, `|`, `||` or a newline, the exit code the tool reports is some
other command's: the line is logged `masked` and the hook answers with additionalContext telling
the pane to run the test command alone (`&&` and redirections keep the code and are fine).

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
    hit = re.search(pat, cmd)
    if not hit:
        return
    # quoted text is argument (`-run 'TestA|TestB'`), a trailing newline is nothing
    tail = re.sub(r"'[^']*'|\"[^\"]*\"", "", cmd[hit.end():]).rstrip()
    masked = re.search(r"[;|\n]", tail) is not None
    resp = payload.get("tool_response")
    tool_input = payload.get("tool_input") or {}
    status = None
    background = bool(tool_input.get("run_in_background")) or (isinstance(resp, dict) and bool(resp.get("backgroundTaskId")))
    if str(payload.get("hook_event_name") or "") == "PostToolUseFailure" or (resp is None and payload.get("error") is not None):
        m = re.search(r"\bExit code (\d+)\b", str(payload.get("error") or ""))
        status = int(m.group(1)) if m else 1
    elif isinstance(resp, dict):
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
    evt = str(payload.get("hook_event_name") or "PostToolUse")
    if background:
        status = "background"
    elif masked:
        status = "masked"
    d = "/tmp/harness-test-runs"
    os.makedirs(d, exist_ok=True)
    name = re.sub(r"[^A-Za-z0-9]+", "_", top).strip("_")
    with open(os.path.join(d, name + ".log"), "a", encoding="utf-8") as fh:
        fh.write(f"{int(time.time() * 1000)}\t{status}\t{cmd[:200].replace(chr(10), ' ')}\n")
    if background:
        note = ("astragentic: that test run is logged as `background` — it has no exit code yet, and the commit gate "
                "reads none from it. Run the test in the foreground before the first commit (builder-claude.md § Background work).")
        print(json.dumps({"hookSpecificOutput": {"hookEventName": evt, "additionalContext": note}}))
    elif masked:
        note = ("astragentic: that test run is logged as `masked` — the exit code the tool reported belongs to the "
                "command after `;`, `|`, `||` or the newline, not to the test. The commit gate reads only a run with "
                "its own non-zero exit code: run the test command alone (redirections and `&&` are fine) before the first commit.")
        print(json.dumps({"hookSpecificOutput": {"hookEventName": evt, "additionalContext": note}}))


if __name__ == "__main__":
    main()
