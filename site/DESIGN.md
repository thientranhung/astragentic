---
name: Astragentic
description: A coordination layer for several agents on one real repository, drawn as a working document rather than a product page.
colors:
  brand-primary: "#E53625"
  brand-primary-hover: "#C92D1F"
  brand-primary-press: "#A82014"
  brand-primary-soft: "#FBE9E6"
  brand-on-primary: "#FFFFFF"
  canvas: "#F2F3F6"
  canvas-grid-a: "#F0574A"
  canvas-grid-b: "#E53625"
  canvas-grid-c: "#B8271B"
  surface: "#FFFFFF"
  surface-raised: "#F7F8FA"
  ink: "#14161A"
  ink-88: "rgba(20, 22, 26, 0.88)"
  ink-70: "rgba(20, 22, 26, 0.7)"
  ink-62: "rgba(20, 22, 26, 0.62)"
  ink-35: "rgba(20, 22, 26, 0.35)"
  ink-22: "rgba(20, 22, 26, 0.22)"
  ink-10: "rgba(20, 22, 26, 0.1)"
  ink-05: "rgba(20, 22, 26, 0.05)"
  defect: "#8C2F1F"
  role-thomas: "#2F5DA8"
  role-shaper: "#7A4FBF"
  role-builder: "#0B6E4F"
  role-rin: "#0E7C86"
  role-qa: "#B7791F"
  group-upkeep: "#4A4F57"
  group-adapter: "#2B6777"
typography:
  stat:
    fontFamily: "JetBrains Mono Variable, ui-monospace, SFMono-Regular, monospace"
    fontSize: "clamp(36px, 3.4vw, 48px)"
    fontWeight: 500
    lineHeight: 1
  hero:
    fontFamily: "Source Serif 4 Variable, ui-serif, Georgia, serif"
    fontSize: "36px"
    fontWeight: 600
    lineHeight: 1.14
    letterSpacing: "-0.02em"
  display:
    fontFamily: "Source Serif 4 Variable, ui-serif, Georgia, serif"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: 1.14
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Inter Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.22
    letterSpacing: "-0.018em"
  title:
    fontFamily: "Inter Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "19px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.018em"
  body:
    fontFamily: "Inter Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.55
  body-sm:
    fontFamily: "Inter Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.45
  ui:
    fontFamily: "Inter Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.35
  mono:
    fontFamily: "JetBrains Mono Variable, ui-monospace, SFMono-Regular, monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "JetBrains Mono Variable, ui-monospace, SFMono-Regular, monospace"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0.1em"
  label-sm:
    fontFamily: "JetBrains Mono Variable, ui-monospace, SFMono-Regular, monospace"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.09em"
  micro:
    fontFamily: "JetBrains Mono Variable, ui-monospace, SFMono-Regular, monospace"
    fontSize: "10px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0.12em"
rounded:
  badge: "2px"
  control: "6px"
  card: "8px"
  island: "14px"
spacing:
  "1": "4px"
  "2": "8px"
  "3": "12px"
  "4": "16px"
  "5": "24px"
  "6": "32px"
  "7": "48px"
  "8": "64px"
components:
  button-primary:
    backgroundColor: "{colors.brand-primary-hover}"
    textColor: "{colors.brand-on-primary}"
    rounded: "{rounded.control}"
    padding: "0 18px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.brand-primary-press}"
    textColor: "{colors.brand-on-primary}"
  button-ghost:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0 18px"
    height: "40px"
  badge:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-70}"
    rounded: "{rounded.badge}"
    padding: "4px 7px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-88}"
    rounded: "{rounded.card}"
    padding: "32px 32px 40px"
  card-defect:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-88}"
    rounded: "{rounded.control}"
    padding: "28px 30px 24px"
  nav-item:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-70}"
    padding: "9px 2px"
    height: "44px"
  nav-item-active:
    textColor: "{colors.ink}"
  sidebar-item:
    textColor: "{colors.ink-70}"
    rounded: "{rounded.badge}"
    padding: "5px 9px"
  sidebar-item-active:
    backgroundColor: "{colors.brand-primary-soft}"
    textColor: "{colors.brand-primary-hover}"
