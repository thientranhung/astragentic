# Astragentic development in Codex

This file governs work on the harness repository. It does not assign a downstream
Thomas or Builder role. Read `docs/codex/README.md` before changing Codex integration.

- Preserve Claude Code behavior. Put Codex-specific contracts and configuration in
  separate files. Do not rewrite `.claude/`, `CLAUDE.md`, or Claude role adapters to
  accommodate Codex unless the owner explicitly expands scope.
- Inspect the current tree and installed CLI before relying on historical integration
  notes. For every proposed capability, record a measurement and source; label untested
  runtime behavior `not measured` rather than treating documentation as execution proof.
- Claude runtime documents are implementation research sources only. Codex role,
  agent, and skill instructions must be self-contained or reference Codex-owned
  contracts; never require loading a Claude role, adapter, or dispatch document.
- The paired skill trees currently have an installer-enforced equality contract.
  Do not silently diverge them or disable the check to add Codex behavior.
- Keep owner model, permission, trust, and orchestrator choices owner-controlled.
  Do not edit user-level Codex configuration or switch active role assignments implicitly.
- A prompted check is not an enforced gate. Never manufacture Claude mod events,
  skill invocation receipts, review results, or completion markers for Codex sessions.
- Test the changed integration at its real boundary. Report static checks, mocked
  checks, and live-session checks separately. Do not claim release readiness from syntax.
- Keep edits narrow; do not commit, publish, or deploy merely to finish integration work.
