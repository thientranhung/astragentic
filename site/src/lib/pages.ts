import { getEntry } from 'astro:content';
import { meta } from './data';
import type { Lang } from './site';

export interface Act {
  id: string;
  eyebrow?: string;
  headline?: string;
}
export interface PageContent {
  title: string;
  description: string;
  acts: Act[];
  /** Everything before the first H2, already HTML. */
  intro: string;
  /** H2 slug (`act-1`, `ast-016`, `orphan`, `brownfield`) → the HTML under it. */
  sections: Record<string, string>;
  missing: boolean;
}

/** Why split rendered HTML rather than the markdown source:
 *  Astro's glob loader already renders every entry and exposes the result on
 *  `entry.rendered.html` (verified on this Astro version — `getEntry` returns
 *  `{id,data,body,filePath,digest,rendered,collection}`). Splitting that string keeps
 *  full markdown fidelity — links, emphasis, lists, inline code — without re-implementing
 *  a parser or pulling in a second markdown pipeline. Astro also slugs every heading,
 *  so `## AST-016` becomes `<h2 id="ast-016">`, which is exactly the key we want.
 *  `entry.body` (raw markdown) is the fallback for the case where `rendered` is absent;
 *  it degrades to plain paragraphs instead of failing the build. */
const H2 = /<h2\b[^>]*\bid="([^"]+)"[^>]*>[\s\S]*?<\/h2>/gi;

export function splitSections(html: string): { intro: string; sections: Record<string, string> } {
  const sections: Record<string, string> = {};
  const marks: { id: string; start: number; end: number }[] = [];
  H2.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = H2.exec(html))) {
    marks.push({ id: m[1].toLowerCase(), start: m.index, end: m.index + m[0].length });
  }
  const intro = (marks.length ? html.slice(0, marks[0].start) : html).trim();
  marks.forEach((mark, i) => {
    const stop = i + 1 < marks.length ? marks[i + 1].start : html.length;
    sections[mark.id] = html.slice(mark.end, stop).trim();
  });
  return { intro, sections };
}

/** Fallback for the (unexpected) case where the loader gave us no rendered HTML:
 *  blank-line separated paragraphs, headings kept as boundaries. Escapes everything. */
function crudeRender(body: string): string {
  const esc = (s: string) =>
    s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return body
    .split(/\n{2,}/)
    .map((block) => block.trim())
    .filter(Boolean)
    .map((block) =>
      block.startsWith('##')
        ? `<h2 id="${block.replace(/^#+\s*/, '').toLowerCase().replace(/[^a-z0-9]+/g, '-')}">${esc(
            block.replace(/^#+\s*/, ''),
          )}</h2>`
        : `<p>${esc(block).replace(/\n/g, ' ')}</p>`,
    )
    .join('\n');
}

const numbers: Record<string, string> = {
  '{{meta.cited}}': String(meta.cited),
  '{{meta.orphan}}': String(meta.orphan),
  '{{meta.total}}': String(meta.total),
  '{{meta.version}}': String(meta.version),
};

/** Writers never hand-type a count; they leave `{{meta.total}}` and it is filled here. */
export function fillMeta(text: string): string {
  return text.replace(/\{\{meta\.(cited|orphan|total|version)\}\}/g, (whole) => numbers[whole] ?? whole);
}

export async function getPage(lang: Lang, slug: string): Promise<PageContent> {
  const entry = (await getEntry('pages', `${lang}/${slug}`)) as
    | { data: { title: string; description: string; acts?: Act[] }; body?: string; rendered?: { html?: string } }
    | undefined;

  if (!entry) {
    return {
      title: slug,
      description: '',
      acts: [],
      intro: '',
      sections: {},
      missing: true,
    };
  }

  const html = entry.rendered?.html ?? crudeRender(entry.body ?? '');
  const { intro, sections } = splitSections(fillMeta(html));
  return {
    title: fillMeta(entry.data.title),
    description: fillMeta(entry.data.description),
    acts: (entry.data.acts ?? []).map((act) => ({
      ...act,
      headline: act.headline ? fillMeta(act.headline) : act.headline,
    })),
    intro,
    sections,
    missing: false,
  };
}

export function act(page: PageContent, id: string): Act {
  return page.acts.find((a) => a.id === id) ?? { id };
}