---

# Design System: Astragentic

## Overview

**Creative North Star: "The Working Document"**

Astragentic is a coordination layer for several coding agents on one real repository, and the site is written the way the product's own ledger is written: numbers that were measured, entries that were kept, and nothing claimed that nobody checked. The visual system follows from that. The page is a sheet of paper on a drafting table. The table is warm graph paper in the brand red, the sheet is a raised island of white and near-white, and everything the reader actually uses stands on the sheet. Depth comes from white on cool grey, never from a border doing the work of a shadow. That white-on-cool-grey reading and the rhythm of the reading column were measured off aihero.dev.

Colour is rationed to the point of severity. There is exactly one hue with a job — Astraler's logo red, sampled from astraler.com as `rgb(229, 54, 37)` — and it appears only where the site is answering "what should you press" or "where are you". Astraler is the company; Astragentic is its product, so the product site borrows the parent's one colour rather than inventing a second identity. Everything else is one ink at seven opacities. Five more hues exist for the five roles, but they are spent at dot and stroke size only: the version of this page that filled five nodes with five pastels is the version that read as mud, and it is not coming back.

The type does the rest. A serif carries the page title and the hero headline, because that is where the site has to sound like a person wrote it; a sans carries every other heading and all the body; a mono carries every label, every skill name and every ledger id, because those are strings the reader will type. Nothing is decorative. If an element cannot say what it is for, it is not on the page.

**Key Characteristics:**

- One accent colour, rationed to state and action.
- One ink at seven alphas; hierarchy is opacity, never a second hue.
- White surfaces on a warm graph-paper ground; one large shadow on the whole page island and nothing else.
- Mono for anything the reader will type; serif for exactly two places per page.
- Role colour is a 6-8px dot or a 1.5px stroke. Never a fill.

## Colors

A near-monochrome system with a single red, a single failure brown-red, and five role hues held at the smallest size that still reads.

### Primary

- **Astraler Red** (`#E53625`): the logo red, measured off astraler.com. It draws marks — the 2px rule under the active nav item, the 2px bar down the current sidebar row, the 2px stroke on a diagram node you picked, the focus ring, the underline on a mono "keep going" link. White on it measures 4.30:1, which clears the 3:1 floor for a mark and misses the 4.5:1 floor for words, so this exact hex never carries text or sits under a label.
- **Astraler Red, Spoken** (`#C92D1F`): the step that is allowed to carry words. It is the primary button's ground, the colour of a brand-coloured link or the current sidebar label, and it measures 5.41:1 both ways against white. Every legacy accent name in the CSS resolves here.
- **Astraler Red, Pressed** (`#A82014`): a filled brand button under the cursor. 7.29:1 with white on it.
- **Blush** (`#FBE9E6`): the ground behind the sidebar row you are on, and the text selection highlight. Never a section background.

### Secondary

- **Ledger Rust** (`#8C2F1F`): darker and browner than the brand, deliberately. It underlines an AST ledger id, outlines a defect card, and draws the block path in a hook diagram. It is a measured failure, never an invitation, and it is never a button.

### Tertiary

Five role hues, each attached to one person in the workflow and to nothing else on the site.

- **Router Blue** (`#2F5DA8`): Thomas.
- **Shaper Violet** (`#7A4FBF`): the Shaper.
- **Builder Green** (`#0B6E4F`): the Builder. This is the only green on the site.
- **Review Teal** (`#0E7C86`): Rin. Rin used to be a red one hue off the brand and read as an error; teal fixed that.
- **Walk Amber** (`#B7791F`): QA.
- Two neutrals extend the set for skill groups that have no person: **Upkeep Slate** (`#4A4F57`) and **Adapter Petrol** (`#2B6777`).

### Neutral

