/* archify's standalone explore pages ship a Google Fonts <link> for JetBrains Mono.
 * Every diagram on the site links to one of them, so a reader who opens a diagram makes
 * a request to a third party — on a site that self-hosts every other byte it serves.
 * Three reasons that is worth closing: it hands the reader's address to someone the
 * reader did not choose; Google Fonts is intermittently slow or blocked on Vietnamese
 * networks, and a blocked load leaves the diagram in a fallback mono; and a page that
 * is otherwise fully static should not depend on anything being up.
 *
 * These files are archify's output, so editing them by hand loses the change on the
 * next `archify deliver`. This runs before every build instead, and skips a file that
 * already carries the marker, so it is safe to run any number of times.
 *
 * The font itself is the same JetBrains Mono the site uses, copied out of the npm
 * package into public/fonts/ at a stable path — these pages are plain HTML in public/
 * and never pass through Vite, so they cannot use a hashed asset URL.
 */
import { readFile, writeFile, readdir } from 'node:fs/promises';
import { join, relative } from 'node:path';

const ROOT = new URL('../public/explore/', import.meta.url).pathname;
const MARKER = 'astragentic:local-mono';

/** One variable file per subset, and the axis covers every weight the pages ask for
 *  (400/500/600/700), so four static faces collapse into one request. */
const FACE = `  <!-- ${MARKER} — JetBrains Mono served from this origin, no third party -->
  <style>
    @font-face {
      font-family: 'JetBrains Mono';
      font-style: normal;
      font-weight: 100 800;
      font-display: swap;
      src: url('/fonts/jetbrains-mono-latin.woff2') format('woff2');
      unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC,
        U+0304, U+0308, U+0329, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212,
        U+2215, U+FEFF, U+FFFD;
    }
    @font-face {
      font-family: 'JetBrains Mono';
      font-style: normal;
      font-weight: 100 800;
      font-display: swap;
      src: url('/fonts/jetbrains-mono-latin-ext.woff2') format('woff2');
      unicode-range: U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304,
        U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0,
        U+2113, U+2C60-2C7F, U+A720-A7FF;
    }
    @font-face {
      font-family: 'JetBrains Mono';
      font-style: normal;
      font-weight: 100 800;
      font-display: swap;
      src: url('/fonts/jetbrains-mono-vietnamese.woff2') format('woff2');
      unicode-range: U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1,
        U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;
    }
  </style>`;

/* Matches archify's block whether or not it keeps the <noscript> twin: the preconnect,
   the media="print" stylesheet, and the noscript copy. Anything else in the head is
   left exactly where it is. */
const PATTERNS = [
  /[ \t]*<link rel="preconnect" href="https:\/\/fonts\.gstatic\.com"[^>]*>\n?/g,
  /[ \t]*<noscript>\s*<link href="https:\/\/fonts\.googleapis\.com[^>]*>\s*<\/noscript>\n?/g,
  /[ \t]*<link href="https:\/\/fonts\.googleapis\.com[^>]*>\n?/g,
];

async function* walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else if (entry.name.endsWith('.html')) yield path;
  }
}

let patched = 0;
let already = 0;
let untouched = 0;

for await (const file of walk(ROOT)) {
  const before = await readFile(file, 'utf8');
  if (before.includes(MARKER)) {
    already += 1;
    continue;
  }
  if (!/fonts\.(googleapis|gstatic)\.com/.test(before)) {
    untouched += 1;
    continue;
  }
  let after = before;
  for (const pattern of PATTERNS) after = after.replace(pattern, '');
  /* The face block goes where the links were, which is before the page's own <style>,
     so the page keeps the last word on anything it sets itself. */
  after = after.replace(/([ \t]*<style>)/, `${FACE}\n$1`);
  if (/fonts\.(googleapis|gstatic)\.com/.test(after.slice(0, after.indexOf('</head>')))) {
    throw new Error(`still calls a font CDN after patching: ${relative(ROOT, file)}`);
  }
  await writeFile(file, after);
  patched += 1;
}

console.log(
  `[explore-fonts] patched ${patched}, already local ${already}, no CDN reference ${untouched}`,
);
