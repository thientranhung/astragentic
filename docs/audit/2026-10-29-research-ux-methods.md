# UX specification, storage and checking for AI agents, 2026

Facts only, no recommendations. "Fetched" means the source was read this session. "Background" means it was not fetched and comes from prior knowledge, so verify before citing.

## 1. Methods between user story and ticket

| Method | Artefact shape | Machine-checkable | Produced by AI toolkits |
|---|---|---|---|
| User journey / journey map | Timeline of one persona's steps, with emotions and pain points. BMAD uses numbered steps with a "climax beat". | No standard schema. BMAD's validator checks that each flow has a protagonist, numbered steps, a climax and a failure path. An LLM does that check, not a script. | BMAD (Key Flows); impeccable (critique "emotional journey"); the Astraler spine (Key Flows) |
| JTBD | Statement "When X, I want Y, so I can Z". | No. | impeccable `shape` ("Job and audience"). No toolkit with a dedicated JTBD artefact found. |
| Story mapping (Patton) | Backbone of activities, steps under it, releases as horizontal slices. Background: jpattonassociates.com. | No. | diagram-design lists a "story map" diagram type. No agent toolkit found that emits one as a ticket input. |
| Gherkin / Given-When-Then | Feature, Rule, Scenario, Given/When/Then/And/But, Background, Scenario Outline with an Examples table. | Yes, when bound to step definitions. Given is described as putting the system "in a known state". Source: https://cucumber.io/docs/gherkin/reference/ (fetched). | GitHub Spec Kit: each story carries Given/When/Then scenarios plus P1/P2/P3 priority. OpenSpec: `#### Scenario:` with GIVEN/WHEN/THEN. BMAD: ticket Requirements and the build plan's acceptance criteria. Kiro: EARS "WHEN ... THE SYSTEM SHALL" (third-party sources only). |
| UX states checklist (Hurff UI stack) | Five states per screen: ideal, error, partial, loading, blank. Blank splits into first launch, data cleared, no search results. Source: https://smart-interface-design-patterns.com/articles/how-to-fix-a-bad-user-interface/ (search result, not fetched in full). | Not as a schema. BMAD's rubric lists empty, cold-load, focus, error, offline and permission-denied per surface. The Astraler spine has a State Patterns table (R8). | BMAD State Patterns; impeccable `shape` ("States and ranges"); Astraler R8 |
| Screen inventory | Table of screens with route, entry point and purpose. | Partly. BMAD requires that every stated need has a surface and every surface has a journey (closure rule). | BMAD IA table (Surface, Reached from, Purpose). Astraler "Glance map" (Screen, Who, Must-see, Recedes). |
| IA map | Menu or route tree. | No schema found. | BMAD, Astraler spine |

## 2. BMAD Method UX workflow

The repository has two layouts.

- **v6.0.0 tag.** The workflow `create-ux-design` has 14 steps and a template `ux-design-template.md`.
  - The template is an empty shell with only frontmatter and a title.
  - The steps append sections as the user confirms each one.
- **Current main (latest release v6.12.4, 2026-10-14).** `create-ux-design` and `create-story` no longer exist.
  - The skill `bmad-ux` writes two files, `DESIGN.md` and `EXPERIENCE.md`.
  - A third file records the run.
  - Sources: `skills/bmad-ux/SKILL.md` and `references/validate.md` in https://github.com/bmad-code-org/BMAD-METHOD.

**v6.0.0 output sections**, in step order:
- Executive Summary (Project Vision, Target Users, Key Design Challenges, Design Opportunities)
- Core User Experience
- Desired Emotional Response
- UX Pattern Analysis & Inspiration
- Design System Foundation
- Defining Experience (heading list not extracted)
- Visual Design Foundation
- Design Direction Decision
- User Journey Flows (journey 1..n, Journey Patterns, Flow Optimization Principles)
- Component Strategy
- UX Consistency Patterns (button hierarchy, feedback, form, navigation)
- Responsive Design & Accessibility

In v6.0.0, personas live only in "Target Users". Step 10 loads the journeys already written in the PRD and designs flows on top of them. States have no dedicated section.

**Current EXPERIENCE.md sections:**
- Foundation
- Information Architecture
- Voice and Tone
- Component Patterns
- State Patterns
- Interaction Primitives
- Accessibility Floor
- Key Flows

Two more are added when triggered: Inspiration & Anti-patterns, and Responsive & Platform.

