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
    vi: 'Astragentic: một đơn vị outsource bằng agent, đặt kỹ sư vào vị trí khách hàng.',
    en: 'Astragentic: an agent outsourcing unit that puts the engineer in the client\'s seat.',
  },
  repoLink: { vi: 'GitHub ↗', en: 'GitHub ↗' },
  footerAdopt: { vi: 'Install', en: 'Install' },
  footerVersion: { vi: 'phiên bản', en: 'version' },
  footerCited: { vi: 'bài học đo được đã thành luật trong harness', en: 'measured lessons now enforced by a harness file' },
  footerGenerated: { vi: 'số liệu sinh ngày', en: 'data generated' },
  skipToContent: { vi: 'Sang phần nội dung', en: 'Skip to content' },

  /* ── read mode (design spec 5 §2) ── */
  onThisPage: { vi: 'Trên trang này', en: 'On this page' },
  contents: { vi: 'Mục lục', en: 'Contents' },
  overview: { vi: 'Tổng quan', en: 'Overview' },
  sideStructure: { vi: 'Cấu trúc', en: 'Structure' },
  sideRoles: { vi: 'Role', en: 'Roles' },
  sideSkills: { vi: 'Skills', en: 'Skills' },
  sideHooks: { vi: 'Hooks', en: 'Hooks' },
  sideWhy: { vi: 'Cách tiếp cận', en: 'Approach' },
  sideStack: { vi: 'Tech stack', en: 'Tech stack' },
  sideFailures: { vi: 'Bài học', en: 'Lessons' },
  sideAdopt: { vi: 'Install', en: 'Install' },
  roleKey: { vi: 'Màu role trong hình', en: 'Role colours in this figure' },

  /* ── hero strip ── */
  statLogged: { vi: 'lỗi đã ghi vào sổ', en: 'failure modes logged' },
  statBound: { vi: 'dòng đã buộc vào một file', en: 'bound to a file' },
  statRuntimes: { vi: 'runtime', en: 'runtimes' },

  /* ── verbatim quoting (PRD §4) ── */
  verbatim: { vi: 'nguyên văn · tiếng Anh', en: 'verbatim' },
  installLabel: { vi: 'năm bước · chạy theo thứ tự', en: 'five steps · in order' },
  trackerReqs: { vi: 'năm yêu cầu với tracker · nguyên văn từ tracker-contract.md', en: 'five requirements on the tracker · verbatim from tracker-contract.md' },

  /** Stands inside a dashed frame where a photograph of the running system will go. It
   *  says the picture is real and not yet taken, so the frame reads as a promise rather
   *  than a broken image (home order spec §3). */
  shotPending: { vi: 'ảnh thật · sẽ cập nhật', en: 'real screenshot · to come' },
  deckLabel: { vi: 'Chọn tracker', en: 'Choose a tracker' },
  wallOpen: { vi: 'mở lớn', en: 'open large' },
  close: { vi: 'Đóng', en: 'Close' },

  /* ── diagrams ── */
  explore: { vi: 'Xem sơ đồ đầy đủ ↗', en: 'Open the full diagram ↗' },
  /** The explore pages are archify's own standalone build and open in a new tab. The
   *  note used to add that their chrome is English; the owner cut that as noise. */
  exploreNote: {
    vi: 'mở tab mới',
    en: 'opens in a new tab',
  },
  /** Replaces archify's `aria-label="Focus …"` on a node that navigates. */
  nodeOpens: { vi: 'mở trang', en: 'open page' },
  diagramHint: {
    vi: 'Bấm vào một ô để sang trang của nó.',
    en: 'Click a box to open its page.',
  },

  /* ── landing feature cards ── */
  featureMore: { vi: 'Đọc tiếp →', en: 'Read more →' },
  /** Column heads on the role table, read out of orchestrator.md. "Runtime", "Model"
   *  and "Effort" are the file's own column names and stay English in both locales. */
  colRole: { vi: 'Role', en: 'Role' },
  colRuntime: { vi: 'Runtime', en: 'Runtime' },
  colModel: { vi: 'Model', en: 'Model' },
  colEffort: { vi: 'Effort', en: 'Effort' },
  /** Shown under the table only when a row still carries the file's `<set-me>`. */
  declareYourself: {
    vi: 'khai báo theo tài khoản của bạn',
    en: 'declare it for your own account',
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
  readAll: { vi: 'Khám phá sáu bài học đã đo được →', en: 'Explore the six measured lessons →' },

  /* ── adopt ── */
  installIt: { vi: 'Deploy vào repo của bạn →', en: 'Deploy to your repo →' },
  copy: { vi: 'Copy', en: 'Copy' },
  copied: { vi: 'Copied', en: 'Copied' },
  prerequisites: { vi: 'Cần sẵn', en: 'Prerequisites' },
  quickstart: { vi: 'Install', en: 'Install' },
  brownfield: { vi: 'Bốn skill cho repo có sẵn', en: 'Four skills for an existing repo' },

  /* ── roles ── */
  roleEyebrow: { vi: 'ROLE', en: 'ROLE' },
  roleDoes: { vi: 'Nó làm gì mỗi lượt', en: 'What it does each turn' },
  roleRights: { vi: 'Nó được phép và không được phép', en: 'What it may and may not do' },
  roleMay: { vi: 'Được', en: 'May' },
  roleMayNot: { vi: 'Không được', en: 'May not' },
  roleDefects: { vi: 'Lỗi nó đã gây ra hoặc bắt được', en: 'Failures it caused or caught' },
  roleNoDefects: {
    vi: 'chưa có mục nào trỏ về role này',
    en: 'nothing in the ledger points back to this role yet',
  },
  roleContract: { vi: 'Contract nguyên văn', en: 'The contract, verbatim' },
  roleSkills: { vi: 'Skill liên quan', en: 'Related skills' },
  roleMissing: {
    vi: 'Trang role này chưa có prose. Bằng chứng bên dưới là dữ liệu thật.',
    en: 'No prose for this role yet. The evidence below is live data.',
  },
  backHome: { vi: 'Về trang chủ →', en: 'Back to home →' },
  seeItRun: { vi: 'Khám phá cách nó chạy', en: 'Explore how it runs' },
  armSkill: { vi: 'Hiểu rõ hơn về codex-arm →', en: 'Learn more about codex-arm →' },
  trackerReq: { vi: 'Yêu cầu số 5', en: 'Requirement 5' },

  /* ── skills catalog ── */
  skillsTitle: { vi: 'Skill có sẵn', en: 'The skills' },
  skillsAll: { vi: 'Khám phá toàn bộ skill →', en: 'Explore all skills →' },
  skillsCount: { vi: 'skill', en: 'skills' },
  skillOneLiner: { vi: 'Nó làm gì', en: 'What it does' },
  skillSource: { vi: 'Nguồn', en: 'Source' },
  skillRuntimes: { vi: 'Chạy được trên', en: 'Runtimes' },
  skillUpdated: { vi: 'Cập nhật', en: 'Updated' },
  skillGroupLabel: { vi: 'Nhóm', en: 'Group' },
  skillBack: { vi: 'Về danh mục skill →', en: 'Back to the skill catalog →' },
  skillMissing: {
    vi: 'Trang skill này chưa có bản tiếng Việt. Dữ liệu bên dưới lấy từ catalog.',
    en: 'This skill page has no prose yet. The data below comes from the catalog.',
  },

  /* ── hooks ── */
  hooksTitle: { vi: 'Hook trong harness', en: 'The hooks in the harness' },
  hookWhen: { vi: 'Bắn khi', en: 'Fires when' },
  hookScript: { vi: 'Script', en: 'Script' },
  hookEffect: { vi: 'Chặn hay ghi', en: 'Blocks or logs' },
  hooksAll: { vi: 'Khám phá bốn hook →', en: 'Explore all four hooks →' },

  /* ── why ── */
  whyTitle: { vi: 'Cách tiếp cận', en: 'Approach' },
  whyAll: { vi: 'Khám phá năm lý do thiết kế →', en: 'Explore the five design decisions →' },

  /* ── tech stack ── */
  stackTitle: { vi: 'Astragentic chạy trên gì', en: 'What this runs on' },
  stackAll: { vi: 'Khám phá toàn bộ tech stack →', en: 'Explore the full tech stack →' },
  stackRequired: { vi: 'required', en: 'required' },
  stackOptional: { vi: 'optional', en: 'optional' },

  /* ── structure ── */
  structureTitle: { vi: 'Cấu trúc', en: 'Structure' },
  structureAll: { vi: 'Khám phá cấu trúc →', en: 'Explore the structure →' },
  goodParts: { vi: 'Các phần hay', en: 'The good parts' },
  layers: { vi: 'Bốn lớp', en: 'Four layers' },

  /* ── nav ── */
  repoAria: { vi: 'Astragentic trên GitHub', en: 'Astragentic on GitHub' },
  langAria: { vi: 'Ngôn ngữ', en: 'Language' },
  /** The phone-width disclosure that holds the seven destinations. */
  menu: { vi: 'Menu', en: 'Menu' },
  /** Under a diagram too wide for the screen it is being read on. */
  swipeDiagram: { vi: 'Vuốt ngang để xem hết sơ đồ', en: 'Scroll sideways for the whole diagram' },
  /** Under a screen capture on a phone, where the text inside it is too small to read. */
  shotZoom: { vi: 'Mở toàn màn hình để đọc rõ chữ', en: 'Open fullscreen to read the text' },
  /** On the button that does it. */
  shotFullLabel: { vi: 'Toàn màn hình', en: 'Fullscreen' },

  /* ── 404 ── */
  notFoundCode: { vi: '404', en: '404' },
  notFoundTitle: { vi: 'Không có trang này', en: 'No page here' },
  notFoundLine: {
    vi: 'Đường dẫn này không trỏ tới trang nào. Trang có thể đã đổi tên, hoặc địa chỉ bị gõ nhầm.',
    en: 'This address points at nothing. The page may have been renamed, or the address mistyped.',
  },
  notFoundHome: { vi: 'Về trang chủ', en: 'Back to the home page' },
  notFoundSkills: { vi: 'Khám phá catalog skill', en: 'Explore the skill catalog' },
} as const satisfies Record<string, Dict>;

export type UIKey = keyof typeof UI;

/** `t(lang)` reads better than `UI.key[lang]` when a component needs a dozen strings. */
export function t(lang: Lang) {
  return new Proxy({} as Record<UIKey, string>, {
    get: (_, key: string) => (UI as Record<string, Dict>)[key]?.[lang] ?? key,
  });
}
