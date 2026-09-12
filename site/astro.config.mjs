// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

// portless supplies PORT/HOST; nothing is hardcoded and nothing auto-opens.
const port = process.env.PORT ? Number(process.env.PORT) : undefined;
const host = process.env.HOST || undefined;


/* ── language pairs for the sitemap ──────────────────────────────────────────
   Every address that exists in both languages, as `{ en, vi }`. Kept beside the
   config because `src/lib/site.ts` is TypeScript and the config cannot import it;
   the two must be changed together, and the build check below fails the build if a
   page in one language has no twin in the other. */
const PAGE_PAIRS = [
  { en: '/', vi: '/vi' },
  { en: '/structure', vi: '/vi/cau-truc' },
  { en: '/skills', vi: '/vi/skills' },
  { en: '/hooks', vi: '/vi/hooks' },
  { en: '/why', vi: '/vi/cach-tiep-can' },
  { en: '/tech-stack', vi: '/vi/tech-stack' },
  { en: '/adopt', vi: '/vi/cai' },
  { en: '/failures', vi: '/vi/loi' },
  ...['thomas', 'shaper', 'builder', 'rin', 'qa'].map((id) => ({
    en: `/roles/${id}`,
    vi: `/vi/role/${id}`,
  })),
];

const norm = (p) => (p.length > 1 ? p.replace(/\/$/, '') : p);
const abs = (p) => new URL(p === '/' ? '/' : `${p}/`, 'https://astragentic.thisistool.com').toString();

/** The `xhtml:link` rows for one address, or null when the page is English-only
 *  (the dictionary and the skill pages have no Vietnamese twin). */
function pairFor(pathname) {
  const path = norm(pathname);
  const skill = path.match(/^\/(?:vi\/)?skills\/(.+)$/);
  const pair = skill
    ? { en: `/skills/${skill[1]}`, vi: `/vi/skills/${skill[1]}` }
    : PAGE_PAIRS.find((p) => p.en === path || p.vi === path);
  if (!pair) return null;
  return [
    { lang: 'en', url: abs(pair.en) },
    { lang: 'vi', url: abs(pair.vi) },
    { lang: 'x-default', url: abs(pair.en) },
  ];
}

// https://astro.build/config
export default defineConfig({
  site: 'https://astragentic.thisistool.com',
  // The dev toolbar is position:fixed, so it lands in the middle of a full-page
  // screenshot and hides whatever it covers. Off.
  devToolbar: { enabled: false },
  integrations: [
    mdx(),
    // One sitemap for both languages. The integration's own `i18n` option pairs pages by
    // matching path, which only works where the two languages share a slug; ours do not
    // (`/why` ↔ `/vi/cach-tiep-can`), so it silently left those pages unpaired. The
    // pairing is done here instead, from the same table the pages link by.
    // `/explore/*` is archify's standalone build under public/ and is not part of the
    // reading site, so it stays out.
    sitemap({
      filter: (page) => !page.includes('/explore/'),
      serialize: (item) => {
        const pair = pairFor(new URL(item.url).pathname);
        return pair ? { ...item, links: pair } : item;
      },
    }),
  ],
  // /kien-truc and /en/architecture were pass-3 names for what is now /cau-truc
  // (build spec 4 §3). Astro emits a redirect page for each, so old links still land.
  // English moved to `/` and Vietnamese under `/vi/` on 2026-09-11; every address
  // from the vi-first layout still lands.
  redirects: {
    '/kien-truc': '/vi/cau-truc',
    '/en/architecture': '/structure',
    '/en': '/',
    '/en/structure': '/structure',
    '/en/why': '/why',
    '/en/adopt': '/adopt',
    '/en/failures': '/failures',
    '/en/evidence': '/failures',
    '/evidence': '/failures',
    '/en/hooks': '/hooks',
    '/en/tech-stack': '/tech-stack',
    '/en/skills': '/skills',
    '/en/skills/[slug]': '/skills/[slug]',
    '/en/roles/[id]': '/roles/[id]',
    '/cau-truc': '/vi/cau-truc',
    '/vi-sao': '/vi/cach-tiep-can',
    '/vi/vi-sao': '/vi/cach-tiep-can',
    '/cai': '/vi/cai',
    '/loi': '/vi/loi',
    '/bang-chung': '/vi/loi',
    '/vi/bang-chung': '/vi/loi',
    '/vai/[id]': '/vi/role/[id]',
    '/vi/vai/[id]': '/vi/role/[id]',
  },
  // English is the primary language and lives at `/`; Vietnamese mirrors under `/vi/`.
  // Route files are explicit (vi/loi.astro / failures.astro) because the Vietnamese
  // slugs are not transliterations of the English ones.
  i18n: {
    defaultLocale: 'en',
    locales: ['vi', 'en'],
    routing: {
      prefixDefaultLocale: false,
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
  server: {
    port,
    host,
    open: false,
  },
});
