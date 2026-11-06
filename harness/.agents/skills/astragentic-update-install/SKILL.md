---
name: astragentic-update-install
description: "Check the installed Astragentic version and available releases, or install/update Astragentic in the current project. Use for “Astragentic có bản mới rồi, kiểm tra version và cập nhật”, “kiểm tra phiên bản”, “cài Astragentic”, or “check/install/update Astragentic” across agent runtimes."
---

# Check, install, or update Astragentic

Use one release workflow in the current project. Determine the runtime from the actual
current agent session, never from binaries found on PATH. The owner need not provide a
runtime flag. Do not launch another runtime or impersonate its adaptation role.

## Inspect and resolve

- Find the project's Git root and inspect its instructions and working tree. Preserve
  owner changes, project configuration, role/model assignments, permissions and trust.
- Read existing version evidence separately: legacy `.astraler/state/applied-version`,
  Codex `.astraler/codex/state/installed-version` and
  `.astraler/codex/state/adapted-version`, and staged `.astraler/releases/` content.
  Missing state means unknown; staged or installed does not mean adapted. Mixed runtime
  state does not identify the active session or authorize converting the project.
- Resolve release tags using the existing `ASTRAGENTIC_REPO` environment setting, otherwise
  `https://github.com/thientranhung/astragentic.git`. Do not derive the package source from
  the downstream project's `origin`. Honor an explicitly requested release; otherwise
  select the newest published version tag. Check the tag and its release `VERSION`.
  A checkout's untagged working tree is not a published release. Use local source only
  when the owner explicitly requests it, and label its version/provenance truthfully.
- Read the target release's `RELEASE-NOTES.md`, including releases skipped since the
  relevant applied/adapted version. Report current version evidence, target tag/source,
  material migrations and any unresolved conflict before making dependent changes.

A check-only request permits inspection and reporting, not installation or staging.
An explicit install/update request (including the Vietnamese example above) authorizes
staging and adaptation in this project. Continue through both within that authorization;
ask only for a missing consequential owner decision or an expansion of scope.

## Stage, then adapt in this session

From the project root, use the package's `get.sh` with `latest` or the requested version,
without `--apply` and without asking the owner for runtime flags. The default stage-only
operation fetches a tagged release and stages it under `.astraler/releases/<version>/`.
Use the chosen source's bootstrap script; the canonical bootstrap is
`https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh`. Keep the same
source setting for tag discovery and bootstrap execution. Inspect the script and its
result; do not silently switch source or claim a failed fetch succeeded.

After staging, read `.astraler/releases/<version>/ADAPT-RUNTIME.md` completely and
execute its route for the actual session. This shared entrypoint selects a separate
Codex-owned contract for Codex, or the existing Claude adaptation contract for Claude.
Do not stop merely because staging printed an adaptation instruction. Let the selected
contract govern integration, conflict resolution, receipt and version state; never stamp
completion to bypass unfinished work. Preserve owner files and existing runtime state.

For older releases without `ADAPT-RUNTIME.md`, only an actual Claude session may follow
that release's `ADAPT-HARNESS.md`. In Codex, explain that the release lacks the shared
runtime adapter and leave it staged; do not load Claude adaptation as Codex instructions.
For any unsupported runtime, report the missing route and leave adaptation incomplete;
a portable skill entrypoint does not establish support for that runtime.

## Verify and report

Follow the selected release contract's checks and reread the changed version state and
receipt. Distinguish fetched, staged, installed and adapted versions. Report changed
project files, unresolved decisions/conflicts, checks actually run, and the next action
when blocked. Static checks, mocked checks and live-session checks are separate evidence.
Do not claim a successful live startup, enforced gates or release readiness unless
measured. Do not edit user-level configuration, commit, publish or deploy to finish an
update unless separately authorized.