- **Ink** (`#14161A`): every heading, and any text that must be read first. Opacity does the rest: `.88` for body and code, `.70` for a caption or a muted label, `.62` for a link inside a paragraph and for the mono eyebrow, `.35` for a default diagram stroke, `.22` for a hairline under a link, `.10` for every rule and border, `.05` for a wash behind a grouped band.
- **Surface** (`#FFFFFF`): the reading surface — the header bar, the docs card, a code pane, a diagram frame on grey ground.
- **Raised Surface** (`#F7F8FA`): one step in from white, for a quoted ledger entry or an open table row.
- **Canvas** (`#F2F3F6`): the page island's own ground, and the alternating band on the landing page.
- **Graph Paper** (blush → soft rose → pale coral under a white grid, 44px squares): the desk the page sits on. The three stops are a warm ramp out of the brand red, so the red reaches the room the page is in as well as the marks on it. It carries no text and never touches the island: everything a reader looks at is on the neutral sheet above it.

### Named Rules

**The Desk-Not-Paper Rule.** The warm ground stops at the island's edge. Nothing is ever set on the graph paper — no text, no control, no card — so its colour never has to clear a contrast floor, and the neutral sheet keeps every reading surface it had.

**The One Job Rule.** The brand red answers exactly two questions — "what do I press" and "where am I" — and it answers nothing else. It never appears in prose, never grounds a section, and never colours a diagram except on the node the reader picked.

**The Two-Step Red Rule.** `#E53625` draws marks; `#C92D1F` carries words. The split is a measurement, not a preference: white on the logo hex is 4.30:1 and a button label needs 4.5:1.

**The Dot-Size Rule.** A role hue may be a 6-8px dot, a 1.5px node stroke, or a sigil inside a white node. It may never be a fill, a tinted row, or a background.

## Typography

**Display Font:** Source Serif 4 Variable (with `ui-serif`, Georgia, serif)
**Body Font:** Inter Variable (with `ui-sans-serif`, `system-ui`, sans-serif)
**Label/Mono Font:** JetBrains Mono Variable (with `ui-monospace`, SFMono-Regular, monospace)

**Character:** A quiet editorial serif for the one line per page that has a voice, a neutral workhorse sans for everything that has to be read quickly, and a mono that appears wherever the page is showing the reader a literal string. The pairing reads as a well-kept engineering document rather than a marketing page.

### Hierarchy

Twelve steps and no others: 10, 11, 12, 13, 14, 15, 17, 19, 26, 30, 36, 48. Three of them — 10, 11 and 48 — are not on the nine-step scale the spec proposed, and they are here because the shipped site genuinely needs them: mono micro-labels live below 12, and a measured number in a stat block lives above 36.

- **Stat** (JetBrains Mono, 500, `clamp(36px, 3.4vw, 48px)`, 1.0): a measured number standing on its own, with a mono caption under it.
- **Hero** (Source Serif 4, 600, 36px, 1.14, `-0.02em`): the landing headline. One per site.
- **Display** (Source Serif 4, 600, 30px, 1.14, `-0.02em`): the `h1` of a content page. One per page.
- **Headline** (Inter, 700, 26px, 1.22, `-0.018em`): a section heading, the lesson line on a large defect card, and the large pull quote's upper bound.
- **Title** (Inter, 700, 19px, 1.3): an `h3`, the sub-line under a section heading, and the medium pull quote.
- **Body** (Inter, 400, 17px, 1.55): all prose. Measure is capped at 66ch inside the docs column and 62ch under a heading, so the column can be wider than the text without the text going wide.
- **Body Small** (Inter, 400, 15px, 1.45): a dense list, a card summary, a table cell of prose.
- **UI** (Inter, 600, 14px, 1.35): a button label, a sidebar leaf, a row title.
- **Mono** (JetBrains Mono, 400, 13px, 1.4): code, a command, a skill name, a "keep going" link.
- **Label** (JetBrains Mono, 400, 12px, 1.4, `+0.1em`, uppercase): the eyebrow above a heading, a nav item, a stat caption.
- **Label Small** (JetBrains Mono, 500, 11px, `+0.09em`, uppercase): a badge, a table header, a footnote.
- **Micro** (JetBrains Mono, 400, 10px, `+0.12em`, uppercase): the smallest label the site allows — a column head inside a card, a step number.

