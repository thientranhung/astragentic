import { getEntry } from 'astro:content';
import { fillMeta } from './pages';
import { HOOKS, STACK, WHY } from './anchors';
import type { Lang } from './site';

/** Captions for the home page, one YAML file per locale (build spec 4 §4 and §6).
 *  The writer owns src/content/landing/{vi,en}.yaml. Until a field lands, the
 *  placeholder below renders, so a half-written file never breaks the build and the
 *  gap is visible on screen instead of hidden. */
export interface Requirement {
  name: string;
  tag?: string;
  role?: string;
  href?: string;
}

export interface Caption {
  eyebrow?: string;
  headline: string;
  sub: string;
}
/** A caption with a short list under it: the team section names what Thomas does. */
export interface TeamCaption extends Caption {
  pointsLabel?: string;
  points?: { title: string; body: string }[];
}
/** One card in the feature grid (home v2 §Section 2). `crop` names the nodes the
 *  thumbnail is cut down to; see src/lib/diagram.ts. A card with no `diagram` is copy
 *  only, and HomeBody decides what stands in for the picture. */
export interface Feature {
  id: string;
  title: string;
  body: string;
  diagram?: string;
  crop?: string[];
  href?: string;
}

/** One row inside an explain section: a role card, a quoted requirement, or a line of
 *  the role → skill table. Only the fields a section uses are filled. */
export interface ExplainItem {
  id?: string;
  title?: string;
  tag?: string;
  session?: string;
  body?: string;
  /** Verbatim English, quoted rather than translated (PRD §4). */
  text?: string;
  href?: string;
}

/** One pane of literal commands. A section may declare one or several. */
export interface Pane {
  label?: string;
  lines: string[];
}

/** One of the explain sections (home explain spec §A-§E). */
export interface Explain {
  eyebrow: string;
  headline: string;
  paragraphs?: string[];
  /** A short list under the prose; the lead-in before the colon is emphasised. */
  bullets?: string[];
  /** Prose that resumes after the bullets. */
  paragraphsAfter?: string[];
  commands?: Pane | Pane[];
  items?: ExplainItem[];
  more?: { label: string; href: string };
  models?: { label: string; intro: string; note: string };
  figureNote?: string;
}

/** The YAML may spell one pane as an object and several as a list; the page only ever
 *  wants a list. */
export const panes = (commands: Explain['commands']): Pane[] =>
  !commands ? [] : Array.isArray(commands) ? commands : [commands];

/** A photograph of the running system. Until `src` lands the page draws a dashed frame
 *  carrying the caption, so the gap is visible rather than hidden (home order §3). */
export interface Shot {
  caption: string;
  src?: string;
  video?: { mp4: string; webm?: string; poster?: string };
  deck?: { name: string; adapter: string; src: string; note?: string }[];
}

export interface Landing {
  hero: { eyebrow: string; headline: string; sub: string; primary: string; secondary: string };
  /** The five explain sections, keyed by their anchor id: agents, comms, roles,
   *  tracker, method. Empty until the YAML lands — HomeBody renders nothing for a
   *  section it has no copy for, rather than a placeholder heading. */
  explain: Record<string, Explain>;
  /** Section 1. Two columns of prose and a link onward; no picture. */
  why: { eyebrow?: string; headline: string; p1: string; p2: string; more: string };
  /** Section 2, in the writer's order. Empty until the YAML lands — the copy has one
   *  home, and duplicating six paragraphs into a fallback would give it two. */
  features: Feature[];
  /** Section 4. `fits` / `notYet` dodge the YAML keys `yes` and `no`. */
  fit: {
    eyebrow?: string;
    headline: string;
    body: string;
    fitsLabel: string;
    notYetLabel: string;
    fits: string[];
    notYet: string[];
  };
  /** Section 5. The four commands come from src/data/adopt.json. */
  adopt: {
    eyebrow?: string;
    headline: string;
    sub?: string;
    reqEyebrow?: string;
    reqHeadline?: string;
    reqSub?: string;
    reqTitle?: string;
    requirements?: Requirement[];
    steps?: { title: string; note?: string; lines: string[] }[];
  };
  /** Keyed by the slug HomeBody asks for: sendmessage, herdr, tracker. */
  shots: Record<string, Shot>;
  sections: {
    structure: Caption;
    roles: Caption;
    features?: Caption;
    team: TeamCaption;
    lifecycle: Caption;
    tracker: Caption;
    skills: Caption & { cta: string };
    hooks: Caption;
    why: Caption;
    stack: Caption;
  };
  stages: Record<string, string>;
  roleCards: Record<string, string>;
  /** Keyed by the anchor id on the destination page (src/lib/anchors.ts). */
  hooksCards: Record<string, { title: string; when: string; does: string }>;
  whyCards: Record<string, { question: string; oneLine: string }>;
  stackItems: Record<string, { name: string; oneLine: string }>;
  /** True when src/content/landing/<lang>.yaml has not landed at all. */
  missing: boolean;
}

