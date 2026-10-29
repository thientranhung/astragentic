# UI/UX skills, plugins and MCP servers: inventory (2026-10-29)

Read-only research. Two things were run: `@google/design.md lint` on a planted defect, and `ui-ux-pro-max` search. Everything else is read from READMEs, source files and docs, not run. GitHub star counts read on 2026-10-29 with `gh api`.

## 1. Anthropic official

**`frontend-design` skill**
- Installed here as plugin 1.1.1 from `claude-plugins-official`. File: `/Users/tranthien/.claude/plugins/marketplaces/claude-plugins-official/plugins/frontend-design/skills/frontend-design/SKILL.md`, 9.4 KB. Text matches `anthropics/skills` main.
- Prose only. No output document, no script, no exit code.
- Tells the model to work as a design lead for a client who rejects clichés. Ground the design in the subject, write a short token plan (4-6 named hex colours, type roles, layout, principles), review the plan against the brief before coding.
- Names five default clusters to avoid:
  - cream background with serif and terracotta `#D97757`;
  - near-black with one acid accent;
  - broadsheet hairlines with zero radius;
  - SaaS cards with one radius and one shadow;
  - template chrome (all-caps eyebrow, middle-dot meta strings, `WORD — fragment` labels, `→` on links, monospace labels).
- Also bans a single accented word in a headline, all-caps labels, and `01/02/03` markers unless the content is a sequence.
- Motion allowed as one orchestrated moment only.
- Quality floor: responsive, visible focus, reduced motion, contrast. Self-critique by screenshot if the environment supports it.
- A third of the file is UX-writing rules: verbs on buttons, one name per action, errors that do not apologise.
- This version lists no fonts or colours to avoid beyond `#D97757`. Third-party write-ups claim Inter, purple gradients and emoji are named. That is not in the current text.
- Other skills in `anthropics/skills` touching design (names only, unread): `canvas-design`, `theme-factory`, `brand-guidelines`, `web-artifacts-builder`, `webapp-testing`.

**`/design` and `/design-sync`** (found in the Claude Code 2.1.312 binary strings, not in public docs fetched)
- `/design` drives Claude Design (claude.ai/design). Subcommands: `sync`, `login`, `consent`, `revoke`, `import`, `export`, `status`.
- `/design-sync` pushes a local design system. Uses `.design-sync/config.json` and `.design-sync/previews/`. The app builds its card index from a `<!-- @dsCard group="..." -->` first line in each preview, compiled to `_ds_manifest.json`. A Storybook probe script path appears in the strings.
- A changelog line in the binary says standalone Claude Design (claude.ai/design) closes by December 14, 2026.
- A 403 error text mentions needing Claude Design access on the account. Neither command was run.

**`dataviz`**
- Bundled skill. No local file found.
- Its listed description mentions a "runnable validator" for the colour formula. The script was not seen.

**`claude-plugins-official` marketplace** (local snapshot, design-related entries)
- `figma`, `frontend-design`, `canva`, `adobe-for-creativity`, `browser-use`, `chrome-devtools-mcp`, `modern-web-guidance`, `liquid-skills` (includes WCAG patterns), `pendo-guides`.
- `playwright` is under `external_plugins` and runs `npx @playwright/mcp@latest`.
- No `impeccable` entry in that snapshot.
- Built-in tips in the binary suggest `frontend-design` and `playwright` when frontend code is detected.

## 2. Community skills and plugins

**DESIGN.md**
- `google-labs-code/design.md`: 28,626 stars, Apache-2.0. Spec plus CLI: `lint`, `diff`, `export` (Tailwind v3 and v4, W3C design-tokens format), `spec --rules`.
  - Reads a `DESIGN.md` with YAML tokens and prose. Writes JSON findings to stdout.
  - `lint` has eleven rules, severity error / warning / info. Run on a planted file with `{colors.nope}`: printed JSON naming `broken-ref` as an error, exit 1. Documented exit codes: `lint` 1 on error, `diff` 1 on regression, `export` 2 on unreadable input.
- `VoltAgent/awesome-design-md`: 124,282 stars. Collection of brand `DESIGN.md` files. Content, not a checker.
- `ShriPunta/generate-design-md`: 2 stars. Generates and validates through Google's linter.
- `albertzhangz10/design-system-skill`: 42 stars. `wenyen-hsu/design-md-skill`: 11 stars. Neither has a lint step.
- `google-labs-code/stitch-skills`: 8,632 stars. Installed here as `stitch-design` and `stitch-utilities` 1.0.0, ten skills (`extract-design-md`, `design-md`, `taste-design`, `generate-design` and others). They need the Stitch MCP server.

