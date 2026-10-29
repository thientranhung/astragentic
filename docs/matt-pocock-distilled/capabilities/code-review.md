# Code review — distilled

> From `skills/engineering/code-review/SKILL.md` (model-invocable). Two-axis review of the diff
> between `HEAD` and a fixed point: **Standards** (repo's documented coding standards + a Fowler
> smell baseline) and **Spec** (does the code implement what the issue/spec asked?). Both axes run
> as **parallel sub-agents** so they do not pollute each other's context.

## Process
1. **Pin the fixed point** (SHA, branch, tag, `main`, `HEAD~5`); ask if none given. Diff is
   `git diff <fixed>...HEAD` (merge-base), commits `git log <fixed>..HEAD --oneline`. Confirm the ref
   resolves and the diff is non-empty before spawning anything.
2. **Identify the spec**: issue refs in commit messages → a path the user passed → a file under
   `docs/`, `specs/`, `.scratch/` matching the branch → ask. None: the Spec sub-agent is skipped and
   says so.
3. **Identify the standards sources**: every file documenting how code is written
   (`CODING_STANDARDS.md`, `CONTRIBUTING.md` must be on the list when present). On top, always the
   **smell baseline**; two rules bind it: the repo overrides (a documented standard wins, suppress the
   smell it endorses), and every smell is a judgement call, never a hard violation. Skip anything
   tooling already enforces.
4. **Spawn both sub-agents together, foreground**, each under 400 words:
   - Standards: per file/hunk, (a) every documented-standard violation, citing file + rule; (b) any
     baseline smell, named, hunk quoted; hard violations distinguished from judgement calls.
   - Spec: (a) requirements missing or partial; (b) behaviour not asked for (scope creep);
     (c) requirements that look implemented but wrong. Quote the spec line per finding.
5. **Aggregate** under `## Standards` and `## Spec`, verbatim or lightly cleaned. **Do not merge or
   rerank across axes.** End with one line: findings per axis, worst issue *within* each axis. Never
   pick a single winner across axes.

## Smell baseline (Fowler, *Refactoring* ch. 3), each "what → fix"
Mysterious Name → rename · Duplicated Code → extract the shared shape · Feature Envy → move the
method onto the data · Data Clumps → bundle into one type · Primitive Obsession → give the concept
its own small type · Repeated Switches → polymorphism or one shared map · Shotgun Surgery → gather
what changes together · Divergent Change → split by reason to change · Speculative Generality →
delete, inline until a real need · Message Chains → hide the walk behind one method · Middle Man →
cut it · Refused Bequest → composition over inheritance.

## Why two axes
Code that follows every standard but implements the wrong thing: Standards pass, Spec fail. Code
that does what the issue asked but breaks conventions: Spec pass, Standards fail. Reporting them
separately stops one axis masking the other.
