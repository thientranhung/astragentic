# Implement — distilled

> From `skills/engineering/implement/SKILL.md` (user-invoked, 622 bytes). Quoted whole; there is no
> shorter form.

1. Implement the work described in the spec or tickets.
2. If given a ticket reference, fetch it from the tracker and state its title before starting; if
   ambiguous, ask.
3. Call `tdd` where possible, at pre-agreed seams.
4. Run typechecking regularly, single test files regularly, the full suite once at the end.
5. Once done, call `code-review` to review the work.
6. Commit to the current branch.

In Astragentic this skill was the Builder brief's first line (`/mattpocock-skills:implement <ticket>`),
which the dispatch mod used to recognise a Builder brief; the method itself lives in `builder.md`.
