import type { Lang } from './site';

/** Everything both diagram components do to a delivered archify SVG before it reaches
 *  the page. Kept here so `Diagram` and `InteractiveDiagram` cannot drift apart, and so
 *  none of it needs a delivered file to be edited (src/assets/diagrams is read-only).
 *
 *  Three jobs:
 *
 *  1. LABEL FLOOR (PRD §5 — a label reads without zoom). archify writes each label's
 *     size as a presentation attribute in SVG user units; the figure then renders at
 *     `frame` CSS px against a viewBox `width` units wide, so one user unit lands at
 *     `frame / width` real pixels. A 7-unit sublabel in a 1080-unit viewBox is 7 real
 *     pixels. Every label is raised until it clears the floor below, capped at
 *     MAX_GROWTH so a bumped label cannot outgrow the box archify laid out around it.
 *  2. LEGEND CROP. Every archify SVG ends in a "Frontend · Backend · Database ·
 *     Security · External" key. That is archify's vocabulary, not this product's, so
 *     the legend is hidden (src/styles/diagram.css) and the viewBox is cropped to where
 *     the drawing actually ends — otherwise the figure keeps the legend's dead band.
 *  3. UNIQUE IDS. Each file declares the same `arrowhead`, `grid` and
 *     `archify-diagram-title` ids. Four diagrams on the landing page means four of each
 *     in one document; every instance gets its own suffix instead.
 */

/** Real CSS pixels a label must reach at the figure's rendered width. */
const FLOOR_PRIMARY = 13;
const FLOOR_MUTED = 10.5;
/** A label may not grow past this multiple of the size archify laid the box out for. */
const MAX_GROWTH = 1.6;

/** The diagram band, in CSS px (`--diagram` in src/styles/global.css). */
export const BAND = 1120;

export interface Prepared {
  html: string;
  /** viewBox width in user units, or null when the file carries no viewBox. */
  width: number | null;
  /** viewBox height in user units, after any crop. Null with no viewBox. */
  height: number | null;
}

let instances = 0;

/** A viewBox, in user units. */
interface Box {
  x: number;
  y: number;
  w: number;
  h: number;
}

function readViewBox(svg: string): Box | null {
  const raw = /<svg\b[^>]*\sviewBox="([^"]+)"/.exec(svg)?.[1];
  if (!raw) return null;
  const parts = raw.trim().split(/[\s,]+/).map(Number);
  if (parts.length !== 4 || parts.some((n) => !Number.isFinite(n))) return null;
  const [x, y, w, h] = parts;
  if (w <= 0 || h <= 0) return null;
  return { x, y, w, h };
}

/** Cut the viewBox back to just above the legend block, which archify always draws
 *  last. A file without a legend is returned untouched. */
function cropLegend(svg: string, box: Box): string {
  const start = svg.indexOf('<g data-legend');
  if (start < 0) return svg;
  const tail = svg.slice(start);
  const tops = [...tail.matchAll(/\sy[12]?="(-?[\d.]+)"/g)].map((m) => Number(m[1]));
  if (tops.length === 0) return svg;
  // The smallest y in the legend is its "Legend" caption baseline; back off one line
  // of leading so the cap heights are not clipped.
  let cut = Math.round(Math.min(...tops) - 14);
  if (!Number.isFinite(cut) || cut <= 0 || cut >= box.h) return svg;
  // An edge routed under the drawing (a feedback loop) can run below the legend's top
  // line; the legend is hidden anyway, so keep the cut under the lowest edge point.
  const headForY = svg.slice(0, start);
  const pointYs = [...headForY.matchAll(/data-composition-points="([^"]+)"/g)].flatMap((m) =>
    m[1].split(';').map((p) => Number(p.split(',')[1])),
  ).filter(Number.isFinite);
  if (pointYs.length) cut = Math.min(box.h, Math.max(cut, Math.ceil(Math.max(...pointYs) + 18)));
  // The legend row can be wider than the drawing above it, and archify sizes the
  // viewBox to the wider of the two. With the legend gone that slack sits to the right
  // and the picture reads as left-aligned, so trim the width to the drawing's own
  // right edge. Rects are enough: every node, lane and label mask is one.
  const head = svg.slice(0, start);
  const rights = [...head.matchAll(/<rect\b[^>]*\sx="(-?[\d.]+)"[^>]*\swidth="([\d.]+)"/g)].map(
    (m) => Number(m[1]) + Number(m[2]),
  );
  const right = rights.length ? Math.ceil(Math.max(...rights) + 24) : box.w;
  const w = right < box.w - 40 ? right : box.w;
  return svg.replace(
    /(<svg\b[^>]*\sviewBox=")[^"]+(")/,
    `$1${box.x} ${box.y} ${w} ${cut}$2`,
  );
}