Body sets `font-variant-numeric: tabular-nums`, because a ledger of ids and counts has to line up.

### Named Rules

**The Two Serifs Rule.** The serif is allowed exactly two homes: the hero headline and the page title. A third one means someone is decorating.

**The Literal String Rule.** Mono means "this is a thing you will type or grep for" — a skill name, a file path, a ledger id, a command. Mono for emphasis is a misuse.

**The Whole-Step Rule.** There are no half steps. A pass that introduced 10.5, 11.5, 12.5 and 13.5px did not add nuance, it added four sizes nobody could tell apart from their neighbours. Both endpoints of a fluid `clamp()` are steps on the ramp too, or the ramp is not a ramp.

## Layout

One page frame, one reading column, one breakout width, and a single set of rails for read mode.

The landing frame is 1200px; the docs frame is 1440px. Inside the docs frame a three-column grid runs 232px sidebar / flexible content / 180px table of contents with a 28px column gap, which lands the content card at 924px at 1440 — measured against aihero.dev's reading column, and taken honestly by trimming the rails rather than by overlapping the sticky table of contents. The right-hand table of contents disappears below 1180px, and the whole grid collapses to one column below 900px, where the sidebar becomes a single collapsed disclosure above the first paragraph rather than a drawer.

On the landing page the reading column is 680px, a breakout block is 1040px, and a diagram band is 1120px. The outer gutter is `clamp(20px, 4vw, 48px)`. The header bar is 56px and sticky; both rails hang off its bottom edge, so that height is a measurement rather than a taste.

Spacing runs on a 4px base: 4, 8, 12, 16, 24, 32, 48, 64. Sections are 48px apart, blocks 24px, and any interactive row is at least 44px tall so a thumb can hit it. A landing screen is a full-width band with 56px of vertical padding, alternating canvas and white so the page has a floor and things standing on it.

## Elevation & Depth

Depth is tonal, not shadowed. The system layers white on near-white on cool grey and lets a 1px `ink-10` hairline mark the seam. Exactly one element on the site casts a real shadow: the page island itself, floating over the graph-paper desk. Everything else earns its depth from the ground it lands on, which is why a diagram pane is white when it sits on canvas and canvas when it sits on white.

### Shadow Vocabulary

- **Island** (`box-shadow: 0 1px 2px rgba(20,22,26,.06), 0 12px 40px rgba(60,10,6,.32)`): the whole page frame, once.
- **Raised** (`box-shadow: 0 1px 2px rgba(20,22,26,.08)`): a contact shadow on a diagram node the reader has picked, applied as a `drop-shadow` filter. Nothing else uses it.

### Named Rules

**The One Shadow Rule.** If a second large shadow appears anywhere on a page, the layering has failed and a tonal step is the fix, not another blur.

## Shapes

Corners are quiet and consistent: 2px on a badge, a sidebar row and an inline code span; 6px on a button, an input and a defect card; 8px on a card, a code pane and a diagram frame; 14px on the page island. Everything is a rectangle. Nothing is a pill, nothing is a circle except a status dot and the window-bar dots on a command pane.

Borders are always 1px of `ink-10` and always a hairline, never a colour. The exceptions are deliberate and few: a defect card is outlined in Ledger Rust, a picked diagram node is stroked 2px in the brand, and a role node is stroked 1.5px in its own hue. A grouping band in a diagram is a dashed `ink-10` outline over a 5% ink wash, not a grey fill.

## Components

### Buttons

- **Shape:** gently squared (6px), 40px tall, 18px of horizontal padding.
- **Primary:** the spoken brand red with white on it (5.41:1), 14px/600 sans. One per screen.
- **Hover / Focus:** the ground drops to the pressed red over 120ms ease-out; focus takes the shared 2px brand ring at 2px offset.
- **Ghost:** white surface, `ink-10` hairline, ink label in 12.5px mono with `+0.06em`. The hairline goes to `ink-22` on hover and nothing else moves. Two buttons side by side are never ambiguous, because only one of them has a colour.

### Chips

