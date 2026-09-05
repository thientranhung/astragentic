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
      headline: 'Bốn Builder chạy cùng lúc.\nKhông ai giẫm lên việc của ai.',
      sub: 'Mình dựng lớp điều phối để việc không rơi mất giữa các session.',
      primary: 'Xem cấu trúc',
      secondary: 'Cài cho repo của anh em',
    },
    sections: {
      structure: {
        headline: 'Astragentic nằm ở đâu',
        sub: 'Bốn lớp, từ runtime xuống repo thật. Bấm vào một ô để mở trang của nó.',
      },
      roles: {
        headline: 'Năm vai, năm kiểu session',
        sub: 'Vai sống bao lâu quyết định nó nhớ được cái gì.',
      },
      lifecycle: {
        headline: 'Một ticket đi qua bảy chặng',
        sub: 'Bảy cái tên để khi một thứ hỏng, mình có chỗ treo nó vào.',
      },
      tracker: {
        headline: 'Thomas hỏi tracker, không nhớ tracker',
        sub: 'Cái gì sẵn để làm là một câu truy vấn trên board.',
      },
      skills: {
        headline: 'Skill có sẵn',
        sub: 'Mười sáu skill, xếp theo lúc anh em cần đến chúng.',
        cta: 'Cả catalog',
      },
      hooks: {
        headline: 'Bốn hook đứng gác',
        sub: 'Mỗi hook bắn ở một khoảnh khắc, và chỉ làm đúng một việc.',
      },
      why: {
        headline: 'Vì sao lại làm vậy',
        sub: 'Năm câu hỏi mình đã phải tự trả lời trước.',
      },
      stack: {
        headline: 'Mình dùng gì',
        sub: 'Chín thứ, và lý do từng thứ có mặt.',
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
      thomas: 'Router thường trú, giữ board và pane.',
      shaper: 'Grill tới khi spec đứng được.',
      builder: 'Một ticket, một worktree, một session.',
      rin: 'Đọc lại artifact và dấu vết.',
      qa: 'Chạy sản phẩm thật, không đọc code.',
    },
    ...cards('vi'),
  },
  en: {
    hero: {
      headline: 'Four Builders at once.\nNone of them in each other’s way.',
      sub: 'I built this layer so work stops falling between sessions.',
      primary: 'See the structure',
      secondary: 'Install it in your repo',
    },
    sections: {
      structure: {
        headline: 'Where Astragentic sits',
        sub: 'Four layers, from the runtime down to the real repo. Click a box to open its page.',
      },
      roles: {
        headline: 'Five roles, five session lifespans',
        sub: 'How long a role lives decides what it can remember.',
      },
      lifecycle: {
        headline: 'One ticket, seven checkpoints',
        sub: 'Seven names, so a failure has somewhere to hang.',
      },
      tracker: {
        headline: 'Thomas asks the tracker instead of remembering it',
        sub: 'What is ready to work on is a query on the board.',
      },
      skills: {
        headline: 'The skills',
        sub: 'Sixteen of them, filed by the moment you need one.',
        cta: 'The whole catalog',
      },
      hooks: {
        headline: 'Four hooks on guard',
        sub: 'Each one fires at a moment and does exactly one thing.',
      },
      why: {
        headline: 'Why it is built this way',
        sub: 'Five questions I had to answer first.',
      },
      stack: {
        headline: 'What this runs on',
        sub: 'Nine pieces, and why each one is here.',
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
      thomas: 'Resident router, holds the board and the panes.',
      shaper: 'Grills until the spec stands up.',
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
