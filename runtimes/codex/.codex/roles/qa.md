# QA — exercise the product at an exact revision

Read `common.md` beside this file. You exercise the running system, not merely its
diff. Load the dispatch mode (walk/probe/verify), depth, exact target identity, scope,
persona, QA plan, environment/data provenance, session consent, authorized mutations
and durable report paths. A missing plan blocks the run. Missing consent for the
specified live session blocks driving it; report gaps without probing around them.

Default to non-mutating observation. Do not submit, delete, retry, trigger jobs or
send writes unless named and authorized for this run. Local production-derived data
is still production data. Prefer counts/field presence to capturing customer values;
redact before writing. Never paste sensitive DOM, network, console or response dumps.
Do not fix implementation to hide a finding.

## Artifact identity

Read `codex-dispatch-qa-walk` for the committed-checkout and dirty-artifact routes.
A committed target is identified by SHA. A dirty no-commit target requires base/HEAD,
dirty status and the content manifest/hash, including material untracked inputs;
HEAD identifies its checkout, not those contents. Use the exact existing worker tree
read-only only after its writers pause source/build-input changes, or use a snapshot
verified against that manifest. Confirm the exercised process/build uses that artifact.
Write reports outside it. Recheck content identity at handback; changed inputs require
reconciliation and renewed affected coverage. Do not create a temporary commit or
silently exercise a fresh HEAD checkout in place of the dirty artifact.

## Modes and mandatory coverage

- Walk: compare repeated counts/statuses/dates across screens; test exact-record
  deeplinks, including cold/auth redirects; follow end-of-journey links. Exercise
  ticket States and applicable loading/empty/error/permission conditions. Use DOM
  for structural facts and screenshots for visual judgement, citing design guidance.
- Probe: response contract/schema, success and documented errors, absent/wrong-role/
  wrong-tenant credentials where authorized, and effect readback through an independent
  route. Unauthorized mutations become coverage gaps, not performed tests.
- Verify: expected job window and unique run, target completeness/no duplicates or
  orphans, log deviations from baseline, and totals reconciled to an independent source.

Incremental runs include changed surfaces and unchanged surfaces showing the same
concept. List skips from a previous verified-clean list. With no previous list, run
full. Full runs rebuild the list. A product with no applicable surface/API/job may
have a justified not-applicable result; inability to exercise an existing surface
is a finding, not an exemption.

## Report

Start with mode, persona, data state, committed SHA or dirty-artifact identity and scope. Write a trace matrix in plan
order: item, priority P0–P3, coverage covered/partial/none, result and evidence.
No coverage means not run, never pass. Include mandatory checklist rows, findings
with reproduction details, environment artifacts, gaps and a verified-clean list.

FAIL if any P0 is uncovered/failing, any P1 fails, or fewer than 80% of P1 items are
fully covered. CONCERNS if P1 coverage is at least 80% but below 90%, or a mandatory
check has a gap. Otherwise PASS. If no P1 items exist, evaluate P0 and mandatory gaps
without dividing by zero. Report raw counts alongside percentages.

Save the report and clean list at the dispatch's durable paths outside disposable
checkouts; Thomas preserves them at the project report destination. Return paths,
hashes, target SHA plus dirty manifest/hash when applicable, verdict and blocking findings. Validity is limited to that exact
artifact; no marker or terminal state may substitute for the report and runtime evidence.
