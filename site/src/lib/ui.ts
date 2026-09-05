import type { Lang } from './site';

/** Every string the layout writes itself, in both locales (PRD §4: one clean language
 *  per page). Nothing here may stay English on a Vietnamese page.
 *
 *  What is deliberately NOT translated, in either direction: role names (Thomas,
 *  Shaper, Builder, Rin, QA), skill names, shell commands, file paths, AST ids, and
 *  verbatim quotes lifted out of the ledger or the release notes. Those are proper
 *  nouns of the harness; a quote wearing a `verbatim` label is a third case and keeps
 *  `lang="en"` so a screen reader switches voice. */
export type Dict = Record<Lang, string>;

export const UI = {
  /* ── chrome ── */
  tagline: {
    vi: 'Astragentic — lớp điều phối cho nhiều agent trên một codebase thật.',
    en: 'Astragentic — the orchestration layer for coding agents on a real codebase.',
  },
  repoLink: { vi: 'GitHub ↗', en: 'GitHub ↗' },
  footerAdopt: { vi: 'Cài', en: 'Adopt' },
  footerVersion: { vi: 'phiên bản', en: 'version' },
  footerCited: { vi: 'dòng đã buộc vào file', en: 'entries bound to a file' },
  footerGenerated: { vi: 'số liệu sinh ngày', en: 'data generated' },
  skipToContent: { vi: 'Sang phần nội dung', en: 'Skip to content' },

  /* ── hero strip ── */
  heroEyebrow: {
    vi: 'Lớp điều phối cho nhiều agent trên một codebase thật',
    en: 'Orchestration layer for coding agents',
  },
  statLogged: { vi: 'lỗi đã ghi vào sổ', en: 'failure modes logged' },
  statBound: { vi: 'dòng đã buộc vào một file', en: 'bound to a file' },
  statRuntimes: { vi: 'runtime', en: 'runtimes' },

  /* ── verbatim quoting (PRD §4) ── */
  verbatim: { vi: 'nguyên văn · tiếng Anh', en: 'verbatim' },

  /* ── diagrams ── */
  explore: { vi: 'Mở bản tương tác ↗', en: 'Explore ↗' },
  /** The explore pages are archify's own standalone build: they open in a new tab and
   *  their chrome is English even when the labels are Vietnamese. Say so before the
   *  click, not after (PRD §4). */
  exploreNote: {
    vi: 'mở tab mới · giao diện tiếng Anh',
    en: 'opens in a new tab',
  },
  /** Replaces archify's `aria-label="Focus …"` on a node that navigates. */
  nodeOpens: { vi: 'mở trang', en: 'open page' },
  diagramHint: {
    vi: 'Bấm vào một ô để sang trang của nó.',
    en: 'Click a box to open its page.',
  },

  /* ── ledger / evidence tables ── */
  filter: { vi: 'lọc theo mã hoặc bài học…', en: 'filter by id or lesson…' },
  colId: { vi: 'Mã', en: 'ID' },
  colLesson: { vi: 'Bài học', en: 'Lesson' },
  colStatus: { vi: 'Trạng thái', en: 'Status' },
  colCited: { vi: 'File đang trỏ về', en: 'Cited by' },
  promoted: { vi: 'đã lên luật', en: 'promoted' },
  carriedBy: { vi: 'File đang mang luật', en: 'Files carrying the rule' },
  rowsShown: { vi: 'dòng đang hiện', en: 'rows shown' },
  noRefs: { vi: 'chưa có gì trỏ về', en: 'nothing points back here' },
  emptyStage: { vi: 'chưa đo được lỗi nào ở đây', en: 'no failure measured here yet' },
  commitsHeading: {
    vi: '20 commit gần nhất có dòng Ledger:',
    en: 'The last 20 commits carrying a Ledger: line',
  },
  readAll: { vi: 'Sáu lỗi, đọc đủ →', en: 'Six failures, read them all →' },
  wholeTable: { vi: 'Cả bảng, và 65 dòng mồ côi →', en: 'The whole table, and 65 orphan rows →' },

  /* ── adopt ── */
  installIt: { vi: 'Cài cho repo của anh em →', en: 'Install it in your repo →' },
  copy: { vi: 'Chép', en: 'Copy' },
  copied: { vi: 'Đã chép', en: 'Copied' },
  prerequisites: { vi: 'Cần sẵn', en: 'Prerequisites' },
  quickstart: { vi: 'Bốn lệnh', en: 'Four commands' },
  brownfield: { vi: 'Bốn skill cho repo có sẵn', en: 'Four skills for an existing repo' },

  /* ── roles ── */
  roleEyebrow: { vi: 'VAI', en: 'ROLE' },
  roleDoes: { vi: 'Nó làm gì mỗi lượt', en: 'What it does each turn' },
  roleRights: { vi: 'Nó được phép và không được phép', en: 'What it may and may not do' },
  roleMay: { vi: 'Được', en: 'May' },
  roleMayNot: { vi: 'Không được', en: 'May not' },
  roleDefects: { vi: 'Lỗi nó đã gây ra hoặc bắt được', en: 'Failures it caused or caught' },
  roleNoDefects: {
    vi: 'chưa có mục nào trỏ về vai này',
    en: 'nothing in the ledger points back to this role yet',
  },
  roleContract: { vi: 'Contract nguyên văn', en: 'The contract, verbatim' },
  roleSkills: { vi: 'Skill liên quan', en: 'Related skills' },
  roleMissing: {
    vi: 'Trang vai này chưa có prose — bằng chứng bên dưới là thật.',
    en: 'No prose for this role yet — the evidence below is live.',
  },
  backHome: { vi: 'Về trang chủ →', en: 'Back to the home page →' },
  seeItRun: { vi: 'Xem nó chạy', en: 'Watch it run' },
  armSkill: { vi: 'Đọc skill codex-arm →', en: 'Read the codex-arm skill →' },
  trackerReq: { vi: 'Yêu cầu số 5', en: 'Requirement 5' },

  /* ── skills catalog ── */
  skillsTitle: { vi: 'Skill có sẵn', en: 'The skills' },
  skillsAll: { vi: 'Cả catalog →', en: 'The whole catalog →' },
  skillsCount: { vi: 'skill', en: 'skills' },
  skillOneLiner: { vi: 'Nó làm gì', en: 'What it does' },
  skillSource: { vi: 'Nguồn', en: 'Source' },
  skillRuntimes: { vi: 'Chạy được trên', en: 'Runtimes' },
  skillUpdated: { vi: 'Cập nhật', en: 'Updated' },
  skillGroupLabel: { vi: 'Nhóm', en: 'Group' },
  skillBack: { vi: 'Về catalog skill →', en: 'Back to the skill catalog →' },
  skillMissing: {
    vi: 'Trang skill này chưa có bản tiếng Việt — dữ liệu bên dưới lấy từ catalog.',
    en: 'This skill page has no prose yet — the data below comes from the catalog.',
  },

  /* ── hooks ── */
  hooksTitle: { vi: 'Hook đứng gác', en: 'The hooks on guard' },
  hookWhen: { vi: 'Bắn khi', en: 'Fires when' },
  hookScript: { vi: 'Script', en: 'Script' },
  hookEffect: { vi: 'Chặn hay ghi', en: 'Blocks or logs' },
  hooksAll: { vi: 'Bốn hook, đọc đủ →', en: 'All four hooks →' },

  /* ── why ── */
  whyTitle: { vi: 'Vì sao', en: 'Why' },
  whyAll: { vi: 'Năm câu vì sao →', en: 'All five answers →' },

  /* ── tech stack ── */
  stackTitle: { vi: 'Mình dùng gì', en: 'What this runs on' },
  stackAll: { vi: 'Cả tech stack →', en: 'The whole stack →' },
  stackRequired: { vi: 'bắt buộc', en: 'required' },
  stackOptional: { vi: 'tuỳ chọn', en: 'optional' },

  /* ── structure ── */
  structureTitle: { vi: 'Cấu trúc', en: 'Structure' },
  structureAll: { vi: 'Xem cấu trúc →', en: 'See the structure →' },
  goodParts: { vi: 'Các phần hay', en: 'The good parts' },
  openLedger: { vi: 'Mở cuốn sổ →', en: 'Open the ledger →' },
  layers: { vi: 'Bốn lớp', en: 'Four layers' },

  /* ── nav ── */
  repoAria: { vi: 'Astragentic trên GitHub', en: 'Astragentic on GitHub' },
  langAria: { vi: 'Ngôn ngữ', en: 'Language' },

  /* ── 404 ── */
  notFoundCode: { vi: '404', en: '404' },
  notFoundTitle: { vi: 'Không có trang này', en: 'No page here' },
  notFoundLine: {
    vi: 'Đường dẫn này không trỏ tới trang nào — có thể nó đã đổi tên, có thể mình gõ nhầm.',
    en: 'This address points at nothing — it may have been renamed, or mistyped.',
  },
  notFoundHome: { vi: 'Về trang chủ', en: 'Back to the home page' },
  notFoundSkills: { vi: 'Xem catalog skill', en: 'See the skill catalog' },
} as const satisfies Record<string, Dict>;

export type UIKey = keyof typeof UI;

/** `t(lang)` reads better than `UI.key[lang]` when a component needs a dozen strings. */
export function t(lang: Lang) {
  return new Proxy({} as Record<UIKey, string>, {
    get: (_, key: string) => (UI as Record<string, Dict>)[key]?.[lang] ?? key,
  });
}