/** The box archify drew for one node, in user units. The node group opens with its own
 *  `<rect>`, so the first rect after the group tag is the box itself. */
function nodeRect(svg: string, id: string): Box | null {
  const open = new RegExp(`<g id="node-${id}"[^>]*>`).exec(svg);
  if (!open) return null;
  const tail = svg.slice(open.index + open[0].length, open.index + open[0].length + 1200);
  const rect = /<rect\b[^>]*\sx="(-?[\d.]+)"[^>]*\sy="(-?[\d.]+)"[^>]*\swidth="([\d.]+)"[^>]*\sheight="([\d.]+)"/.exec(
    tail,
  );
  if (!rect) return null;
  const [x, y, w, h] = rect.slice(1, 5).map(Number);
  return Number.isFinite(x + y + w + h) ? { x, y, w, h } : null;
}

/** Room left around a cropped detail so a node's own hairline and its sublabel are not
 *  sitting on the edge of the frame. */
const CROP_PAD = 20;

/** Remove every label the crop would only show part of. A viewBox is a window, not a
 *  filter: an edge label whose baseline sits just below the cut still draws its
 *  ascenders inside the frame, and half a word reads as a rendering bug. Dropping the
 *  whole label loses a caption a thumbnail was never going to carry anyway.
 *
 *  Vertically the test is the baseline, since a line inks upward from it. Horizontally
 *  the label is centred on its `x`, so half its computed advance has to clear both
 *  sides. */
function dropClippedText(svg: string, box: Box): string {
  return svg.replace(/<text\b([^>]*)>([\s\S]*?)<\/text>/g, (whole, tag: string, body: string) => {
    const x = Number(/\sx="(-?[\d.]+)"/.exec(tag)?.[1]);
    const y = Number(/\sy="(-?[\d.]+)"/.exec(tag)?.[1]);
    if (!Number.isFinite(x) || !Number.isFinite(y)) return whole;
    const size = Number(/\sfont-size="([\d.]+)"/.exec(tag)?.[1]) || 10;
    const chars = body.replace(/<[^>]*>/g, '').replace(/&\S{1,6};/g, 'x').trim().length;
    const half = (MONO_ADVANCE * chars * size) / 2;
    const inside =
      y - size >= box.y &&
      y + 0.3 * size <= box.y + box.h &&
      x - half >= box.x &&
      x + half <= box.x + box.w;
    return inside ? whole : '';
  });
}

/** Crop the viewBox to the union of the named nodes' boxes. A card-sized figure that
 *  keeps the whole drawing renders its labels at four or five pixels; a detail of two
 *  or three boxes renders them at the size the label floor asks for. The box is taken
 *  from the rects archify laid out, never from the text, so a label can be too small
 *  here but it can never be cut in half. Unknown ids are ignored; if none of them
 *  resolve, the figure is returned whole rather than blank. */
