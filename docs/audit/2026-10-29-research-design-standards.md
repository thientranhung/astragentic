# Research: shared standards for AI agents and UI design systems (as of 2026-10-29)

Read-only web research. Facts with source URLs, no recommendations. Claims marked "unverified" come from secondary sources only.

Of the standards surveyed, only Google's DESIGN.md and DTCG are open, text-based specs with their own tooling. DESIGN.md is Google-owned and still alpha. DTCG is a W3C Community Group format, not a W3C Standard. Nothing from Anthropic, Figma or Vercel is a repo-storable format under a public spec, apart from the shadcn registry, `components.json` and Storybook manifests.

## 1. Google DESIGN.md

**What it is.** A file with YAML front matter (tokens) plus a Markdown body (rationale). The README says "Tokens give agents exact values. Prose tells them why."
- Spec status: version `alpha`, Apache-2.0, owned by Google Labs, incubated from Stitch.
- Announced on the Google Labs blog on 2026-04-21 ([blog.google](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-design-md/)). That post names no tool except Stitch.
- Repo: [github.com/google-labs-code/design.md](https://github.com/google-labs-code/design.md), spec at `docs/spec.md`.

**Schema** (from the [README](https://raw.githubusercontent.com/google-labs-code/design.md/main/README.md) and [spec.md](https://raw.githubusercontent.com/google-labs-code/design.md/main/docs/spec.md)):
- Top-level keys: `version`, `name`, `description`, `omitted`, `colors`, `typography`, `rounded`, `spacing`, `components`.
- References use `{colors.primary}`. Colors accept any CSS color string, hex recommended.
- Dimensions use px, em or rem. Typography objects carry `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`, `fontFeature`, `fontVariation`.
- Component properties are limited to `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`.
- Variants are sibling keys such as `button-primary-hover`. The spec says "The agent will consider all variants."
- Body sections must appear in this order: Overview, Colors, Typography, Layout, Elevation & Depth, Shapes, Components, Do's and Don'ts.
- Unknown sections are preserved. Duplicate sections or duplicate top-level YAML keys are errors.

**Tooling** (`npx @google/design.md`, bin alias `designmd`):

| Command | Behavior | Exit code |
|---|---|---|
| `lint` | JSON findings with severity, path, message | 1 if errors, else 0 |
| `diff a b` | Token-level and finding-delta JSON with a `regression` flag | 1 if more errors or warnings after |
| `export --format` | `json-tailwind` (v3), `css-tailwind` (v4 `@theme`), `dtcg` | 0 ok, 1 bad format or emitter error, 2 unreadable input |
| `spec [--rules]` | Prints the spec or rules table for prompt injection | Not documented |

There are 11 lint rules:
- Error: `broken-ref`.
- Warning: `missing-primary`, `contrast-ratio` (WCAG AA 4.5:1 on component background/text pairs), `orphaned-tokens`, `missing-typography`, `section-order`, `unknown-key`, `token-like-ignored`.
- Info: `token-summary`, `missing-sections`, `omitted-rules`.

A TypeScript library API (`lint(markdown)`) also exists.

**Adoption evidence** (measured 2026-10-29 via `gh` and the npm API):

| Measure | Value |
|---|---|
| Repo created | 2026-04-10 |
| Stars / forks | 28,626 / 2,274 |
| Latest npm release | 0.4.0 (2026-07-27); earlier 0.2.0, 0.3.0 |
| npm downloads, 2026-10-21 to 10-27 | 390,741 |

**Who reads or writes it.**
- Stitch exports and imports it. Google: Stitch "lets you export or import your design rules from project to project." Stitch 3.0 importing from a codebase, Figma or a live site comes from third-party posts only.
- [google-labs-code/stitch-skills](https://github.com/google-labs-code/stitch-skills), 8,632 stars: Agent Skills and plugins for Codex, Antigravity, Gemini CLI, Claude Code, Cursor, OpenCode, driven by the Stitch MCP server.
- Impeccable writes and reads it. Its `document` command says it follows "the official DESIGN.md format spec" and keeps shadows, motion and focus rings in a sidecar, since the 8 component properties cannot hold them.
- BMAD-METHOD (54,696 stars): `bmad-ux` produces DESIGN.md "per the Google Labs spec" plus a peer EXPERIENCE.md ([skill](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-ux/SKILL.md)).
- Bolt carries the file along in its Stitch export ([bolt.new](https://bolt.new/blog/bolt-stitch-integration)).

**Community collections.**

| Collection | Facts | Source |
|---|---|---|
| VoltAgent/awesome-design-md | 124,282 stars, pushed 2026-10-28 | [repo](https://github.com/VoltAgent/awesome-design-md) |
| getdesign.md | Maintained by the VoltAgent team. UI advertises a "550+" website catalog and paid products (Private DESIGN.md, Catalog Pass). | [getdesign.md](https://getdesign.md/what-is-design-md) |
| VoltAgent/awesome-claude-design | 4,243 stars, 68 files. Claims "Upload any DESIGN.md to Claude Design" scaffolds a full system. | [repo](https://github.com/VoltAgent/awesome-claude-design) |
| designmd.co | HTTP 403 to my fetch. Not verified. | none |
| designmd.app | Advertises 759 files. Unverified. | [designmd.app](https://designmd.app/) |

Star counts and file counts differ across sources and dates.

## 2. W3C Design Tokens Community Group (DTCG)

**Status.** First stable version, "Design Tokens Format Module 2025.10", published 2025-10-28 as a Final Community Group Report ([announcement](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/), [spec](https://www.designtokens.org/tr/2025.10/format/)). The report states it "is not a W3C Standard nor is it on the W3C Standards Track." Separate Color Module and Resolver Module reports also carry 2025.10.

**Format** (from the spec):
- Extension `.tokens` or `.tokens.json`. Media type `application/design-tokens+json`; `application/json` also allowed.
- A token is an object with `$value`. Other properties: `$type`, `$description`, `$extensions` (reverse-domain keys, which tools must preserve), `$deprecated`.
- Groups have no inherent meaning. They support `$type` inheritance, `$extends` (deep merge) and a `$root` token.
- Aliases use `{a.b}`. Property-level access uses `$ref` with JSON Pointer. Circular references are errors.
- Tools "must not guess a type from the value."
- Composite types: strokeStyle, border, transition, shadow, gradient, typography.
- Color is an object with `colorSpace`, `components`, optional `alpha`, optional `hex`. Dimension is `{value, unit}` with `px` or `rem`.
- Theming and multi-brand support live in the separate Resolver Module, which I did not read.

**Tool support.**
- The W3C community page claims support from Figma, Penpot, Sketch, Tokens Studio, Style Dictionary and Terrazzo ([w3.org](https://www.w3.org/community/design-tokens/2026)). That is the group's own claim, not a parity test.
- Style Dictionary v4 has "first-class support for the DTCG format." Its docs say 2025.10 is "not fully supported yet", with completion in progress for v5 ([docs](https://styledictionary.com/info/dtcg/)).
- Penpot: a community post found the export is Tokens Studio's multi-set format, not DTCG 2025.10 ([Penpot forum](https://community.penpot.app/t/token-export-is-tokens-studio-format-not-dtcg-2025-10/10544)).
- Figma: a forum thread says native DTCG variable export and import was announced at Schema 2025 and still rolling out in November 2025 ([forum](https://forum.figma.com/ask-the-community-7/native-variable-export-feature-47831)). A secondary guide dated 2026-10-23 says Figma exports DTCG-aligned JSON, with Figma data under `$extensions.com.figma` ([atomize.tools](https://atomize.tools/blog/figma-variables-export-json/)). Figma's own variables help article mentions neither JSON nor DTCG.

**Relation to DESIGN.md.** The DESIGN.md README says its tokens are "inspired by" the DTCG format, and `export --format dtcg` converts one into the other. The syntax differs: DESIGN.md has no `$value`/`$type`, and references plain strings with `{colors.primary}`.

## 3. Figma for agents

**Figma MCP server** ([docs](https://developers.figma.com/docs/figma-mcp-server/)):
- The remote server is at `https://mcp.figma.com/mcp`. A desktop server also exists and needs a Dev or Full seat.
- Write to canvas is free during beta and "will later become usage-based."
- Read tools include `get_design_context`, `get_variable_defs`, `get_code_connect_map`, `get_metadata`, `get_screenshot`, `search_design_system`, `get_libraries`.
- Write tools include `use_figma`, `add_code_connect_map`, `generate_figma_design`, `html_to_figma`, `send_code_to_figma` ([tools list](https://developers.figma.com/docs/figma-mcp-server/tools-and-prompts/)).
- One MCP prompt, `create_design_system_rules`, writes a rules file.
- Server "skills" are instructions on which tools to call and in what order. A `figma-spec` skill reads and updates team specs (open beta).

**Rules files.** Figma tells users to put rules in `CLAUDE.md` for Claude Code or `.cursor/rules` for Cursor. It does not mention AGENTS.md ([page](https://developers.figma.com/docs/figma-mcp-server/add-custom-rules/)). Examples:
- "IMPORTANT: Always use components from `/path_to_your_design_system`."
- Prefer Figma tokens over hardcoded values.
- Run `get_design_context`, then `get_screenshot`, then implement and validate.

**Code Connect** ([docs](https://developers.figma.com/docs/code-connect/)):
- Maps Figma components to repo components using `*.figma.ts` template files. Legacy parsers cover React, HTML, SwiftUI, Compose.
- Available on Dev or Full seats from the Professional plan upward. Professional allows one active framework.
- The page does not say where connections are stored, and notes CLI-created connections "can only be edited in the CLI." A secondary source says Organization or Enterprise only (unverified; conflicts with Figma's page).

**Variables REST API** ([docs](https://developers.figma.com/docs/rest-api/variables/)):
- Endpoints: GET local, GET published, POST. Scopes: `file_variables:read`, `file_variables:write`.
- Needs a Full seat in an Enterprise org.

**Figma Make.** A Make kit starts with a guidelines folder holding at least one Markdown file (`Guidelines.md`) ([help](https://help.figma.com/hc/en-us/articles/39241689698839)). Make can generate guidelines (costs AI credits) or the user writes them. Design system packages must be React 18 and Vite-compatible. A July 2026 forum post reports Make followed the guidelines yet generated a new Dialog instead of reusing the kit's.

**Repo-storable text.** Code Connect `*.figma.ts` files and a rules file in CLAUDE.md or Cursor rules. Make's `Guidelines.md` lives inside the kit, not necessarily in the app repo.

## 4. Anthropic: Claude Design and `frontend-design`

**Claude Design** ([get started](https://support.claude.com/en/articles/14604416-get-started-with-claude-design), [set up a design system](https://support.claude.com/en/articles/14604397-set-up-your-design-system-in-claude-design)):
- A design system consists of "guide, tokens, and components." Each becomes "an artifact Claude can use in any chat, including in Claude Code."
- Import sources: a GitHub repo, design files, raw uploads, or "your local codebase."
- In Claude Code, `/design-sync` "reads your tokens and components directly" and checks output against the system.
- `/design` imports a design into the codebase, exports code as a live prototype, or builds the whole thing.
- Exports: .zip, PDF, PPTX, Google Slides, standalone HTML; sends to Canva, Miro, Vercel, Netlify, Wix; handoff to Claude Code.
- The support articles name no token file format and do not mention DESIGN.md. The only DESIGN.md claim I found is community-sourced (awesome-claude-design).
- Checking is manual: build a test project and "check whether the output matches your brand." No automated validation is described.
- The standalone claude.ai/design closes on December 14, 2026. Enterprise plans get Claude Design on by default on October 15, 2026.
- A secondary article gives an MCP setup command, `claude mcp add --scope user --transport http claude-design https://api.anthropic.com/v1/design/mcp`, with `/design-login` ([horadecodar](https://horadecodar.com.br/claude-design-claude-code/)). The official page does not mention it.

**`frontend-design` skill** ([SKILL.md](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md), repo `anthropics/skills`, 184,524 stars):
- Latest commits to the file: 2026-09-03 ("avoid generic design defaults") and 2026-06-09.
- Format: one `SKILL.md` with name and description frontmatter. No schema, linter, token format or checker.
- Sets a role: "design lead at a design studio" for a client that rejected "cliché or templated" proposals.
- Lists what generated pages cluster around, and says these are defaults rather than choices unless the brief asks for them:
  1. Cream background (near #F4F1EA) with serif display and terracotta accent (near #D97757).
  2. Near-black background with one acid-green or vermilion accent.
  3. Broadsheet layout, hairline rules, zero radius.
  4. "SaaS-card kit": identical rounded cards, one radius, the same soft grey shadow, gradient washes.
  5. Template chrome: tracked ALL-CAPS eyebrow labels, middle-dot meta strings, "WORD — fragment" labels, tinted near-black, monospace data labels, "→" on links.
- Typography: line length under 80 characters. Avoid accenting one word of a headline, all-caps labels, unnecessary labels above content.
- Numbered markers only for real sequences. Motion: one orchestrated moment; fade-and-slide on every section is named generic.
- Process: write a compact token plan first (4-6 named hex colors, type roles, layout, principles), review it against the brief, then build.
- Quality floor: responsive to mobile, visible keyboard focus, reduced motion respected.
- Copy: "Save changes" not "Submit"; errors name the problem and the fix.

## 5. shadcn/ui, v0, Storybook

**shadcn registry and `components.json`.**
- `registry-item.json` types: `registry:base` ("entire design systems"), `block`, `component`, `font`, `lib`, `hook`, `ui`, `page`, `file`, `style`, `theme`, `item` ([spec](https://ui.shadcn.com/docs/registry/registry-item-json)). Items can carry `cssVars` with `theme`, `light`, `dark` maps.
- `registry.json` at a registry root is the index the MCP server reads. Namespaces such as `@acme` map to URL templates in `components.json` ([registry MCP](https://ui.shadcn.com/docs/registry/mcp)).
- `components.json` has a published schema at `https://ui.shadcn.com/schema.json`. It holds `style`, `tailwind.cssVariables`, `tailwind.baseColor`, `aliases`, `registries` ([docs](https://ui.shadcn.com/docs/components-json)).
- The shadcn skill (`npx skills add shadcn/ui`) runs `shadcn info --json` on every interaction to get framework, aliases, installed components, icon library, base library ([skills](https://ui.shadcn.com/docs/skills)).
- CLI commands: `init`, `add`, `search`, `view`, `docs`, `diff`, `info`, `build`. The repo has 126,836 stars.

**v0.**
- Legacy path: a shadcn-based registry ("a distribution specification designed to pass context from your design system to AI Models"). v0 reads Tailwind configs and `globals.css` ([v0 docs](https://v0.app/docs/design-systems)).
- Design Systems 2.0 saves the design system as a skill ([page](https://v0.app/docs/design-systems-2)): "an adapter that tells v0 where your source lives," not a copy of docs.
- The skill is `SKILL.md` (frontmatter `v0.kind: design-system`) plus `v0.json` (version 1, up to three read-only GitHub sources, a starter setting), `assets/starter` and an optional logo.
- Inputs: npm package or archive, GitHub repos, Storybook or docs links, Figma frames, notes. The page does not mention DESIGN.md.

**Storybook** ([AI docs](https://storybook.js.org/docs/ai), [manifests](https://storybook.js.org/docs/ai/manifests), [MCP tools](https://storybook.js.org/docs/ai/mcp/api)):
- AI capabilities are "in preview" and the API "may change."
- Install with `npx storybook add @storybook/addon-mcp`. The server runs at `http://localhost:6006/mcp`.
- Two manifests: components (CSF files plus prop extraction) and docs (MDX). The components manifest is off by default (`features.componentsManifest`) and not every framework generates it.
- Raw JSON is served at `/manifests/components.json`. Its schema "is not yet stable and should not be considered a public API."
- Tools: dev (`stories-changed`, `get-storybook-story-instructions`, `stories-preview`, `stories-find-by-component`, `review-create`), docs (`docs-show`, `docs-show-story`, `docs-list`), test (`test-run`, needs the Vitest addon).
- JSDoc on components and props feeds the manifest.

## 6. Project-level AI design documents in use

| Document | Where it comes from | Evidence |
|---|---|---|
| DESIGN.md | Google spec (section 1) | 28.6k-star spec repo; 124k-star collection |
| PRODUCT.md | Impeccable. `/impeccable init` writes it. Sections: Platform, Users, Product Purpose, Positioning, Operating Context, Brand Commitments. Carries `<!-- impeccable:product-schema 1 -->`. | Impeccable repo 92,727 stars ([README](https://github.com/pbakaus/impeccable)) |
| EXPERIENCE.md | BMAD `bmad-ux`. IA, behavior, states, interactions, accessibility, journeys. References DESIGN.md tokens with `{path.to.token}`; its docs say both files win over any mock or wireframe. | BMAD 54,696 stars; CHANGELOG calls the design-to-engineering handoff "a sealed file contract" |
| CLAUDE.md or AGENTS.md design section | Figma rules guidance, Supernova blogs | Figma docs name CLAUDE.md and `.cursor/rules`; Supernova advises keeping CLAUDE.md short ([Supernova](https://www.supernova.io/blog/what-to-put-in-claude-md-for-a-design-system)) |
| Figma Make `Guidelines.md` | Figma | Help center |

- Supernova argues hand-pasted CLAUDE.md rules drift across repos and that the files are guidance, not enforced config ([Supernova](https://www.supernova.io/blog/shadcn-mcp-design-system)). It sells an MCP server (Relay) as the alternative; vendor material.
- A Design Systems Collective post reports an agent ignored a component library despite CLAUDE.md plus DESIGN.md and proposes a third file for components. Anecdotal ([post](https://www.designsystemscollective.com/i-gave-my-agent-claude-md-and-design-md-it-ignored-my-entire-component-library-c6d7e9be34d4)).
- I found no published standard called EXPERIENCE.md outside BMAD's convention.

## 7. Shared vocabulary

There is a shared base: on/container pairs, a primary/secondary/tertiary/neutral palette order, and typography categories. There is no shared standard for status roles, link color or component states.

| Concept | DTCG 2025.10 | Material 3 | shadcn | DESIGN.md |
|---|---|---|---|---|
| Token layers | None prescribed; aliases and groups carry any layering | Reference (`md.ref.palette`), system (`md.sys.color`), component (`md.comp`) | Semantic CSS variables only | Flat sections; components reference primitives |
| Text on a surface | Not defined | `on-primary`, `on-surface` | `primary-foreground`, `foreground` (surface name plain, text name `-foreground`) | Recommended `on-surface`; examples use `on-tertiary` |
| Large-area fill | Not defined | `primary-container` | Not defined | Example `tertiary-container` |
| Error or danger | Not defined | `error` | `destructive` | Recommended `error` |
| Warning, success, info, link | Not defined | Not found in sources | `warning` and `warning-foreground` in the current theming doc; no `success` or `info` found | Not defined |
| Component variants | Not defined | State layers in component tokens | Not defined | Sibling keys, `-hover` / `-active` |
| Typography | Composite `typography` type | Role scale in `md.sys.typescale` (third-party source only) | Not tokenized in theming doc | Recommended `headline-*`, `body-*`, `label-*` |

- The DESIGN.md spec says its recommended names are "Non-Normative" and palettes "may follow any consistent naming convention." Its `neutral`, `surface`, `on-surface`, `error` overlap Material 3 names. Impeccable's DESIGN.md guidance says "Don't rename to Material defaults" and leaves scale keys open-ended.
- M3 tier names come from third-party guides; the official M3 page returned only a title to my fetch ([guide](https://zoewave.medium.com/material-3-design-system-e91a15d303a0)).
- `status.*` and `text.link` are defined by none of the four. I did not survey other design systems that define them.
- Impeccable ties its detector to the DESIGN.md palette via four rules: `design-system-font`, `design-system-color`, `design-system-radius`, `design-system-font-size`.

## 8. Anti-"AI slop" rule sets

Sources: Anthropic `frontend-design` (section 4); Impeccable's craft floor and 62-rule detector ([craft-floor.md](https://github.com/pbakaus/impeccable/blob/main/skill/reference/craft-floor.md), `npx impeccable detect --list-rules`); the pixelslop catalog of 26 visual and 16 source patterns ([catalog](https://cdn.jsdelivr.net/npm/pixelslop@0.3.8/dist/skill/resources/ai-slop-patterns.md)); a survey blog listing Hallmark, avoid-ai-design, antislop, Gesso, no-slop-ui ([capitalandcompute](https://capitalandcompute.net/blog/fix-ai-slop-design/)).

| Rule | frontend-design | Impeccable | pixelslop | Survey blog |
|---|---|---|---|---|
| Identical card grids, nested cards, one radius and shadow everywhere | yes | yes (`nested-cards`; craft floor bans identical grids) | yes (7, 9, 10, 23) | yes |
| Gradient text, purple/violet or cyan-on-dark palettes | gradient washes as decoration | yes (`gradient-text`, `ai-color-palette`) | yes (1, 4, 5) | yes |
| Glass, blur and glow as decoration | no | yes (`dark-glow`, `radial-halo`, glassmorphism ban) | yes (2, 3) | yes |
| Eyebrow or kicker label above headings | yes | yes (`hero-eyebrow-chip`, `kicker-above-heading`; craft floor calls it a ban) | no | yes |
| Numbered 01/02/03 markers on non-sequences | yes | yes (`numbered-section-labels`) | no | yes |
| Cream background with serif display | yes (names near #F4F1EA) | yes (`cream-palette`, `italic-serif-display`) | no | yes |
| Hero-metric template (big number, label, stats) | yes | yes (craft floor) | yes (6) | yes (invented metrics) |
| Same entrance animation on every section; bounce easing | yes | yes (craft floor; `bounce-easing`) | yes (13) | yes |
| Overused fonts (Inter, Roboto) | tell is "default families you would reach for" | yes (`overused-font`) | yes (8; S4) | yes |
| Monospace as technical costume | yes (small data labels) | yes (craft floor) | yes (12) | yes |
| Colored side-border accent on cards | no | yes (`side-tab`) | yes (15) | no |
| Icon tile above heading | no | yes (`icon-tile-stack`) | yes (18) | no |
| Filler copy and invented figures | yes (copy rules) | yes (`marketing-buzzword`, craft-floor copy rule) | no | yes |

- Each rule above appears in at least two sources.
- The survey blog and frontend-design both describe a "second wave": banning the first defaults pushes agents to cream-plus-terracotta or near-black-plus-neon.
- Enforcement differs. frontend-design is prose only. Impeccable's detector and the avoid-ai-design scanner are deterministic. Impeccable's `detect` exits 2 on findings and 1 if a target cannot be scanned. avoid-ai-design's scanner exits 2 on any P0 or P1 finding (survey blog only). Impeccable also installs an edit hook for Claude Code, Cursor, Codex, Copilot, Grok Build, Hermes Agent.
- Impeccable's contrast floor (body text at or above 4.5:1, large text at or above 3:1) matches the WCAG AA check in the DESIGN.md linter.

## Summary table

| Artefact | Owner | Machine-checkable | Read by | Adoption evidence |
|---|---|---|---|---|
| DESIGN.md | Google Labs, alpha | Yes: `lint` (exit 1 on errors), `diff` (exit 1 on regression), `export` | Stitch, Impeccable, BMAD, Bolt, stitch-skills agents; Claude Design community-claimed only | 28.6k-star spec repo; 390,741 npm downloads in one week; 124k-star collection |
| DTCG `.tokens.json` | W3C DTCG, Final CG Report, not a Standard | Spec-level rules only; no official CLI or linter found | Style Dictionary v4 (2025.10 incomplete), Tokens Studio, Penpot (export differs), Figma (unclear) | Group lists Figma, Penpot, Sketch, Tokens Studio, Style Dictionary, Terrazzo |
| Figma MCP plus rules file | Figma | No; server has no lint or exit codes; rules file is free text | Claude Code, Cursor and other MCP clients | Docs only; no usage numbers found |
| Code Connect `*.figma.ts` | Figma | Partly: publish via CLI; tests unknown | Figma MCP `get_code_connect_map` | Paid plans only |
| Figma Variables REST API | Figma | API schema only | Scripts, plugins | Enterprise Full seat |
| Claude Design design system | Anthropic | No; checking is manual by test project | Claude Design, Claude Code via `/design-sync` | Standalone shuts down 2026-12-14; no usage numbers found |
| `frontend-design` SKILL.md | Anthropic | No; prose only | Claude agents with the skill | 184.5k stars on `anthropics/skills` |
| shadcn `registry.json`, `components.json` | shadcn/ui | Yes: published JSON Schemas; CLI `diff`, `info`, `build` | shadcn CLI, MCP server, skill, v0 (legacy) | 126.8k stars |
| v0 design-system skill | Vercel | Validated before save (per its doc page) | v0 | Docs only |
| Storybook manifests plus MCP | Storybook | Partly: JSON manifests, `test-run` tool; schema unstable | Storybook MCP agents | "Preview" status; no counts |
| PRODUCT.md | Impeccable | Marker comment only; no linter found | Impeccable commands | 92.7k stars on Impeccable |
| Impeccable detector | Impeccable | Yes: 62 rules; exit 2 findings, 1 unscannable | Edit hook, CI (`--github`, `--json`), Chrome extension | 92.7k stars; `design-system-*` rules compare code to DESIGN.md |
| EXPERIENCE.md | BMAD convention | No schema or linter found | BMAD agents | 54.7k stars on BMAD |
| CLAUDE.md / AGENTS.md design section | Per repo | No | Claude Code and others | Figma docs and Supernova blogs recommend it |
| Figma Make `Guidelines.md` | Figma | No | Figma Make | Help-center docs; one forum report of ignored guidelines |

Gaps: could not verify designmd.co, Stitch's own DESIGN.md docs page, the official Material 3 token docs, Figma's native DTCG export, or whether Claude Design reads DESIGN.md.
