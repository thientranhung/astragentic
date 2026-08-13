---
description: Audit the tracker for tickets that are ready and do not look it — an unmaterialised frontier, preconditions that are not issues, parent blocking the tracker does not inherit. Reports and proposes exact writes; never mass-edits.
---

Run `tracker-frontier-audit` over this project's tracker and report what it finds.

This command exists because the owner is the one who looks at the board, and an agent that
must *remember* to check it will not. Its measured history: a project ran six merges without
the audit firing once, and the first run found a ticket reported to stakeholders as blocked
that had never had a blocking edge at all.

Report every check, including the ones that found nothing — a check that reports only when it
fires cannot be told from a check that did not run. Propose writes; make none without the
owner saying so.
