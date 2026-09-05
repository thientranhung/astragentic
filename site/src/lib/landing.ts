import { getEntry } from 'astro:content';
import { fillMeta } from './pages';
import { HOOKS, STACK, WHY } from './anchors';
import type { Lang } from './site';

/** Captions for the home page, one YAML file per locale (build spec 4 §4 and §6).
 *  The writer owns src/content/landing/{vi,en}.yaml. Until a field lands, the
 *  placeholder below renders, so a half-written file never breaks the build and the
 *  gap is visible on screen instead of hidden. */
export interface Caption {
  headline: string;
  sub: string;
}
export interface Landing {
  hero: { headline: string; sub: string; primary: string; secondary: string };
  sections: {
    structure: Caption;
    roles: Caption;
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
      headline: 'Bốn Builder chạy cùng lúc\ntrên một repo, không giẫm lên nhau.',
      sub: 'Tôi dựng lớp điều phối này để việc không rơi mất giữa các session.',
      primary: 'Xem cấu trúc',
      secondary: 'Cài cho repo của bạn',
    },
    sections: {
      structure: {
        headline: 'Astragentic nằm ở đâu trong stack',
        sub: 'Bốn lớp, từ runtime xuống repo thật. Bấm vào một ô để mở trang của lớp đó.',
      },
      roles: {
        headline: 'Năm vai, năm vòng đời session',
        sub: 'Vòng đời session quyết định một vai nhớ được gì.',
      },
      lifecycle: {
        headline: 'Một ticket đi qua bảy chặng',
        sub: 'Bảy chặng có tên để mỗi lỗi đo được gắn vào đúng một chặng.',
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
      arm: 'Codex đọc lại, biên nhận buộc vào SHA.',
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
      headline: 'Four Builders at once\non one repo, never in each other’s way.',
      sub: 'I built this coordination layer so work stops falling between sessions.',
      primary: 'See the structure',
      secondary: 'Install it in your repo',
    },
    sections: {
      structure: {
        headline: 'Where Astragentic sits in the stack',
        sub: 'Four layers, from the runtime down to the real repo. Click a box to open its page.',
      },
      roles: {
        headline: 'Five roles, five session lifetimes',
        sub: 'Session lifetime decides what a role can remember.',
      },
      lifecycle: {
        headline: 'A ticket passes through seven named stages',
        sub: 'The stages are named so every measured failure attaches to one of them.',
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