function cropNodes(svg: string, box: Box, ids: string[]): { svg: string; box: Box } {
  const found = ids.map((id) => nodeRect(svg, id)).filter((b): b is Box => b !== null);
  if (found.length === 0) return { svg, box };
  const left = Math.min(...found.map((b) => b.x));
  const top = Math.min(...found.map((b) => b.y));
  const right = Math.max(...found.map((b) => b.x + b.w));
  const bottom = Math.max(...found.map((b) => b.y + b.h));
  const next: Box = {
    x: Math.round(left - CROP_PAD),
    y: Math.round(top - CROP_PAD),
    w: Math.round(right - left + 2 * CROP_PAD),
    h: Math.round(bottom - top + 2 * CROP_PAD),
  };
  return {
    svg: svg.replace(
      /(<svg\b[^>]*\sviewBox=")[^"]+(")/,
      `$1${next.x} ${next.y} ${next.w} ${next.h}$2`,
    ),
    box: next,
  };
}

/** Advance width of one JetBrains Mono character, in em. Every label in an archify SVG
 *  is set in the mono face (src/styles/diagram.css), and mono is the one case where a
 *  string's width can be computed instead of measured. */
const MONO_ADVANCE = 0.6;
/** Breathing room between a label and the two sides of the box holding it, in units. */
const BOX_PADDING = 14;

/** Room a node's kind sigil takes at the top-left corner of its box. The title is
 *  centred, so the sigil costs the same room on both sides of it. */
const SIGIL_RESERVE = 17;
/** How far a line of Vietnamese mono actually inks, in em above and below its baseline.
 *  Above the cap height sit the stacked tone marks — `Ổ` and `ề` reach higher than the
 *  0.73em an English cap does, and that is what a raised label runs into. */
const INK_UP = 0.95;
const INK_DOWN = 0.25;

/** Every `<g>` holding a `<rect>` of its own, innermost first. A node box, an edge
 *  label's mask pill and a lane band all arrive in this shape, so one scan gives every
 *  label the width of whatever is actually drawn behind it. */
function boxesIn(svg: string): { start: number; end: number; width: number; sigil: boolean }[] {
  const found: { start: number; end: number; width: number; sigil: boolean }[] = [];
  const open: { start: number; width: number }[] = [];
  const token = /<g\b[^>]*>|<\/g>|<rect\b[^>]*>/g;
  let hit: RegExpExecArray | null;
  while ((hit = token.exec(svg))) {
    const text = hit[0];
    if (text.startsWith('</g')) {
      const frame = open.pop();
      if (frame && frame.width > 0) {
        found.push({
          start: frame.start,
          end: hit.index,
          width: frame.width,
          sigil: svg.slice(frame.start, hit.index).includes('semantic-sigil'),
        });
      }
    } else if (text.startsWith('<g')) {
      open.push({ start: hit.index, width: 0 });
    } else if (open.length) {
      const w = Number(/\swidth="([\d.]+)"/.exec(text)?.[1]);
      const top = open[open.length - 1];
      if (Number.isFinite(w)) top.width = Math.max(top.width, w);
    }
  }
  return found.sort((a, b) => a.end - a.start - (b.end - b.start));
}

interface Label {
  at: number;
  x: number;
  y: number;
  declared: number;
  title: boolean;
  chars: number;
  /** How much bigger this one label could get on its own. */
  k: number;
}

/** Read every label, with the largest growth its own box and the size floor allow. */
function readLabels(svg: string, floorPrimary: number, floorMuted: number): Label[] {
  const boxes = boxesIn(svg);
  const out: Label[] = [];
  for (const m of svg.matchAll(/(<text\b[^>]*>)([\s\S]*?)<\/text>/g)) {
    const [, tag, body] = m;
    const cls = /\sclass="([^"]*)"/.exec(tag)?.[1] ?? '';
    const declared = Number(/\sfont-size="([\d.]+)"/.exec(tag)?.[1]);
    if (!/\bt-/.test(cls) || !Number.isFinite(declared) || declared <= 0) continue;

    const at = m.index!;
    const title = /\bt-primary\b/.test(cls);
    const chars = body.replace(/<[^>]*>/g, '').replace(/&\S{1,6};/g, 'x').trim().length;
    const box = boxes.find((b) => at > b.start && at < b.end);
    // A node title shares the top of its box with the kind sigil, and it is centred, so
    // the sigil costs it room on both sides.
    const room = box
      ? box.width - BOX_PADDING - (box.sigil && title ? 2 * SIGIL_RESERVE : 0)
      : Infinity;
    const fits = chars > 0 && room > 0 ? room / (MONO_ADVANCE * chars) : Infinity;
    const want = Math.min(
      Math.max(declared, title ? floorPrimary : floorMuted),
      declared * MAX_GROWTH,
      Math.max(fits, declared), // a label already wider than its box is left alone
    );
    out.push({
      at,
      x: Number(/\sx="(-?[\d.]+)"/.exec(tag)?.[1]) || 0,
      y: Number(/\sy="(-?[\d.]+)"/.exec(tag)?.[1]) || 0,
      declared,
      title,
      chars,
      k: Math.max(want / declared, 1),
    });
  }
  return out;
}

/** archify stacks the lines of one label on a single x, at baselines it will not move.
 *  Two neighbours clear each other while
 *  `INK_UP · lower + INK_DOWN · upper ≤ gap`, so the pair can be scaled by at most
 *  `gap / that sum`. Bounding both members of a pair by that factor keeps the whole
 *  stack clear whatever each one settles on. */
