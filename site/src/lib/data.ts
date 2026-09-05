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
  return (stop > 80 ? cut.slice(0, stop + 1) : cut.trimEnd()) + ' …';
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
