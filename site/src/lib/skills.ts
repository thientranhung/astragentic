import { getCollection } from 'astro:content';
import catalog from '../data/skill-catalog.json';
import type { Lang } from './site';

export const GROUP_IDS = [
  'entry',
  'shaping',
  'main-flow',
  'gate',
  'brownfield',
  'upkeep',
  'adapter',
] as const;
export type GroupId = (typeof GROUP_IDS)[number];

/** aihero-style catalog: the reader picks a group by *when they need it*, not by what
 *  the skill is made of (PRD §5). Title and the one sentence under it are chrome, so
 *  they are translated; skill names never are. */
export const GROUPS: Record<
  GroupId,
  { title: Record<Lang, string>; short: Record<Lang, string>; line: Record<Lang, string> }
> = {
  entry: {
    title: { vi: 'Lúc mới vào repo', en: 'First contact' },
    short: { vi: 'Mới vào', en: 'First contact' },
    line: {
      vi: 'Lần đầu chạm vào một codebase có sẵn: đọc nó đã, rồi mới sửa.',
      en: 'First contact with an existing codebase: read it before you touch it.',
    },
  },
  shaping: {
    title: { vi: 'Lúc nắn việc', en: 'Shaping the work' },
    short: { vi: 'Nắn việc', en: 'Shaping' },
    line: {
      vi: 'Biến một ý còn mờ thành spec và ticket đứng được.',
      en: 'Turning a vague idea into a spec and tickets that stand up.',
    },
  },
  'main-flow': {
    title: { vi: 'Lúc chạy việc', en: 'Running the work' },
    short: { vi: 'Chạy việc', en: 'Running' },
    line: {
      vi: 'Đường đi thường ngày của một ticket, từ dispatch tới receipt.',
      en: 'The everyday path of a ticket, from dispatch to receipt.',
    },
  },
  gate: {
    title: { vi: 'Lúc qua gate', en: 'At the gate' },
    short: { vi: 'Gate', en: 'Gate' },
    line: {
      vi: 'Chỗ một người khác đọc lại trước khi thứ gì đó đi tiếp.',
      en: 'Where someone else re-reads before anything moves on.',
    },
  },
  brownfield: {
    title: { vi: 'Lúc gặp code cũ', en: 'When the code is old' },
    short: { vi: 'Code cũ', en: 'Legacy' },
    line: {
      vi: 'Code có sẵn đã chạy lâu: không test, không ranh giới module.',
      en: 'Code that has lived a while: no tests, no module boundaries.',
    },
  },
  upkeep: {
    title: { vi: 'Lúc dọn dẹp', en: 'Keeping it honest' },
    short: { vi: 'Dọn dẹp', en: 'Upkeep' },
    line: {
      vi: 'Việc định kỳ để board và git không kể hai câu chuyện khác nhau.',
      en: 'The recurring work that keeps the board and git telling one story.',
    },
  },
  adapter: {
    title: { vi: 'Lúc đổi runtime hoặc tracker', en: 'Same flow, other tooling' },
    short: { vi: 'Runtime khác', en: 'Adapters' },
    line: {
      vi: 'Cùng một quy trình, chạy trên runtime khác hoặc tracker khác.',
      en: 'The same procedure against a different runtime or a different tracker.',
    },
  },
};

/** The catalog JSON predates the `adapter` group; these six are runtime- and
 *  tracker-specific variants of a procedure documented elsewhere. A skill file whose
 *  frontmatter carries `group:` always wins over this map. */
const REGROUP: Record<string, GroupId> = {
  'dispatch-ticket-claude': 'adapter',
  'dispatch-ticket-codex': 'adapter',
  'dispatch-ticket-opencode': 'adapter',
  'github-issue-tracker': 'adapter',
  'jira-issue-tracker': 'adapter',
  'linear-issue-tracker': 'adapter',
};

/** One verb line per skill, used until the writer's `skills/<lang>/<name>.md` lands.
 *  Each line is a compression of the catalog one-liner, not a new claim. */
