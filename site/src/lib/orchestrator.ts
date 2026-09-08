// The harness file itself, inlined at build time. A `?raw` import is what makes this
// live: Vite reads the file during the build and watches it in dev, so editing
// orchestrator.md changes the page without a second command to run. Resolving a path at
// runtime does not work here — the module is bundled into dist/.prerender/chunks, and
// `import.meta.url` then points at the chunk rather than at src/lib.
import RAW from '../../../harness/.agents/orchestrator.md?raw';

/** `harness/.agents/orchestrator.md` is the file the owner edits to say which role runs
 *  on which runtime, at which model and which effort. The landing reads it rather than
 *  carrying a copy, so the file and the page cannot disagree. */

/** The path as the reader would type it, for a caption or a link. */
export const ORCHESTRATOR_FILE = 'harness/.agents/orchestrator.md';

export interface Assignment {
  role: string;
  runtime: string;
  /** The declared model, or an em dash where the file still carries a placeholder. */
  model: string;
  effort: string;
  /** True when the file left this row for the reader to fill in (`<set-me>`). */
  unset: boolean;
}

/** A cell the owner has not filled in yet. The file writes `<set-me>`; the page writes
 *  an em dash and says once, under the table, whose job it is. */
const PLACEHOLDER = /^<[^>]*>$/;
const DASH = '—';

/** Read the markdown table that follows a `## <heading>` line. Rows stop at the first
 *  line that is not a table row, so a table followed by prose is read correctly. */
function tableUnder(markdown: string, heading: string): string[][] {
  const lines = markdown.split('\n');
  const start = lines.findIndex((line) => line.trim() === `## ${heading}`);
  if (start < 0) return [];
  const rows: string[][] = [];
  let seenHeader = false;
  for (const line of lines.slice(start + 1)) {
    const text = line.trim();
    if (!text.startsWith('|')) {
      // A blank line inside the block is fine; anything else ends the table.
      if (rows.length > 0 || seenHeader) break;
      continue;
    }
    const cells = text.replace(/^\||\|$/g, '').split('|').map((cell) => cell.trim());
    // The header and its `|---|` rule are structure, not data.
    if (cells.every((cell) => /^:?-{2,}:?$/.test(cell))) continue;
    if (!seenHeader) {
      seenHeader = true;
      continue;
    }
    rows.push(cells);
  }
  return rows;
}

function assignments(markdown: string, heading: string): Assignment[] {
  return tableUnder(markdown, heading)
    .filter((cells) => cells.length >= 4 && cells[0])
    .map(([role, runtime, model, effort]) => {
      const unset = PLACEHOLDER.test(model);
      return {
        // Backticks are markdown's, not the reader's.
        role: role.replace(/`/g, ''),
        runtime: runtime.replace(/`/g, ''),
        model: unset ? DASH : model.replace(/`/g, ''),
        effort: PLACEHOLDER.test(effort) ? DASH : effort.replace(/`/g, ''),
        unset,
      };
    });
}

/** What every role runs on today. The file's other table, "Fallback providers", is read
 *  by the same call with its heading — nothing on the landing shows it yet, so it is
 *  not exported rather than shipped unused. */
export const ACTIVE: Assignment[] = assignments(RAW, 'Active assignments');

// A renamed heading must not fail the build silently: the card renders empty and the
// gap is visible on screen, which is the contract the landing YAML already has.
if (ACTIVE.length === 0) {
  console.warn(
    `[orchestrator] no "Active assignments" table in ${ORCHESTRATOR_FILE} — the model card will be empty.`,
  );
}

/** One row to quote as a sample of the declaration. The Builder is the row a reader
 *  recognises first; any row will do if the file is written differently. */
export const SAMPLE: Assignment | null =
  ACTIVE.find((row) => row.role === 'builder') ?? ACTIVE[0] ?? null;

/** True when any row on the active table is still waiting on the reader. */
export const HAS_UNSET = ACTIVE.some((row) => row.unset);

/** The "Active assignments" block verbatim, heading to the blank line after the table,
 *  for showing the reader the exact text they would edit. */
export const ACTIVE_TABLE: string[] = (() => {
  const lines = RAW.split('\n');
  const start = lines.findIndex((l) => /^##\s+Active assignments/.test(l));
  if (start === -1) return [];
  const out: string[] = [];
  for (let i = start; i < lines.length; i++) {
    const l = lines[i];
    if (i > start && /^##\s/.test(l)) break;
    if (i > start && l.trim() === '' && out.some((x) => x.startsWith('|'))) break;
    out.push(l);
  }
  return out.filter((l, i) => !(i > 0 && l.trim() === ''));
})();