**Design and anti-slop skills**
- `nextlevelbuilder/ui-ux-pro-max-skill`: 142,094 stars. Source of the local skill.
- `Nutlope/hallmark` (Together AI, MIT): 40,741 stars. 16-point "Floor" of rules and tiered gates (FAIL, REFLEX, finish). `scripts/sloplint.mjs` is 4,422 lines, has `--json`, an optional `--render` browser pass at eight widths, and `--before` / `--kept` modes that fail a redesign if links, fields or handlers go missing. Exits 2 on usage errors and sets an exit code from findings. Verbs `audit` and `redesign`. Optional edit-time hook installer.
- `Leonxlnx/taste-skill` (MIT): 104,503 stars. `lint.mjs` and `inspect.mjs`. `lint.mjs --json` prints `{files, findings}` and exits 1 on any FAIL. Needs Node 22+ and Chrome.
- `bitjaru/styleseed`: 993 stars. Render, score, revise loop. README claims +5.3 points on 120 rendered benchmark cells and says a score does not replace human acceptance.
- `superdesigndev/superdesign-skill`: 912 stars.
- `vercel-labs/agent-skills`: 33,169 stars. Includes `web-design-guidelines`: fetches Vercel's rule list at review time, outputs terse `file:line` text findings. Prose, not JSON.
- No skill with real adoption found for accessibility audits, UI critique or Storybook. Best hit: `CFLW-AI/wcag-audit-claude-skill`, 8 stars. Figma skill repos were all under 100 stars.

**Browser and visual QA**
- `microsoft/playwright-mcp`: 38,774 stars. `ChromeDevTools/chrome-devtools-mcp`: 54,369. `vercel-labs/agent-browser`: 44,782. `browser-use/browser-use`: 119,407.
- agent-browser has `screenshot --if-changed` and `--threshold 0.01`. These skip unchanged images. They are not a diff score.

## 3. Local inventory details

**`ui-ux-pro-max`**
- `/Users/tranthien/.claude/skills/ui-ux-pro-max`. `SKILL.md` 16 KB. Model-invoked (no disable flag). Runs `python scripts/search.py`.
- Counts from `data/catalog-summary.json` (verified 2026-08-13):

| Data | Count |
|---|---|
| Styles | 88 (79 searchable, 50 active) |
| Palettes and reasoning profiles | 192 |
| Font pairings | 74 |
| UX guidelines | 119 |
| Curated icons | 105 |
| GSAP presets | 17 |
| Chart types | 25 |
| Stacks (1,260 guidelines) | 22 |
| Google Fonts | 1,934 |

- Query modes: `--design-system`, `--domain`, `--stack`. Dials `--variance`, `--motion`, `--density` tune design-system output.
- `--design-system --persist --output-dir <root>` writes `design-system/<slug>/MASTER.md` and a `pages/` folder. `--json` prints a machine-readable dict.
- Run: `search.py "ops dashboard" --design-system --json` exited 0 and returned category "General", pattern "Hero + Features + CTA". That is a marketing-page pattern for a dashboard query.
- Does not inspect rendered output. The only integrity check, `validate_data.py`, checks the data files.

**Other local items**
- `astraler-ui-anti-slop`: `/Users/tranthien/Documents/2.DEV/my-skills/skills/astraler-ui-anti-slop`. `SKILL.md` 266 lines, 16 KB, five reference files including `audit-checklist.md`. No script. Step 4 is a manual audit.
- `bmad-ux`: 3.6 KB. Found only in harness copies under `/tmp`, e.g. `/private/tmp/tra1278fulltree/.claude/skills/bmad-ux`. Reads `DESIGN.md`, `EXPERIENCE.md` and the rendered surface. Reports in prose.
- `moda-website`, `moda-mockup`, `moda-brand`, `moda-chart` and other `moda-*`: symlinks into `.agents/skills`, 5-9 KB each. Call the Moda cloud product.
- impeccable 4.8.0 installed. `plugin/skills/impeccable/SKILL.md` 12 KB, user-invocable. `reference/craft-floor.md` carries its verify list and bans.
- `agent-browser`: 3.3 KB.

## 4. MCP servers and what an agent can assert on

- **Figma MCP (official)**: `figma@claude-plugins-official`, or `claude mcp add --transport http figma https://mcp.figma.com/mcp`.
  - `get_design_context` returns React and Tailwind for the selection.
  - `get_variable_defs` returns colour, spacing and type variables.
  - `get_metadata` returns a node map. `get_screenshot` returns an image.
  - Also `generate_image`, `upload_assets`, Code Connect, and a remote-only write-to-canvas mode.
  - Token values can be compared to code. Nothing returns pass or fail.
