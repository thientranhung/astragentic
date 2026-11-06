# Adapt the staged Astragentic Codex harness

Act as the project setup agent. Adapt the staged Codex runtime to this project,
then report what is ready and what still needs owner input. This is setup work,
not an assignment to Thomas or Builder. Use Codex-owned contracts throughout.

## 1. Establish the candidate and project context

Work from the target Git checkout root. Read its active AGENTS.md instructions and
inspect Git status before changing files; preserve existing work. Read
`.astraler/codex/CANDIDATE`, resolve the selected candidate beneath
`.astraler/codex/releases/<version>/`, and verify its VERSION agrees with the
selected version. Reject paths escaping that release directory, including symlink
escapes. The candidate contains `runtimes/codex/`, VERSION and RELEASE-NOTES.md.
Read those release notes and the runtime README, role common contract, dispatch
contract, orchestrator table and installer help/source as needed for setup.
If the pointer, version or required runtime files are missing/inconsistent, report
the exact gap before applying anything; do not select another release silently.

Inspect project entrypoints, scripts, architecture/docs, existing `.agents/` and
`.codex/`, tracker configuration and the current harness integration. Existing
legacy configuration is evidence of owner choices, not a Codex runtime dependency:
translate applicable project facts into Codex-owned instructions. Keep Claude
files and legacy `.astraler/state/applied-version` unchanged. Never require a Codex role
or skill to load a Claude role, adapter or dispatch document.

Completion: identify the candidate version, project root, existing integration,
project validation commands, tracker/access evidence and owner decisions to keep.
Record sources for each conclusion; distinguish observations from assumptions.

## 2. Reconcile and install the overlay

Use the selected candidate's `runtimes/codex/install.py` for every command below.
Run `install --project <absolute-project-root>` without `--apply` first. Review the
planned writes/removals against the existing project. Then apply from the project root through the staged entrypoint when the plan is
in scope (replace `<version>` with the verified selected version):

```sh
bash ".astraler/codex/releases/<version>/install.sh" "$PWD" --runtime codex --apply
```

This entrypoint runs the mechanical installer, records installed-version and
refreshes the shared wrapper. Direct `install.py --apply` alone omits that staging
bookkeeping; use direct installer commands for preview and doctor.

On drift or collision, inspect the old manifest, local file and candidate source.
Preserve local changes and produce a concrete reconciliation before retrying.
For an unchanged prior file that was accidentally removed, restore that exact
prior content only when its manifest hash can be verified. For deliberate local
edits, retain the project-specific meaning in an appropriate owner/project file
and reconcile the managed file to its verified prior baseline before upgrading.
For the shared `astragentic-update-install` skill already installed by the legacy
payload, the Codex manifest may intentionally not own it. When its bytes differ
from the new candidate, restoring old bytes will not resolve an unowned collision.
Use this explicit shared-skill migration instead:

- First confirm `.agents/skills/astragentic-update-install/SKILL.md` is NOT listed
  in the Codex manifest. If listed, let the installer manage it; do not hand-edit
  its hash or bytes to bypass ownership.
- Resolve the old legacy applied-version and read the shared skill from that exact
  staged release's `harness/.agents/skills/astragentic-update-install/SKILL.md`.
  Verify the installed shared skill equals that baseline. If a `.claude` mirror
  exists, verify it equals the same baseline too. A missing baseline or any local
  edit requires explicit reconciliation preserving that content, not an overwrite.
- Review the old-to-new skill diff. For verified pristine copies, replace the
  existing shared `.agents` copy and existing `.claude` mirror with the selected
  candidate skill, keeping the two identical. Do not create a Claude tree where
  none exists. Record this narrow shared-skill migration separately in the
  adaptation report; it does not mark the rest of the legacy payload upgraded.
- Re-run installer preview/apply. The identical unowned shared copy is reused
  without ownership transfer and survives Codex uninstall. Keep the legacy version
  stamp unchanged. On later upgrades, if that old release no longer matches the
  migrated skill, use the prior Codex staged release and its adaptation report as
  the explicit baseline for this recorded shared-skill migration; if unavailable,
  stop for reconciliation rather than guessing.

If the baseline or intended behavior cannot be established, leave the conflict
intact and report it. Never delete/edit the manifest, forge its hashes, or blindly
copy candidate files over local work to make installation pass. Re-run the dry
run after reconciliation. Keep owner model, effort, permissions and trust choices;
installer defaults are proposed defaults, not evidence of model access.

Completion: installer succeeds with the selected payload, or each unresolved
conflict is recorded without losing local content. A mechanical install may be
recorded by the entrypoint at `.astraler/codex/state/installed-version` only after successful apply; that
stamp does not mean the semantic adaptation below is complete.

## 3. Integrate the project meaning

Edit AGENTS.md narrowly, preserving its project rules and instruction hierarchy.
Add a compact Codex entrypoint section that directs setup/startup to installed
Codex role contracts, `.codex/DISPATCH.md`, and the project-owned
`.agents/orchestrator-for-codex.md`. Ensure instructions describe the project's
actual build/test commands, tracker, documentation sources and task handoff paths.
Avoid copying the full runtime contracts into AGENTS.md or assigning the current
session a downstream role. Existing shared instructions must remain valid for
other tools; keep Codex-specific behavior in a clearly scoped section/files.

Preserve an existing Codex orchestrator table. On first install, reconcile its
proposed defaults with documented owner choices without silently changing active
roles, models or effort. Verify the configured tracker through available read-only
access. Reuse established project identifiers and workflow conventions. Ask only
for genuine missing decisions or unavailable access needed for operation; do not
invent a tracker, install dependencies, change personal configuration/trust, or
substitute a model/provider to bypass a missing choice. A provider access probe
requires the owner's existing authorization and should avoid unnecessary spend.
Record inaccessible or untested access explicitly.

Completion: every relevant project rule and owner choice is preserved or has an
explicit disposition, the Codex entrypoint reaches self-contained contracts, and
required unresolved setup choices are visible.

## 4. Validate and hand back

Run candidate `install.py doctor --project <absolute-project-root>`. Run installed
`.codex/astragentic/launch.py thomas --project <absolute-project-root> --dry-run`
with Python 3; inspect the selected model/effort and startup argv. Use another role
only when the owner chose it. Do not start a live role merely to finish setup.
Inspect the installed Codex CLI version/help before claiming discovery or startup
capabilities. Newly installed skills/helpers require a new Codex session: give the
owner a concrete launch command and check discovery in that session when available.
A current session's cached catalog is not discovery evidence for the new overlay.

Write `.astraler/codex/state/adaptation-report.md` with candidate version, date,
changed files, retained choices, tracker/access findings, reconciliation decisions,
validation commands/results, remaining gaps and next startup command. Separate
static checks, real installer/doctor checks, mocked checks and live-session checks.
Mark checks not executed `NOT RUN` and runtime behavior without measurement
`not measured`; doctor and launch dry-run do not prove model access, native
skill/helper discovery or a successful dispatch journey.

Only after installation and semantic integration are complete, required setup
choices are resolved, and doctor/startup dry-run pass, write the selected version
to `.astraler/codex/state/adapted-version`. Write the report before this stamp. If a new
session cannot be observed, record discovery/live startup `NOT RUN` with the exact
handoff; the stamp records completed adaptation, not live certification. For a
partial/blocked run, keep any previous adapted-version and clearly mark that the
candidate is not yet adapted. Leave the candidate pointer and other releases intact.

Finish with the report path, installed/adapted versions, checks actually run,
remaining owner actions and the next-session command. Do not commit, publish,
deploy, fabricate gate/review receipts, or claim release readiness from setup.
