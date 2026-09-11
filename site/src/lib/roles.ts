import { getEntry } from 'astro:content';
import { ledger, type LedgerRow } from './data';
import { splitSections } from './pages';
import { REPO, type Lang } from './site';

export const ROLE_IDS = ['thomas', 'shaper', 'builder', 'rin', 'qa'] as const;
export type RoleId = (typeof ROLE_IDS)[number];

/** Label, sublabel and session tag are copied verbatim from the `data-node-*` attributes
 *  on `five-roles.svg`, so the page and the diagram cannot drift apart. English in both
 *  locales (rebuild spec §1 rule 3). `cites` is the landing spec §3 map: a ledger row
 *  belongs to a role when its `citedBy` names the role's contract file or one of its
 *  skills. */
export const ROLE_META: Record<
  RoleId,
  { label: string; sublabel: string; sessionTag: string; cites: string[] }
> = {
  thomas: {
    label: 'Thomas',
    sublabel: 'resident router',
    sessionTag: 'session: resident',
    cites: ['thomas.md', 'dispatch-ticket', 'reconcile-tracker'],
  },
  shaper: {
    label: 'Shaper',
    sublabel: 'grill → spec → tickets',
    sessionTag: 'session: unbroken',
    cites: ['shaper.md'],
  },
  builder: {
    label: 'Builder',
    sublabel: 'implements, own worktree',
    sessionTag: 'session: per ticket',
    cites: ['builder.md', 'CLEANUP.md', 'MARKERS.md'],
  },
  rin: {
    label: 'Rin',
    sublabel: 'verifies artifact + traces',
    sessionTag: 'session: per milestone',
    cites: ['rin.md', 'review-with-rin'],
  },
  qa: {
    label: 'QA',
    sublabel: 'runs the real product',
    sessionTag: 'session: per walk',
    cites: ['qa.md', 'dispatch-qa-walk'],
  },
};

/** Skill pages that document the role's own procedures. Only skills that exist as a
 *  page under /skills/ are listed; the contract file link covers the rest. */
export const ROLE_SKILLS: Record<RoleId, string[]> = {
  thomas: ['dispatch-ticket', 'reconcile-tracker'],
  shaper: [],
  builder: [],
  rin: ['review-with-rin'],
  qa: ['dispatch-qa-walk'],
};

export function roleHref(lang: Lang, id: string): string {
  return lang === 'vi' ? `/vi/role/${id}` : `/roles/${id}`;
}

export function roleContractHref(id: RoleId): string {
  return `${REPO}/blob/main/harness/.claude/agents/${id}.md`;
}

/** Every ledger row whose `citedBy` names a file or skill belonging to this role. */
export function roleDefects(id: RoleId): LedgerRow[] {
  const wanted = ROLE_META[id].cites;
  return ledger.filter((row) => (row.citedBy ?? []).some((name) => wanted.includes(name)));
}

export interface RoleContent {
  title: string;
  tagline: string;
  sessionTag: string;
  /** H2 slug (`does`, `may`, `may-not`) → HTML under it. */
  sections: Record<string, string>;
  intro: string;
  missing: boolean;
}

export async function getRole(lang: Lang, id: RoleId): Promise<RoleContent> {
  const entry = (await getEntry('roles', `${lang}/${id}`)) as
    | {
        data: { title: string; tagline?: string; sessionTag?: string };
        body?: string;
        rendered?: { html?: string };
      }
    | undefined;

  const meta = ROLE_META[id];
  if (!entry) {
    return {
      title: meta.label,
      tagline: meta.sublabel,
      sessionTag: meta.sessionTag,
      sections: {},
      intro: '',
      missing: true,
    };
  }

  const { intro, sections } = splitSections(entry.rendered?.html ?? '');
  return {
    title: entry.data.title || meta.label,
    tagline: entry.data.tagline || meta.sublabel,
    sessionTag: entry.data.sessionTag || meta.sessionTag,
    sections,
    intro,
    missing: false,
  };
}
