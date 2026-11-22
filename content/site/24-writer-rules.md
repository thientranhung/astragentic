## House rules for the Astragentic site (read before writing any copy)

Repo: /Users/tranthien/Documents/2.DEV/2.PRIVATE/astragentic. Site: `site/` (Astro, pnpm). Plan: `content/site/22-refresh-6.1.19.md`. **Fact sheet: `content/site/23-facts-6.1.19.md` — the ONLY allowed source of harness facts.** If a claim is not in the fact sheet or in the harness file it cites, do not write it; list it as `chưa đo` in your report.

Voice (owner rulings, binding):
- Vietnamese is primary and the only language the owner reviews. Register: standard technical Vietnamese, "tôi" (author, only to state a decision and its reason) and "bạn" (reader). Never "mình/anh em". No blog voice, no anecdotes, no rhetorical hooks, no question headings, no colloquial connectors.
- Industry terms stay English: role, session, worktree, tracker, claim, dispatch, handback, receipt, gate, frontier, contract, hook, skill, subagent, review, merge. Never a word-for-word metaphor ("lái" → "điều khiển/thao tác"; "giẫm lên nhau" → "tranh chấp").
- Each section: one-line claim, then mechanism, then measurement (`**Số đo.**` / `**Measurement.**`), then cost or limit (`**Cái giá.**` / `**Cost.**`). Paragraphs of 1–3 sentences, sentences ~12–20 words. Enumerations become bullets with a **bold lead-in**. A contrast becomes a table. Headings state the decision.
- Technique pages (tech-stack style) introduce a component: what it is, why this and not the alternative, mechanism, trade-off. Incidents are at most one clause, never the frame.
- Never name a downstream project, client, shop or vendor business. Numbers stay; identity goes.
- English twin (`en/`) updated in the same pass, faithful translation, "I/you". Vietnamese heading ids are non-ASCII; never match ids with `[a-z0-9-]`.
- Matt Pocock / BMAD / mattpocock-skills / Superpowers / OpenCode / Rin / archify are gone from the product; do not mention them except where a page is explicitly about history (none in your scope).
- Every content file you rewrite and verify against the fact sheet gets frontmatter `harness: v6.1.19` and a `source:` listing the harness paths it describes (if the collection has `source`). Files you did not verify stay unstamped.

Process: do NOT commit, do NOT deploy, do NOT touch files outside your scope (other agents are editing in parallel). Run `pnpm build` in `site/` at the end; report exit code and the `[harness-stamp]` count. Report back in under 400 words: files changed, claims you could not source (`chưa đo`), anything left undone.