const VERB: Record<string, Record<Lang, string>> = {
  'batch-triage': {
    vi: 'Phân loại cả một backlog kế thừa trong một lượt.',
    en: 'Triage an inherited backlog in one pass.',
  },
  'bootstrap-glossary': {
    vi: 'Gieo CONTEXT.md bằng chính từ vựng codebase đang dùng.',
    en: 'Seed CONTEXT.md with the terms the code already uses.',
  },
  'codex-arm': {
    vi: 'Chạy một lượt Codex đọc lại artifact trước khi nó merge.',
    en: 'Fire a Codex pass over a finished artifact before it merges.',
  },
  'codex-claude-arm': {
    vi: 'Chạy một lượt Claude đọc lại artifact khi runtime gốc là Codex.',
    en: 'Fire the Claude pass when the root runtime is Codex.',
  },
  'dispatch-ticket': {
    vi: 'Đẩy một ticket đã claim thành một pane nhìn thấy được.',
    en: 'Dispatch one claimed ticket as a visible pane.',
  },
  'dispatch-ticket-claude': {
    vi: 'Launch và xác nhận một Builder trên Claude Code.',
    en: 'Launch and verify a Builder on Claude Code.',
  },
  'dispatch-ticket-codex': {
    vi: 'Launch và xác nhận một Builder trên Codex.',
    en: 'Launch and verify a Builder on Codex.',
  },
  'dispatch-ticket-opencode': {
    vi: 'Launch và xác nhận một Builder trên OpenCode.',
    en: 'Launch and verify a Builder on OpenCode.',
  },
  'dispatch-qa-walk': {
    vi: 'Đẩy QA đi một vòng trên sản phẩm đang chạy.',
    en: 'Dispatch QA on a walk through the running product.',
  },
  'review-with-rin': {
    vi: 'Chạy gate milestone của Rin trong một pane quan sát được.',
    en: "Run Rin's milestone gate as an observable pane.",
  },
  'github-issue-tracker': {
    vi: 'Vận hành tracker khi board là GitHub Issues.',
    en: 'Operate the tracker when the board is GitHub Issues.',
  },
  'jira-issue-tracker': {
    vi: 'Vận hành tracker khi board là Jira.',
    en: 'Operate the tracker when the board is Jira.',
  },
  'linear-issue-tracker': {
    vi: 'Vận hành tracker khi board là Linear.',
    en: 'Operate the tracker when the board is Linear.',
  },
  'legacy-testing': {
    vi: 'Đưa code chưa có test vào lưới characterisation test.',
    en: 'Get untested code under characterisation tests.',
  },
  untangle: {
    vi: 'Gỡ code rối tới mức không refactor thẳng được.',
    en: 'Untangle code too knotted for a straight refactor.',
  },
  'reconcile-tracker': {
    vi: 'Đối chiếu tracker với git để phát hiện trạng thái sai lệch.',
    en: 'Reconcile the tracker against what actually merged.',
  },
};

export interface SkillCard {
  name: string;
  title: string;
  /** One verb line, in `lang`. */
  line: string;
  group: GroupId;
  href: string;
  /** True when the line came from the fallback table, not from a content file. */
  fallback: boolean;
}

export function skillHref(lang: Lang, name: string): string {
  return lang === 'vi' ? `/skills/${name}` : `/en/skills/${name}`;
}

type Entry = {
  id: string;
  data: {
    title: string;
    oneLiner?: string;
    lang?: Lang;
    group?: string;
    order?: number;
  };
};

/** `vi/foo` → `{lang:'vi', name:'foo'}`; a flat legacy `foo.md` is English (pass 1). */
function locate(id: string): { lang: Lang; name: string } {
  const [head, ...rest] = id.split('/');
  if ((head === 'vi' || head === 'en') && rest.length) return { lang: head, name: rest.join('/') };
  return { lang: 'en', name: id };
}

const CATALOG = (catalog as { name: string; kind: string; oneLiner: string; group: string }[])
  .filter((row) => row.kind === 'skill');

/** The 16 canonical skill names, in catalog order. */
export const SKILL_NAMES = CATALOG.map((row) => row.name);

function groupOf(name: string, declared?: string): GroupId {
  if (declared && (GROUP_IDS as readonly string[]).includes(declared)) return declared as GroupId;
  if (REGROUP[name]) return REGROUP[name];
  const row = CATALOG.find((r) => r.name === name);
  return (row && (GROUP_IDS as readonly string[]).includes(row.group) ? row.group : 'main-flow') as GroupId;
}

/** Every skill, in this locale. A name always appears: the content file when the
 *  writer has landed it, the catalog + verb table otherwise. */
export async function getSkillCards(lang: Lang): Promise<SkillCard[]> {
  const entries = (await getCollection('skills')) as unknown as Entry[];
  const mine = new Map<string, Entry>();
  for (const entry of entries) {
    const at = locate(entry.id);
    const code = entry.data.lang ?? at.lang;
    if (code === lang) mine.set(at.name, entry);
  }

  const names = [...SKILL_NAMES];
  for (const name of mine.keys()) if (!names.includes(name)) names.push(name);

  return names.map((name) => {
    const entry = mine.get(name);
    const written = entry?.data.oneLiner?.trim();
    const fromTable = VERB[name]?.[lang];
    const fromCatalog = CATALOG.find((r) => r.name === name)?.oneLiner ?? name;
    return {
      name,
      title: entry?.data.title ?? name,
      line: written || fromTable || fromCatalog,
      group: groupOf(name, entry?.data.group),
      href: skillHref(lang, name),
      fallback: !written,
    };
  });
}

export interface SkillGroup {
  id: GroupId;
  title: string;
  line: string;
  skills: SkillCard[];
}

/** Grouped for the catalog page; a group with no skill in it is dropped. */
export async function getSkillGroups(lang: Lang): Promise<SkillGroup[]> {
  const cards = await getSkillCards(lang);
  return GROUP_IDS.map((id) => ({
    id,
    title: GROUPS[id].title[lang],
    line: GROUPS[id].line[lang],
    skills: cards.filter((card) => card.group === id),
  })).filter((group) => group.skills.length > 0);
}

/** The catalog one-liner, English, used as the detail line on a skill page that has
 *  no prose yet. */
export function catalogLine(name: string): string {
  return CATALOG.find((r) => r.name === name)?.oneLiner ?? '';
}
