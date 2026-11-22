import { getCollection } from 'astro:content';
import { REPO } from './site';

let warned = false;

/** Prints one line at build time naming every entry that has no `harness:` stamp.
 *  Called from DocsLayout, so it runs once per build and costs one collection scan. */
export async function warnUnstamped(): Promise<void> {
  if (warned) return;
  warned = true;
  const names = ['skills', 'dictionary', 'essays', 'pages', 'roles', 'landing'] as const;
  const missing: string[] = [];
  for (const name of names) {
    for (const e of (await getCollection(name)) as { id: string; data: { harness?: string } }[]) {
      if (!e.data.harness) missing.push(`${name}/${e.id}`);
    }
  }
  if (missing.length) console.warn(`[harness-stamp] ${missing.length} entries without harness: ${missing.join(', ')}`);
}

export const harnessHref = (v: string) => `${REPO}/tree/${v}`;
