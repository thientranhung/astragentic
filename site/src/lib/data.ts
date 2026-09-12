/** Data comes from site/src/data/*.json, generated from the repo by the data script.
 *  Each loader falls back to the committed *.example.json so the site builds while
 *  the generator is still running. */
const files = import.meta.glob('/src/data/*.json', { eager: true, import: 'default' }) as Record<
  string,
  unknown
>;

function load<T>(name: string, fallback: T): T {
  const real = files[`/src/data/${name}.json`];
  if (real !== undefined) return real as T;
  const example = files[`/src/data/${name}.example.json`];
  if (example !== undefined) return example as T;
  return fallback;
}

export interface Ref {
  name: string;
  kind: 'skill' | 'file';
  href: string | null;
}
export interface LedgerRow {
  id: string;
  lesson: string;
  status: string;
  words: number;
  citedBy: string[];
  indexLine: number;
  entryLine: number;
  promotedOn: string | null;
  entry: string;
  refs: Ref[];
  commits?: { sha: string; date: string; subject: string }[];
}
export interface Failure {
  id: string;
  stage: string;
  costLine: string;
}
export interface Adopt {
  prerequisites: { name: string; version: string | null; href: string | null }[];
  commands: string[];
}
export interface Commit {
  sha: string;
  date: string;
  subject: string;
  ledger: string;
}
export interface Meta {
  total: number;
  cited: number;
  orphan: number;
  generatedAt: string;
  version: string;
}

export const ledger = load<LedgerRow[]>('ledger', []);
export const failures = load<Failure[]>('failures', []);
/** True when the ledger row has a lesson on the failures page, so an AST code can link there. */
export const hasLesson = (id: string): boolean => failures.some((f) => f.id.toLowerCase() === id.toLowerCase());
export const adopt = load<Adopt>('adopt', { prerequisites: [], commands: [] });
export const commits = load<Commit[]>('commits', []);
export const meta = load<Meta>('meta', {
  total: ledger.length,
  cited: ledger.filter((r) => r.citedBy?.length).length,
  orphan: ledger.filter((r) => !r.citedBy?.length).length,
  generatedAt: '',
  version: '',
});

export const byId = new Map(ledger.map((row) => [row.id, row]));

/** The lesson as the reader should see it.
 *
 *  The ledger's INDEX.md keeps its summary column to a fixed width and cuts anything
 *  longer mid-word — `…worktree born in the wrong place, hour-long mi…`. That is right
 *  for a table the harness reads and wrong for a card on a page, where it reads as a
 *  rendering fault. The entry's own `### AST-028 — <lesson> · promoted <date>` heading
 *  carries the sentence whole, so a cut row is repaired from it. Nothing is rewritten:
 *  when the heading is missing or says the same thing, the index line stands. */
export function lessonOf(row: LedgerRow | undefined): string {
  if (!row) return '';
  if (!row.lesson.endsWith('…')) return row.lesson;
  const heading = /^###\s+\S+\s+—\s+([\s\S]*?)(?:\s+·\s+[^\n·]*)?\s*$/m.exec(
    row.entry?.split('\n')[0] ?? '',
  );
  const full = heading?.[1]?.trim();
  return full && full.length > row.lesson.length - 1 ? full : row.lesson;
}

/** The generator keeps the `### AST-016 — … · promoted …` heading at the top of `entry`.
 *  The card and the drawer print that title themselves, so drop the heading line. */
export function entryBody(row: LedgerRow | undefined): string {
  if (!row?.entry) return '';
  return row.entry.replace(/^###\s.*(\r?\n)+/, '').trim();
}

/** First N sentences-worth of the entry, for the small card on the home page. */
export function entryExcerpt(row: LedgerRow | undefined, maxChars = 260): string {
  const body = entryBody(row);
  if (body.length <= maxChars) return body;
  const cut = body.slice(0, maxChars);
  const stop = Math.max(cut.lastIndexOf('. '), cut.lastIndexOf('; '));
  if (stop > 80) return `${cut.slice(0, stop + 1)} …`;
  /* No sentence ended in range, so the cut falls wherever the character count landed —
     which was mid-word ("…hour-long mi …"). Step back to the last space, then past any
     word too small to carry the end of a sentence, so the excerpt breaks on a word the
     reader can finish in their head. */
  let end = cut.lastIndexOf(' ');
  if (end < 0) return `${cut.trimEnd()} …`;
  const trailing = /(\s|[-–—,;:([{"'`])+$/;
  let text = cut.slice(0, end).replace(trailing, '');
  const last = text.slice(text.lastIndexOf(' ') + 1);
  if (last.length <= 3 && text.length > 80) text = text.slice(0, text.lastIndexOf(' ')).replace(trailing, '');
  return `${text} …`;
}

/** Ledger entries are markdown prose. Render only the inline bits we meet there:
 *  `code`, **bold**, and paragraph breaks. Everything else is escaped verbatim. */
export function entryHtml(text: string): string {
  const esc = (t: string) =>
    t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return esc(text)
    .replace(/`([^`\n]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*\n]+)\*\*/g, '<strong>$1</strong>')
    .split(/\n\s*\n/)
    .map((para) => para.replace(/\s*\n\s*/g, ' ').trim())
    .filter(Boolean)
    .join('<br><br>');
}

export function ledgerHref(row: { entryLine: number }): string {
  return `https://github.com/thientranhung/astragentic/blob/main/harness/.agents/memory/recurring-failure-modes.md#L${row.entryLine}`;
}

/** Commit bodies carry the trailer verbatim (`Ledger: AST-097.`). Strip the key. */
export function ledgerTrailer(value: string): string {
  return (value || '').replace(/^Ledger:\s*/i, '').trim();
}