- **shadcn MCP**: `shadcn@latest mcp init --client claude`.
  - Browses, searches and installs registry items, including private and `@namespace` registries.
  - The docs page does not name tools or the return format.
- **Storybook MCP**: `@storybook/addon-mcp`. Repo `storybookjs/mcp` (271 stars) has moved into `storybookjs/storybook` (91,400). Ten tools.
  - `test-run` runs story tests and returns results including accessibility issues when a11y checks are configured.
  - `docs-show` returns props and stories. `stories-changed` lists affected stories.
  - The `docs-*` tools need a components manifest that only some frameworks generate.
- **Playwright MCP**: `browser_snapshot` returns an accessibility tree. `browser_take_screenshot` returns an image. Also `browser_console_messages`, `browser_network_requests`, `browser_evaluate`. Assertions are whatever the agent computes from those outputs. Playwright's own `toHaveScreenshot` diff (not run) lives in the test runner, not the MCP.
- **Chrome DevTools MCP**: `take_snapshot`, `take_screenshot`, `get_css_styles`, `list_console_messages`, `evaluate_script`, `performance_start_trace`, `performance_analyze_insight`. `lighthouse_audit` is in the tool reference. Output schema not checked.
- **Lighthouse and axe wrappers**
  - `danielsogl/lighthouse-mcp-server`: 73 stars.
  - `ronantakizawa/a11ymcp` (axe-core): 94 stars, last pushed 2026-03-10.
  - Deque documents its own axe MCP server. Output schema not seen.
  - `GoogleChrome/lighthouse-ci` (7,120 stars) and `axe-core` (7,725) are the underlying engines. Lighthouse CI assertions and axe CLI exit non-zero on failure. From documentation, not run here.

## 5. Anti-slop rules appearing in two or more sources

Source key: FD = Anthropic `frontend-design` 1.1.1. HM = Hallmark. IMP = impeccable `craft-floor.md`. AST = `astraler-ui-anti-slop`. UXP = `ui-ux-pro-max`. PAR = https://www.paralect.com/blog/signs-of-ai-slop-in-design. MAN = https://www.mania.design/blog/spot-the-slop-a-ui-designers-guide-to-fixing-ai-defaults/ (2026-07-23). 925 = https://www.925studios.co/blog/ai-slop-design-tells.

| Rule | Sources |
|---|---|
| No eyebrow or all-caps tracked label above headings | FD, HM (rule 9), IMP (a ban), PAR |
| No purple or indigo to blue gradient | HM (rule 11), PAR, MAN, 925 |
| No gradient text or single accented word in a headline | FD, HM (rule 3), IMP, PAR |
| No identical rounded cards, same radius and shadow everywhere | FD, IMP, PAR, MAN, 925 |
| No card inside a card | HM (rule 11), IMP |
| No emoji as icons; one icon set | HM (rule 11), IMP, PAR, UXP |
| No coloured left-border stripe on cards or callouts | IMP, PAR, MAN |
| Glass and blur only with a purpose | IMP, PAR |
| Monospace only for code and data | FD, IMP, PAR |
| `01 / 02 / 03` markers only for real sequences | FD, IMP |
| No hero-metric template (big number, small label, stats) | FD, IMP |
| Middle-dot meta strings and arrows on links are chrome | FD, HM (rule 10) |
| Motion: one authored moment, reduced-motion fallback, nothing decorative | FD, HM (rule 7), IMP, PAR, MAN |
| Body contrast at least 4.5:1 | HM, IMP, PAR, UXP |
| Visible keyboard focus | FD, HM (rule 6), UXP |
| No invented metrics, testimonials or logos | HM (rule 8), PAR |
| Design empty, loading and error states | AST (R8), IMP, MAN |
| Avoid Inter as the default face | MAN, 925, HM (display font from a catalog) |
| Buttons name their action; errors name the fix | FD, IMP, AST (R10), MAN |

## 6. Advisory prose versus machine-checkable

- **Prose only:** `frontend-design`, `astraler-ui-anti-slop`, `bmad-ux`, `web-design-guidelines`, the `moda-*` skills, the Stitch skills (which also need the Stitch service).
- **Machine check on the design spec:** `@google/design.md lint`. JSON findings with severity, rule name and path, exit 1 on error. Verified by a planted defect.
- **Machine check on code or render:** Hallmark `sloplint.mjs` and taste-skill `lint.mjs`. Read from source, not run.
- **Machine data, no verdict:** `ui-ux-pro-max` returns JSON from `--design-system --json` but only recommends.
- **Raw evidence for an agent to judge:** Playwright, Chrome DevTools and Figma MCP outputs.
- **Pass/fail from the tool itself:** Storybook `test-run` with a11y configured, `lighthouse_audit`, the axe and Lighthouse CI engines. Exit codes documented, not run.