Where things live in the current layout:
- **Personas and journeys.** Key Flows holds named-protagonist journeys. The shipped example is "Sarah, solo founder, 8:45am Tuesday", with numbered steps, a **Climax:** line and a **Failure:** line.
- **States.** The State Patterns table has columns State, Surface, Treatment. Example rows: cold load on Today, empty project, offline, permission denied.
- **Screens.** The IA table maps surface to purpose.
- **Rubric.** Pass 1 mechanical checks: flow coverage, token completeness, component coverage, state coverage, visual reference coverage.
- **Tokens.** `DESIGN.md` follows the Google Labs spec. Its stated scope is "a visual identity". Its `lint` command emits JSON findings, including WCAG contrast. Source: https://github.com/google-labs-code/design.md (28.6k stars).

**Handoff to stories**
- **v6.0.0 `create-story`.**
  - The template has "As a {{role}}, I want...", acceptance criteria, tasks, Dev Notes and a Dev Agent Record.
  - Its workflow lists the UX file as a fallback input with the glob `*ux*.md` and `SELECTIVE_LOAD`.
  - The preferred input is "epics file ... with BDD and source hints".
  - There is no field for screen, state or persona in the template.
- **Current ticket template** (`skills/bmad-agent-po/assets/ticket-template.md`).
  - A story carries `Verify:` or numbered criteria in Given/When/Then, each naming the requirement it proves.
  - `companions:` and a `References` line of type `design` point at `DESIGN.md` in the `ux-<slug>/` run.
  - `SKILL.md` names, as the next step after finalising the spines, asking the product-owner agent (Sofia) to update the ticket's requirements from them.
- **Current build plan template** (`skills/bmad-build/plan-template.md`).
  - An I/O & Edge-Case Matrix with columns Scenario, Input / State, Expected Output / Behavior, Error Handling.
  - A `context:` list of file paths for the implementation agent to load.
  - The template says "Delete this section if route is oneshot".

## 3. Stitch, Claude Design, Figma Make

| Tool | Carries UX artefacts? | Source |
|---|---|---|
| Google Stitch | Screens, plus an interactive prototype where only links to generated screens are live. Its `DESIGN.md` is visual only. MCP server exposes projects and screens. Third-party sources only. | https://blog.openreplay.com/prompt-ui-google-stitch/ and https://github.com/google-labs-code/design.md |
| Claude Design | Anthropic's page lists "designs, prototypes, slides, one-pagers". Handoff is a "bundle" for Claude Code. The page mentions "feature flows" once as a use case. It does not mention states, personas or journeys. The bundle format is not documented there. Third-party sources add "interaction notes", unconfirmed. | https://www.anthropic.com/news/claude-design-anthropic-labs |
| Figma Make | Figma's marketing pages say a feature description becomes "user flows, states, logic, and edge cases". A CRM page mentions roles. No independent test of output quality found. | https://www.figma.com/solutions/ai-feature-spec-generator/ |
| Figma MCP | Returns design context from Design, FigJam and Make files, and can write to the canvas. | https://help.figma.com/hc/en-us/articles/32132100833559 |

## 4. Heuristic and accessibility standards

**Nielsen's 10 heuristics.** The names are visibility of system status; match between system and real world; user control and freedom; consistency and standards; error prevention; recognition rather than recall; flexibility and efficiency of use; aesthetic and minimalist design; help users recognize, diagnose and recover from errors; help and documentation. NN/g calls them "broad rules of thumb and not specific usability guidelines". Last reviewed 2024-01-30. Source: https://www.nngroup.com/articles/ten-usability-heuristics/ (fetched). They have no exit code. impeccable's `critique` scores each 0-4 and allows `n/a`.

**WCAG 2.2 AA.** Machine-checkable only in part.
- **Rule coverage.** axe-core covers WCAG 2.0, 2.1 and 2.2 at A, AA and AAA, plus best-practice rules.
- **Issue coverage.** Its README says it finds "on average 57% of WCAG issues". That measures issue volume, not success criteria. Deque is the vendor.
- **Uncertain results.** axe returns "incomplete" elements for manual review.
- **Playwright.** Its docs say automated tests catch "some common" problems and recommend adding manual and user testing.

