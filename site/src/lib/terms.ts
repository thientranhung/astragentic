import type { Lang } from './site';

/** /dictionary/* is an English-only reference set: it has no Vietnamese twin, no
 *  language switch of its own, and none of the site nav's Vietnamese vocabulary. A
 *  Vietnamese page that links a term straight into it drops the reader onto a second,
 *  English site (PRD §4: one clean language per page).
 *
 *  So a term resolves per language. English keeps the dictionary entry; Vietnamese
 *  goes to the Vietnamese page that already explains the same thing. Only terms that
 *  really have a Vietnamese home are listed — a term missing from this table keeps the
 *  dictionary page in both locales, and gets no language switch, because there is
 *  nothing to switch to. */
export const TERM_VI: Record<string, string> = {
  tracker: '/vi/vi-sao#why-tracker',
  frontier: '/vi/cau-truc#coordination',
  'blocking-edge': '/vi/cau-truc#coordination',
  claim: '/vi/cau-truc#coordination',
  worktree: '/vi/vai/builder',
};

export const dictionaryHref = (slug: string) => `/dictionary/${slug}`;

/** Where a diagram node or a body link about `slug` should land, in this locale. */
export function termHref(lang: Lang, slug: string): string {
  return (lang === 'vi' && TERM_VI[slug]) || dictionaryHref(slug);
}

/** The vi/en pair for a dictionary page, or undefined when the term has no Vietnamese
 *  home — the language switch is then left off rather than pointed at a guess. */
export function termAlternate(slug: string): Record<Lang, string> | undefined {
  const vi = TERM_VI[slug];
  return vi ? { vi, en: dictionaryHref(slug) } : undefined;
}
