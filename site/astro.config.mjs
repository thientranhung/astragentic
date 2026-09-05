// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import mdx from '@astrojs/mdx';

// portless supplies PORT/HOST; nothing is hardcoded and nothing auto-opens.
const port = process.env.PORT ? Number(process.env.PORT) : undefined;
const host = process.env.HOST || undefined;

// https://astro.build/config
export default defineConfig({
  site: 'https://astragentic.dev',
  // The dev toolbar is position:fixed, so it lands in the middle of a full-page
  // screenshot and hides whatever it covers. Off.
  devToolbar: { enabled: false },
  integrations: [mdx()],
  // /kien-truc and /en/architecture were pass-3 names for what is now /cau-truc
  // (build spec 4 §3). Astro emits a redirect page for each, so old links still land.
  redirects: {
    '/kien-truc': '/cau-truc',
    '/en/architecture': '/en/structure',
  },
  // Vietnamese is the primary language and lives at `/`; English mirrors under `/en/`.
  // Route files are explicit (loi.astro / en/failures.astro) because the Vietnamese
  // slugs are not transliterations of the English ones.
  i18n: {
    defaultLocale: 'vi',
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