/** What the landing shows before the writer's YAML lands: the same facts the
 *  destination pages carry, so the two can never disagree. */
const cards = (lang: Lang) => ({
  hooksCards: Object.fromEntries(
    HOOKS.map((hook) => [
      hook.id,
      { title: hook.event, when: hook.when[lang], does: hook.effect[lang] },
    ]),
  ),
  whyCards: Object.fromEntries(
    WHY.map((why) => [why.id, { question: why.question[lang], oneLine: why.answer[lang] }]),
  ),
  stackItems: Object.fromEntries(
    STACK.map((item) => [item.id, { name: item.name, oneLine: item.line[lang] }]),
  ),
});

const FALLBACK: Record<Lang, Omit<Landing, 'missing'>> = {
  vi: {
    hero: {
      eyebrow: 'Agentic engineering',
      headline: 'Bốn Builder chạy cùng lúc\ntrên một repo, không giẫm lên nhau.',
      sub: 'Tôi dựng lớp điều phối này để việc không rơi mất giữa các session.',
      primary: 'Xem cấu trúc',
      secondary: 'Install cho repo của bạn',
    },
    explain: {},
    why: { headline: '', p1: '', p2: '', more: '' },
    features: [],
    fit: { headline: '', body: '', fitsLabel: '', notYetLabel: '', fits: [], notYet: [] },
    adopt: { headline: '' },
    shots: {},
    sections: {
      structure: {
        headline: 'Astragentic nằm ở đâu trong stack',
        sub: 'Bốn lớp, từ runtime xuống repo thật. Bấm vào một ô để mở trang của lớp đó.',
      },
      roles: {
        headline: 'Năm role, năm vòng đời session',
        sub: 'Vòng đời session quyết định một agent nhớ được gì.',
      },
      features: {
        eyebrow: 'Tính năng',
        headline: 'Sáu điều một team làm được mà một agent đơn lẻ thì không.',
        sub: 'Mỗi thẻ mở trang giải thích cơ chế bên dưới.',
      },
      team: {
        eyebrow: 'Cách bạn làm việc với AI team',
        headline: 'Mô hình vận hành.',
        sub: 'Bạn là khách hàng, trao đổi với Thomas là người đại diện của team. Team làm việc quanh issue tracker, và mọi việc đều đi qua đó để bạn đọc lại được bất cứ lúc nào.',
        pointsLabel: 'Hằng ngày, bạn chỉ làm việc với Thomas',
        points: [
          {
            title: 'Thomas điều phối team.',
            body: 'Thomas mở session Shaper khi cần shape, dispatch ticket cho Builder theo capacity, gọi Rin gate ở mỗi milestone và QA walk trước khi merge. Bạn không phải tự gọi từng agent.',
          },
          {
            title: 'Thomas đọc báo cáo thay bạn.',
            body: 'Handback, receipt, kết luận gate, walk report đều về Thomas trước. Thomas đọc, đối chiếu với ticket, rồi kể lại cho bạn theo cách hai bên vẫn trao đổi: ngôn ngữ bạn dùng, mức chi tiết bạn cần, ví dụ thay cho thuật ngữ khi bạn muốn. Báo cáo gốc vẫn nằm trên tracker để bạn kiểm chứng.',
          },
          {
            title: 'Bạn chỉ cần làm Thomas hiểu ý định của mình.',
            body: 'Bạn nói điều mình muốn và hướng đi; Thomas tự triển khai với team, tự quyết trong quá trình làm. Nó chỉ quay lại hỏi khi một quyết định thật sự là của bạn, như UI/UX hay tech stack, và lúc đó câu hỏi đã được thu gọn thành một lựa chọn trả lời được.',
          },
        ],
      },
      lifecycle: {
        eyebrow: 'Vòng đời ticket',
        headline: 'Một ticket đi qua bảy stage.',
        sub: 'Bảy stage có tên, nên mỗi sự cố đo được gắn vào đúng một stage.',
      },
      tracker: {
        headline: 'Thomas hỏi tracker, không nhớ tracker',
        sub: 'Ticket nào sẵn sàng là kết quả một truy vấn trên board.',
      },
      skills: {
        headline: 'Mười sáu skill trong harness',
        sub: 'Mười sáu skill, xếp theo lúc bạn cần dùng chúng.',
        cta: 'Cả catalog',
      },
      hooks: {
        headline: 'Bốn hook chạy ở bốn thời điểm cố định',
        sub: 'Mỗi hook bắn ở một thời điểm và chỉ làm đúng một việc.',
      },
      why: {
        headline: 'Vì sao Astragentic được dựng như vậy',
        sub: 'Năm câu hỏi tôi đã phải tự trả lời trước.',
      },
      stack: {
        headline: 'Astragentic chạy trên gì',
        sub: 'Chín thành phần, và lý do từng thành phần có mặt.',
      },
    },
    stages: {
      claim: 'Assignee ghi rồi đọc lại.',
      brief: 'Dispatch vào pane, tại Base.',
      build: 'Builder làm trong worktree riêng.',
      'code-review': 'Rin đọc lại artifact và dấu vết.',
      simplify: 'Dọn marker, cắt phần thừa.',
      arm: 'Codex đọc lại, receipt buộc vào SHA.',
      merge: 'Ledger ghi một dòng, assignee gỡ.',
    },
    roleCards: {
      thomas: 'Thomas thường trú, giữ board và pane.',
      shaper: 'Shaper grill tới khi spec đứng được.',
      builder: 'Một ticket, một worktree, một session.',
      rin: 'Đọc lại artifact và dấu vết.',
      qa: 'Chạy sản phẩm thật, không đọc code.',
    },
    ...cards('vi'),
  },
  en: {
    hero: {
      eyebrow: 'Agentic engineering',
      headline: 'Four Builders at once\non one repo, never in each other’s way.',
      sub: 'I built this coordination layer so work stops falling between sessions.',
      primary: 'See the structure',
      secondary: 'Install it in your repo',
    },
    explain: {},
    why: { headline: '', p1: '', p2: '', more: '' },
    features: [],
    fit: { headline: '', body: '', fitsLabel: '', notYetLabel: '', fits: [], notYet: [] },
    adopt: { headline: '' },
    shots: {},
    sections: {
      structure: {
        headline: 'Where Astragentic sits in the stack',
        sub: 'Four layers, from the runtime down to the real repo. Click a box to open its page.',
      },
      roles: {
        headline: 'Five roles, five session lifetimes',
        sub: 'Session lifetime decides what a role can remember.',
      },
      features: {
        eyebrow: 'Features',
        headline: 'Six things a team can do that a single agent cannot.',
        sub: 'Each card opens the page that explains the mechanism behind it.',
      },
      team: {
        eyebrow: 'How you work with the AI team',
        headline: 'The operating model.',
        sub: "You are the client, talking to Thomas, the team's representative. The team works around the issue tracker, and everything passes through it so you can read it back at any time.",
        pointsLabel: 'Day to day, you work with Thomas alone',
        points: [
          {
            title: 'Thomas runs the team.',
            body: 'Thomas opens a Shaper session when something needs shaping, dispatches tickets to Builders up to capacity, calls Rin’s gate at every milestone and QA’s walk before a merge. You never summon an agent yourself.',
          },
          {
            title: 'Thomas reads the reports for you.',
            body: 'Handbacks, receipts, gate verdicts and walk reports reach Thomas first. Thomas reads them against the ticket and tells you what they say the way the two of you already talk: your language, the level of detail you want, an example in place of a term when you prefer one. The originals stay on the tracker for you to check.',
          },
          {
            title: 'You only have to make Thomas understand what you want.',
            body: 'You state what you want and where it is going; Thomas carries it out with the team and makes the calls along the way. It comes back to you only when a decision is genuinely yours, such as UI/UX or the tech stack, and by then the question has been reduced to a choice you can answer.',
          },
        ],
      },
      lifecycle: {
        eyebrow: 'Ticket lifecycle',
        headline: 'A ticket passes through seven stages.',
        sub: 'The stages are named, so every measured incident attaches to exactly one of them.',
      },
      tracker: {
        headline: 'Thomas asks the tracker instead of remembering it',
        sub: 'Which ticket is ready is the result of a query against the board.',
      },
      skills: {
        headline: 'Sixteen skills in the harness',
        sub: 'Sixteen skills, grouped by the moment you need one.',
        cta: 'The whole catalog',
      },
      hooks: {
        headline: 'Four hooks fire at four fixed moments',
        sub: 'Each hook fires at one moment and does exactly one thing.',
      },
      why: {
        headline: 'Why Astragentic is built this way',
        sub: 'Five questions I had to answer first.',
      },
      stack: {
        headline: 'What this runs on',
        sub: 'Nine components, and why each one is here.',
      },
    },
    stages: {
      claim: 'Assignee written, then read back.',
      brief: 'Dispatched into a pane, at Base.',
      build: 'The Builder works in its own worktree.',
      'code-review': 'Rin re-reads the artifact and the traces.',
      simplify: 'Markers cleared, the surplus cut.',
      arm: 'Codex re-reads; the receipt is bound to a SHA.',
      merge: 'One Ledger line written, assignee cleared.',
    },
    roleCards: {
      thomas: 'Thomas is resident, holding the board and the panes.',
      shaper: 'The Shaper grills until the spec stands up.',
      builder: 'One ticket, one worktree, one session.',
      rin: 'Re-reads the artifact and the traces.',
      qa: 'Runs the real product, never reads the code.',
    },
    ...cards('en'),
  },
};