Badges for a role or a skill group. White ground, `ink-10` hairline, 2px corners, 11px mono in `ink-70` at `+0.09em` uppercase, and a 6px dot in the role or group hue leading the label. There is no filled or tinted variant — the dot is the entire colour budget.

### Cards / Containers

- **Corner Style:** 8px for a content card, 6px for a defect card.
- **Background:** white on the canvas ground; the docs content column is a white card with an `ink-10` hairline.
- **Shadow Strategy:** none. See Elevation & Depth.
- **Border:** 1px `ink-10`, except the defect card, which takes a 1px Ledger Rust outline as its whole signal.
- **Internal Padding:** 32px on a large card, 14px on a small one, dropping to 18px on a phone.

### Inputs / Fields

The only real control on the site is the ledger's search field and the copy button on the quickstart block. Both are a white ground with a 1px `ink-10` hairline, 2px corners, mono label, and a minimum height of 36px that rises to 44px on a coarse pointer. Focus is the shared brand ring; there is no glow and no border-colour shift.

### Navigation

The header is a 56px sticky white bar with an `ink-10` bottom hairline. Items are 12px mono, uppercase, `+0.09em`, in `ink-70`. Hover takes them to full ink. The current item takes full ink plus a 2px brand rule under the word — the colour is the mark, the ink is the reading, so the label never has to be red to be legible. Below 860px the bar becomes two rows rather than a hamburger: seven links read fine stacked, and hiding the whole site behind one tap does not.

The read-mode sidebar is a mono tree of collapsible sections. A leaf is 14px sans in `ink-70`; the row you are on takes the blush ground, the spoken red label, and a 2px brand bar down its left edge. A role leaf keeps its dot in the role hue and follows the same current-row treatment as every other leaf, because the ground already says where you are.

### Interactive Diagram

The site's signature component. An archify SVG is rendered inline, its legend cropped, and every node the page has an href for is marked `is-link` at build time so hover and focus highlighting work with JavaScript off. A node at rest is a white rectangle with an `ink-35` hairline. A node with a role is stroked 1.5px in that role's hue and carries a small sigil in the same hue. A node under the cursor, focused, or arrived-at gets a 2px brand stroke, a white fill and a contact shadow — the only place the brand red is allowed inside a drawing. Arrows are `ink-35`; an emphasised arrow is the same ink drawn at 1.5px, because inside a picture colour is reserved for the node you picked.

One semantic is split by figure. archify's `security` class means "a gate", which on this site is two different things: a hook refusing a command, which stays Ledger Rust, and a review by Rin, which is Review Teal. The split is keyed off a `data-diagram` slug on the figure, because the SVG files are generated and are not edited by hand.

## Do's and Don'ts

### Do:

- **Do** take every value from `design-tokens.json` and regenerate `src/styles/tokens.css` with `pnpm tokens`. That generated file is the only place a custom property is declared.
- **Do** use `#C92D1F` when the red carries words and `#E53625` when it draws a mark. The Two-Step Red Rule exists because of a measured 4.30:1.
- **Do** spend a role hue as a 6-8px dot or a 1.5px stroke, and let the white fill stay white.
- **Do** give any interactive row at least 44px of height, and any coarse-pointer control at least 44px.
- **Do** let a code keyword say so with weight 600 and ink `.88`. Code has no colour of its own.
- **Do** cap prose at 66ch even when the column around it is wider.
- **Do** pick a size from the twelve-step ramp, including both endpoints of any `clamp()`.

### Don't:

- **Don't** put the brand red in prose, in a section background, or on more than one button per screen.
- **Don't** add a second large shadow. If something needs to lift, change the tone of the ground under it.
- **Don't** tint a table row, a card or a diagram node with a role hue. Five pastel fills in one picture is the failure this system was rewritten to end.
- **Don't** introduce a third font, or give the serif a third home beyond the hero and the page title.
- **Don't** use Ledger Rust for anything a reader is meant to act on. It marks a measured failure and it is never a button.
- **Don't** hand-edit `src/styles/tokens.css`, and don't declare a custom property in `global.css` or a component. Two palettes that have to agree is exactly the drift this file was written to end.