| Tool | CLI or CI behaviour | Source |
|---|---|---|
| axe-cli | `--exit` returns code 1 when any rule fails. `--tags wcag2a` selects rules. | https://github.com/dequelabs/axe-core-npm |
| pa11y | Exit 0 clean, 1 technical fault, 2 errors found. `--threshold N` permits N issues. `--runner axe` or `htmlcs`. Standards WCAG2A, WCAG2AA, WCAG2AAA. | https://github.com/pa11y/pa11y |
| Lighthouse CI | Assertions at `error` or `warn` level. `"categories:accessibility": ["error", {"minScore": 1}]` is in the docs. `assert` exits with the appropriate status code. | https://github.com/GoogleChrome/lighthouse-ci |
| @axe-core/playwright | `AxeBuilder.analyze()`, assert violations empty. `withTags()` takes `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`. | https://playwright.dev/docs/accessibility-testing |
| DESIGN.md lint | JSON findings, including contrast ratios per component. | https://github.com/google-labs-code/design.md |

Material 3 and Apple HIG were not fetched. They are reference documents with no CLI.

## 5. Glance, hierarchy and 2-second tests

- **Five-second test.**
  - A viewer sees a screen for five seconds, then answers what they recall.
  - One case study credits Christine Perfetti with the term. It says the five-second figure rests on "anecdotal experience", not hard evidence.
  - Source: https://smashingmagazine.com/2023/12/five-second-testing-case-study
  - It needs human viewers. No agent-applicable version found.
- **F-pattern.**
  - Eyetracking of 232 users.
  - NN/g calls it "a rough, general shape".
  - NN/g's advice concerns writing, not layout. First paragraphs carry the key information and lines start with key words.
  - Source: https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content-discovered/ (fetched)
- **Scoring tools.**
  - EyeQuant has an API with a 0-100 clarity score, plus attention, perception and hotspot maps from an image, URL or video.
  - Attention Insight is described as having a public API, with a clarity score and "percentage of attention" on objects. Its 90-96% accuracy figure is vendor-reported.
  - Source: https://developers.eyequant.com/introduction
  - Nothing found on UEyes or Neurons.
- **Squint test.** No published procedure or tool found.
- **Astraler glance rule.** The R2 "2-second glance" rule is reviewed by a model at 100% screenshot crops. No script scores it.

## 6. impeccable and Astraler skills (local files)

**impeccable `shape.md`** (`/Users/tranthien/.claude/plugins/marketplaces/impeccable/.claude/skills/impeccable/reference/shape.md`)

- **Actor.** Round 1 asks "Who specifically reaches it, in what situation and state of mind?". Brief part 1 is "Job and audience: who arrives, their context, need, and visitor mode".
- **State.** Round 2 lists "first-run, empty, loading, error, success, permissions, overflow, or expert use". Brief part 5 is "States and ranges: realistic content/data ranges and material states".
- **Brief parts.**
  1. Job and audience
  2. Outcome and proof
  3. Selected direction
  4. Scope and boundaries
  5. States and ranges
  6. Interaction and layout
  7. Constraints and open decisions
- **Form.** The brief is prose or bullets. "Shape never writes code." It stops at confirmation. Nothing in it names a screen.

**impeccable `critique.md`**

- **Personas.** Five fixed archetypes:
  - Alex, impatient power user.
  - Jordan, confused first-timer.
  - Sam, accessibility-dependent user.
  - Riley, deliberate stress tester.
  - Casey, distracted mobile user.
- **Persona shape.** Each has Profile, Behaviors, Test Questions and Red Flags.
- **Selection.** A table maps interface type to two or three personas. A dashboard or admin interface gets Alex and Sam.
- **Project personas.** One or two more are generated, but only if `CLAUDE.md` has a `## Design Context` section. "Don't invent audience details."
- **State handling.** "States" appear in the holistic review list. No per-screen state matrix exists.
- **Scoring.** Output includes the Nielsen scores, cognitive load, emotional journey and P0-P3 severity.

**astraler-ui-anti-slop** (`/Users/tranthien/.claude/skills/astraler-ui-anti-slop/SKILL.md` and `references/`)

- **Role (Step 0).** One row per screen: Screen, Who opens it (real role), When, The one thing they must see in 2 s, What recedes. Roles must be job titles, "not 'the user'". Done when each screen has exactly one must-see.
- **Glance (R2).** Detail pages follow state and problem, then actions, then evidence, then metadata. Alerts gather in one strip that does not render when empty.
- **State (R8).**
  - Skeleton shaped like the final content.
  - Refetch keeps old data.
  - Stale caption after 5 minutes.
  - Per-card error with Retry.
  - Empty state is one sentence and one action.
  - Filtered-to-nothing offers Clear filters.
  - "Sample data" label on mocks.
