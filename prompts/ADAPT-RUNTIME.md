# Set up the staged Astragentic release

This is the common install/update entrypoint for the agent currently helping the
owner. Continue the requested setup after staging; do not ask the owner to copy
another prompt or select a CLI flag when the session already identifies its runtime.

Read the project's active instructions and Git status. Resolve the release from
this document's directory, check its VERSION and the project candidate pointer,
and read the relevant release notes (including skipped migrations on upgrade).
If the candidate changed since this prompt was issued, report that mismatch before
applying. Preserve project changes, owner configuration and the other runtime.

Select from your actual session identity, not from installed binaries, existing
Claude files, model names or the tool used to launch a terminal:

- **Claude Code:** read `ADAPT-HARNESS.md` beside this file and execute its existing
  workflow. No changes to the Claude adaptation contract are implied by this router.
- **Codex:** from the target Git root, run the selected release's `install.sh` with
  the target root and `--runtime codex` to stage its Codex candidate. This flag is
  an internal adapter detail, not an extra step for the owner. Read the resulting
  `ADAPT-HARNESS-CODEX.md` and execute it. Do not load the Claude adaptation or role
  contracts. Keep legacy applied-version untouched; Codex has separate file and
  semantic adaptation receipts.
- **Another runtime:** inspect whether this release ships a self-contained adapter
  for that runtime. If absent, report that gap and leave the installed harness
  intact. A portable update skill does not make unsupported runtime contracts work.
  If identity genuinely cannot be established, ask only which runtime is intended.

The shared `astragentic-update-install` skill is shipped in the selected payload.
Ensure it is installed/discoverable through the runtime's supported skill location.
Newly installed skills may need a new session. Finish with the selected release,
actual changes, preserved choices, validation results, report path and remaining
steps. A download or successful file copy alone is not completed adaptation.