## Table (a): local inventory

| Item | Path | Size | Invocation | Purpose | Reads / writes | Machine-checkable |
|---|---|---|---|---|---|---|
| frontend-design 1.1.1 | `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/frontend-design` | 9.4 KB | Model | Distinctive design, anti-default calibration | Writes code only | No |
| impeccable 4.8.0 | `~/.claude/plugins/marketplaces/impeccable/plugin/skills/impeccable` | 12 KB | User and model | Design, critique, polish, DESIGN.md | Not examined | Not examined |
| astraler-ui-anti-slop | `/Users/tranthien/Documents/2.DEV/my-skills/skills/astraler-ui-anti-slop` | 16 KB, 5 refs | Model | Astraler rules R1-R10 and audit | Reads tokens and spines, writes spine rows | No |
| ui-ux-pro-max | `~/.claude/skills/ui-ux-pro-max` | 16 KB plus data | Model | Searchable design intelligence | Reads CSVs; `--persist` writes `design-system/<slug>/MASTER.md` | JSON output, no verdict |
| bmad-ux | harness copies, e.g. `/private/tmp/tra1278fulltree/.claude/skills/bmad-ux` | 3.6 KB | User (`/bmad-ux`) | Sally audit, polish, upgrade | Reads DESIGN.md, EXPERIENCE.md, render | No |
| stitch-design (6), stitch-utilities (4) | `~/.claude/plugins/cache/google-labs-code-stitch-skills` | 3-14 KB each | Model | Stitch screens and DESIGN.md | Stitch MCP, local code | No |
| moda-website, mockup, brand, chart | `~/.claude/skills/moda-*` | 5-9 KB | Model | Moda cloud artifacts | Moda service | No |
| agent-browser | `~/.claude/skills/agent-browser` | 3.3 KB | Model | Browser automation | Screenshots, accessibility tree | Screenshot threshold only |
| dataviz | bundled, no local file found | n/a | Model | Chart design | Not examined | Validator mentioned, not seen |

## Table (b): external candidates

| Candidate | Owner | Stars | Reads / writes | Machine-checkable |
|---|---|---|---|---|
| `@google/design.md` lint, diff, export | Google Labs | 28,626 | DESIGN.md in, JSON out | Yes, JSON and exit 1 (verified) |
| Hallmark `sloplint.mjs` | Together AI | 40,741 | HTML, CSS, JSX, rendered pages | Yes, FAIL / REFLEX / WARN and exit code (source) |
| taste-skill `lint.mjs`, `inspect.mjs` | Leonxlnx | 104,503 | Source files, real browser | Yes, `--json`, exit 1 on FAIL (source) |
| styleseed | bitjaru | 993 | Project rules, renders | Render score, per its README |
| ui-ux-pro-max-skill | nextlevelbuilder | 142,094 | CSV data, MASTER.md | JSON recommendations only |
| web-design-guidelines | Vercel | 33,169 (repo) | Source files | No, `file:line` text |
| awesome-design-md | VoltAgent | 124,282 | Brand DESIGN.md files | No |
| Figma MCP | Figma | n/a | Figma files | Raw values only |
| shadcn MCP | shadcn-ui | 126,836 | Registries | Unknown |
| Storybook addon-mcp | Storybook | 271 / 91,400 | Stories, a11y results | Yes via `test-run` |
| Playwright MCP | Microsoft | 38,774 | Live page | Evidence only |
| Chrome DevTools MCP | Google Chrome | 54,369 | Live page, traces | `lighthouse_audit`, schema unchecked |
| lighthouse-mcp-server | danielsogl | 73 | URL | Likely, unchecked |
| a11ymcp (axe) | ronantakizawa | 94 | URL | Likely, unchecked |
| Lighthouse CI | Google Chrome | 7,120 | URL | Yes, assertions and exit code (docs) |
| axe-core | Deque | 7,725 | DOM | Yes, violations JSON (docs) |
| Claude Design `/design`, `/design-sync` | Anthropic | n/a | `.design-sync/*`, claude.ai/design | Not examined |

## Unverified

- `lighthouse_audit` and axe wrapper output schemas.
- Exit codes for Lighthouse CI and axe (from documentation).
- `/design` behaviour (from binary strings only).
- Hallmark and taste-skill exit codes (from source reading).