function stackLimit(labels: Label[]): Map<number, number> {
  const limit = new Map(labels.map((l) => [l.at, l.k]));
  const column = new Map<string, Label[]>();
  for (const label of labels) {
    const key = label.x.toFixed(1);
    (column.get(key) ?? column.set(key, []).get(key)!).push(label);
  }
  for (const lines of column.values()) {
    lines.sort((a, b) => a.y - b.y);
    for (let i = 1; i < lines.length; i += 1) {
      const upper = lines[i - 1];
      const lower = lines[i];
      const gap = lower.y - upper.y;
      if (gap <= 0 || gap > 60) continue;
      const ink = INK_UP * lower.declared + INK_DOWN * upper.declared;
      const room = ink > 0 ? gap / ink : Infinity;
      limit.set(upper.at, Math.min(limit.get(upper.at)!, room));
      limit.set(lower.at, Math.min(limit.get(lower.at)!, room));
    }
  }
  return limit;
}

/** Raise every label that renders below the floor, but never past what the box behind
 *  it can hold, the room its kind sigil leaves, or the line under it. `frame` is the
 *  width the figure occupies on a desktop screen. */
function raiseLabels(svg: string, width: number, frame: number): string {
  const pxPerUnit = frame / width;
  const labels = readLabels(svg, FLOOR_PRIMARY / pxPerUnit, FLOOR_MUTED / pxPerUnit);
  const limit = stackLimit(labels);

  const size = new Map<number, number>();
  for (const label of labels) {
    const k = Math.max(Math.min(label.k, limit.get(label.at) ?? label.k), 1);
    if (k > 1.005) size.set(label.at, Number((label.declared * k).toFixed(2)));
  }
  if (size.size === 0) return svg;

  return svg.replace(/<text\b[^>]*>/g, (tag, at: number) => {
    const next = size.get(at);
    return next === undefined ? tag : tag.replace(/\sfont-size="[\d.]+"/, ` font-size="${next}"`);
  });
}

/** Suffix every id this file declares, and every reference to one. */
function uniqueIds(svg: string, suffix: string): string {
  return svg
    .replace(/\sid="([^"]+)"/g, (_m, id: string) => ` id="${id}-${suffix}"`)
    .replace(/url\(#([^)]+)\)/g, (_m, id: string) => `url(#${id}-${suffix})`)
    .replace(
      /\saria-labelledby="([^"]+)"/g,
      (_m, ids: string) =>
        ` aria-labelledby="${ids
          .trim()
          .split(/\s+/)
          .map((id) => `${id}-${suffix}`)
          .join(' ')}"`,
    );
}

/** archify stamps `lang="en"` on the root of every file, including the translated
 *  ones. A Vietnamese page must not hand a screen reader an English voice (PRD §4). */
function setLang(svg: string, lang: Lang): string {
  return svg.replace(/(<svg\b[^>]*?)\slang="[^"]*"/, `$1 lang="${lang}"`);
}

/** archify ships every node as `tabindex="0" role="button"`, which is true inside its
 *  own explore page. On a figure where nothing is clickable those are tab stops that
 *  lead nowhere; the `<title>` on each node still names it for a screen reader. */
export function stripFocus(svg: string): string {
  return svg
    .replace(/\stabindex="0"/g, '')
    .replace(/\srole="button"/g, '')
    .replace(/\saria-pressed="[^"]*"/g, '');
}

export interface PrepareOptions {
  lang: Lang;
  /** Rendered width of the figure on a desktop screen, in CSS px. */
  frame: number;
  /** Node ids to crop the viewBox down to, for a card-sized detail of a big drawing. */
  crop?: string[];
  /** Run before the ids are made unique — this is where node groups get their classes
   *  and their link semantics. */
  transform?: (svg: string) => string;
}

export function prepare(raw: string, { lang, frame, crop, transform }: PrepareOptions): Prepared {
  const suffix = `d${++instances}`;
  let box = readViewBox(raw);
  let svg = raw;
  if (box) {
    // A node crop already excludes the legend, and both rewrite the same attribute, so
    // only one of the two ever runs.
    if (crop?.length) {
      const cropped = cropNodes(svg, box, crop);
      svg = cropped.svg;
      box = cropped.box;
    } else {
      svg = cropLegend(svg, box);
      box = readViewBox(svg) ?? box;
    }
    // The label floor is measured against what is actually on screen, so a cropped
    // figure sizes its labels against the crop rather than the whole drawing.
    svg = raiseLabels(svg, box.w, frame);
    // After the floor has settled, not before: a label that was raised is wider than
    // the one that was read, and it is the raised one the frame has to hold.
    if (crop?.length) svg = dropClippedText(svg, box);
  }
  svg = setLang(svg, lang);
  if (transform) svg = transform(svg);
  return { html: uniqueIds(svg, suffix), width: box?.w ?? null, height: box?.h ?? null };
}