type Partialish<T> = { [K in keyof T]?: T[K] extends object ? Partialish<T[K]> : T[K] };

/** Only fill from the fallback where the writer's file is silent. */
function merge<T extends Record<string, unknown>>(base: T, over: Partialish<T> | undefined): T {
  if (!over) return base;
  const out = { ...base } as Record<string, unknown>;
  for (const [key, value] of Object.entries(over)) {
    if (value === undefined || value === null || value === '') continue;
    const current = out[key];
    out[key] =
      typeof value === 'object' && !Array.isArray(value) && typeof current === 'object'
        ? merge(current as Record<string, unknown>, value as Record<string, unknown>)
        : typeof value === 'string'
          ? fillMeta(value)
          : value;
  }
  return out as T;
}

/** The YAML lists cards as an array so the writer keeps control of the order; the page
 *  wants them by anchor id. Missing fields fall back per field, not per card. */
function keyBy<T extends Record<string, unknown>>(
  rows: { [k: string]: unknown }[] | undefined,
  idKey: string,
  base: Record<string, T>,
): Record<string, T> {
  if (!rows?.length) return base;
  const out = { ...base };
  for (const row of rows) {
    const id = String(row[idKey] ?? '');
    if (!id) continue;
    const filled = Object.fromEntries(
      Object.entries(row)
        .filter(([key, value]) => key !== idKey && typeof value === 'string' && value !== '')
        .map(([key, value]) => [key, fillMeta(value as string)]),
    );
    out[id] = { ...(base[id] ?? ({} as T)), ...filled } as T;
  }
  return out;
}

type CardRows = {
  hooksCards?: { [k: string]: unknown }[];
  whyCards?: { [k: string]: unknown }[];
  stackItems?: { [k: string]: unknown }[];
};

export async function getLanding(lang: Lang): Promise<Landing> {
  const entry = (await getEntry('landing', lang)) as { data?: unknown } | undefined;
  const data = entry?.data as (Partialish<Omit<Landing, 'missing'>> & CardRows) | undefined;
  const base = FALLBACK[lang];
  const merged = merge(base, data);
  return {
    ...merged,
    hooksCards: keyBy(data?.hooksCards, 'id', base.hooksCards),
    whyCards: keyBy(data?.whyCards, 'slug', base.whyCards),
    stackItems: keyBy(data?.stackItems, 'slug', base.stackItems),
    missing: !entry,
  };
}
