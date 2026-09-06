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
  | 'failures'
  | 'evidence';

/** One table owns every route. Nav, LangSwitch and the pages all read from here,
 *  so a Vietnamese slug and its English twin can never drift apart. */
export const ROUTES: Record<PageKey, Record<Lang, string>> = {
  home: { vi: '/', en: '/en' },
  structure: { vi: '/cau-truc', en: '/en/structure' },
  roles: { vi: '/vai/thomas', en: '/en/roles/thomas' },
  skills: { vi: '/skills', en: '/en/skills' },
  hooks: { vi: '/hooks', en: '/en/hooks' },
  why: { vi: '/vi-sao', en: '/en/why' },
  stack: { vi: '/tech-stack', en: '/en/tech-stack' },
  adopt: { vi: '/cai', en: '/en/adopt' },
  failures: { vi: '/loi', en: '/en/failures' },
  evidence: { vi: '/bang-chung', en: '/en/evidence' },
};

/** Seven items, in the order the reader asks the questions (home v2 spec §Nav): why the
 *  thing exists, then what it is made of, then how to install it. */
export const NAV: { key: PageKey; label: Record<Lang, string> }[] = [
  { key: 'why', label: { vi: 'Vì sao', en: 'Why' } },
  { key: 'structure', label: { vi: 'Cấu trúc', en: 'Structure' } },
  { key: 'roles', label: { vi: 'Vai', en: 'Roles' } },
  { key: 'skills', label: { vi: 'Skills', en: 'Skills' } },
  { key: 'hooks', label: { vi: 'Hooks', en: 'Hooks' } },
  { key: 'stack', label: { vi: 'Tech stack', en: 'Tech stack' } },
  { key: 'adopt', label: { vi: 'Cài', en: 'Adopt' } },
];

export const REPO = 'https://github.com/thientranhung/astragentic';

/** Every UI string lives in one dictionary; see src/lib/ui.ts. */
export { UI, t } from './ui';

export const other = (lang: Lang): Lang => (lang === 'vi' ? 'en' : 'vi');
export const htmlLang = (lang: Lang) => (lang === 'vi' ? 'vi' : 'en');
