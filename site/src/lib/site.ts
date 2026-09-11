export type Lang = 'vi' | 'en';

/** Every page that has a Vietnamese and an English twin. `roles` and `skills` point at
 *  the entry page of a set; the individual pages under them build their own pair. */
export type PageKey =
  | 'home'
  | 'structure'
  | 'roles'
  | 'skills'
  | 'hooks'
  | 'why'
  | 'stack'
  | 'adopt'
  | 'failures';

/** English is the primary language and lives at `/`; Vietnamese mirrors under `/vi/`
 *  with its own slugs (decided 2026-09-11, swapping the earlier vi-first layout).
 *  One table owns every route. Nav, LangSwitch and the pages all read from here,
 *  so a Vietnamese slug and its English twin can never drift apart. */
export const ROUTES: Record<PageKey, Record<Lang, string>> = {
  home: { vi: '/vi', en: '/' },
  structure: { vi: '/vi/cau-truc', en: '/structure' },
  roles: { vi: '/vi/vai/thomas', en: '/roles/thomas' },
  skills: { vi: '/vi/skills', en: '/skills' },
  hooks: { vi: '/vi/hooks', en: '/hooks' },
  why: { vi: '/vi/vi-sao', en: '/why' },
  stack: { vi: '/vi/tech-stack', en: '/tech-stack' },
  adopt: { vi: '/vi/cai', en: '/adopt' },
  failures: { vi: '/vi/loi', en: '/failures' },
};

/** Seven items, in the order the reader asks the questions (home v2 spec §Nav): why the
 *  thing exists, then what it is made of, then how to install it. */
export const NAV: { key: PageKey; label: Record<Lang, string> }[] = [
  { key: 'home', label: { vi: 'Trang chủ', en: 'Home' } },
  { key: 'why', label: { vi: 'Cách tiếp cận', en: 'Approach' } },
  { key: 'structure', label: { vi: 'Cấu trúc', en: 'Structure' } },
  { key: 'roles', label: { vi: 'Role', en: 'Roles' } },
  { key: 'skills', label: { vi: 'Skills', en: 'Skills' } },
  { key: 'hooks', label: { vi: 'Hooks', en: 'Hooks' } },
  { key: 'stack', label: { vi: 'Tech stack', en: 'Tech stack' } },
  { key: 'adopt', label: { vi: 'Install', en: 'Install' } },
];

export const REPO = 'https://github.com/thientranhung/astragentic';

/** Every UI string lives in one dictionary; see src/lib/ui.ts. */
export { UI, t } from './ui';

export const other = (lang: Lang): Lang => (lang === 'vi' ? 'en' : 'vi');
export const htmlLang = (lang: Lang) => (lang === 'vi' ? 'vi' : 'en');
