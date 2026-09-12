// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

// portless supplies PORT/HOST; nothing is hardcoded and nothing auto-opens.
const port = process.env.PORT ? Number(process.env.PORT) : undefined;
const host = process.env.HOST || undefined;

// https://astro.build/config
export default defineConfig({
  site: 'https://astragentic.thisistool.com',
  // The dev toolbar is position:fixed, so it lands in the middle of a full-page
  // screenshot and hides whatever it covers. Off.
  devToolbar: { enabled: false },
  integrations: [
    mdx(),
    // One sitemap for both languages, with the vi/en pair declared on every entry so a
    // crawler that lands on one finds the other. `/explore/*` is archify's standalone
    // build under public/ and is not part of the reading site, so it stays out.
    sitemap({
      i18n: { defaultLocale: 'en', locales: { en: 'en', vi: 'vi' } },
      filter: (page) => !page.includes('/explore/'),
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