- **R1b.** Empty values use one marker per product.
- **Other rules.** R1 to R10 also cover label versus value, colour by threshold, clickable text, image size, status visibility, money actions, button weight, consumer-app rules, section patterns and copy.
- **Questions.** `questions.md` is grouped by moment: before drawing, while building, reviewing from the seat of each role. Each is answered "by pointing at the pixel, data row or config value".
- **Spine.** `spine-templates.md` defines `EXPERIENCE.md` with Foundation (roles), IA with a Glance map, State Patterns, Interaction Primitives, Key Flows with "a named role, numbered steps, a climax step".
- **Overlap with BMAD.** That section list matches BMAD's current EXPERIENCE.md almost one to one. Both name Key Flows with a named protagonist and a climax step.
- **Checks.** The audit checklist is manual: screenshots at 1440 and 1920, 100% crops, P0/P1/P2 severity. No script.

## 7. Where the UX contract lives in tickets

| Place | What it holds | Evidence |
|---|---|---|
| Matt Pocock `to-spec` | Spec has "User Stories": "As an <actor>, I want a <feature>, so that <benefit>". | Fetched: `skills/engineering/to-spec/SKILL.md` |
| Matt Pocock `to-tickets` | Ticket has "What to build" (end-to-end behaviour "from the user's perspective"), "Blocked by", Status, checkbox criteria. No actor, screen or state field. | Fetched: `skills/engineering/to-tickets/SKILL.md` |
| Spec Kit (github/spec-kit, 143.7k stars) | Prioritised stories, Independent Test, Given/When/Then scenarios, an Edge Cases section. | Fetched: `templates/spec-template.md` |
| OpenSpec (73.3k stars) | Requirements with GIVEN/WHEN/THEN scenarios. | Fetched: `docs/concepts.md` |
| BMAD ticket and plan | Numbered Given/When/Then criteria, `companions:` and `References` pointing at design files, an I/O matrix with a state column. | Fetched, section 2 |
| GitHub issue forms | YAML with input, textarea, dropdown, checkboxes, markdown elements. `required: true` works only on public repos. Fields are whatever the repo defines. | https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms |
| Jira and Linear | No public template with Actor, Screen, State fields and adoption data found. The Atlassian user-story page returned navigation only, so its template is unverified. Linear was not searched. | Not found |

## Summary table

| Artefact | Pins | Machine-checkable | Produced by | Consumed by |
|---|---|---|---|---|
| User story "As an actor..." | Actor | No | Pocock `to-spec`; BMAD `create-story` v6.0.0; Spec Kit | Ticket writer |
| Journey with named protagonist | Actor, flow, climax, failure path | By LLM rubric only (BMAD `validate.md`) | BMAD, Astraler spine | UX validator, builder |
| JTBD statement | Actor, situation | No | impeccable `shape` (as "Job and audience") | Shape reviewer |
| Story map | Flow, release slicing | No | Diagram only (diagram-design) | Humans |
| Gherkin or EARS scenario | State, action, observable result | Yes, with step bindings | Spec Kit, OpenSpec, BMAD, Kiro | Test runner, builder |
| UI states list (Hurff) | State per screen | No schema | BMAD State Patterns, Astraler R8, impeccable `shape` | Builder, reviewer |
| Screen inventory / IA table | Screen, entry point, purpose | Closure rule, checked by LLM | BMAD IA, Astraler Glance map | Builder |
| Glance map row | Actor, screen, must-see, what recedes | No, manual review at 100% crops | Astraler Step 0 | Builder, auditor |
| I/O and edge-case matrix | Screen state, input, expected output, error | Convertible to tests | BMAD build plan | Builder |
| Fixed critique personas | Actor archetypes | No, LLM-judged | impeccable `critique` | Critic |
| DESIGN.md tokens | Visual identity only | Yes (`design.md lint`, contrast, token references) | Stitch, BMAD, Astraler | Builder |
| Nielsen scores | Heuristic compliance | No exit code | impeccable `critique` | Reviewer |
| axe, pa11y, Lighthouse, Playwright | Part of WCAG 2.x A/AA | Yes (axe `--exit`, pa11y 2, `lhci` assert) | Any CI | CI, builder |
| Attention-map clarity score | Hierarchy | Yes, via paid API (EyeQuant) | None of the agent toolkits | Humans |
| Claude Design bundle, Stitch export, Figma Make output | Screens and tokens, with flows claimed in marketing | Not documented | Anthropic, Google, Figma | Claude Code or other builders |
