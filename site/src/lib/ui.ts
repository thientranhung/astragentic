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
    vi: 'Astragentic: một đơn vị outsource bằng agent, đặt kỹ sư vào vai khách hàng.',
    en: 'Astragentic: an agent outsourcing unit that puts the engineer in the client\'s seat.',
  },
  repoLink: { vi: 'GitHub ↗', en: 'GitHub ↗' },
  footerAdopt: { vi: 'Cài', en: 'Adopt' },
  footerVersion: { vi: 'phiên bản', en: 'version' },
  footerCited: { vi: 'dòng ledger đã buộc vào file', en: 'entries bound to a file' },
  footerGenerated: { vi: 'số liệu sinh ngày', en: 'data generated' },
  skipToContent: { vi: 'Sang phần nội dung', en: 'Skip to content' },

  /* ── read mode (design spec 5 §2) ── */
  onThisPage: { vi: 'Trên trang này', en: 'On this page' },
  contents: { vi: 'Mục lục', en: 'Contents' },
  overview: { vi: 'Tổng quan', en: 'Overview' },
  sideStructure: { vi: 'Cấu trúc', en: 'Structure' },
  sideRoles: { vi: 'Vai', en: 'Roles' },
  sideSkills: { vi: 'Skills', en: 'Skills' },
  sideHooks: { vi: 'Hooks', en: 'Hooks' },
  sideWhy: { vi: 'Vì sao', en: 'Why' },
  sideStack: { vi: 'Tech stack', en: 'Tech stack' },
  sideFailures: { vi: 'Lỗi', en: 'Failures' },
  sideEvidence: { vi: 'Bằng chứng', en: 'Evidence' },
  sideAdopt: { vi: 'Cài', en: 'Adopt' },
  roleKey: { vi: 'Màu vai trong hình', en: 'Role colours in this figure' },

  /* ── hero strip ── */
  statLogged: { vi: 'lỗi đã ghi vào sổ', en: 'failure modes logged' },
  statBound: { vi: 'dòng đã buộc vào một file', en: 'bound to a file' },
  statRuntimes: { vi: 'runtime', en: 'runtimes' },

  /* ── verbatim quoting (PRD §4) ── */
  verbatim: { vi: 'nguyên văn · tiếng Anh', en: 'verbatim' },

  /** Stands inside a dashed frame where a photograph of the running system will go. It
   *  says the picture is real and not yet taken, so the frame reads as a promise rather
   *  than a broken image (home order spec §3). */
  shotPending: { vi: 'ảnh thật · sẽ cập nhật', en: 'real screenshot · to come' },

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

  /* ── landing feature cards ── */
  featureMore: { vi: 'Tìm hiểu thêm →', en: 'Read more →' },
  /** Column heads on the role table, read out of orchestrator.md. "Runtime", "Model"
   *  and "Effort" are the file's own column names and stay English in both locales. */
  colRole: { vi: 'Vai', en: 'Role' },
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
  readAll: { vi: 'Xem sáu lỗi đã đo được →', en: 'See the six measured failures →' },
  wholeTable: { vi: 'Xem toàn bộ ledger →', en: 'View the full ledger →' },

  /* ── adopt ── */
  installIt: { vi: 'Triển khai vào repo của bạn →', en: 'Deploy to your repo →' },
  copy: { vi: 'Chép', en: 'Copy' },
  copied: { vi: 'Đã chép', en: 'Copied' },
  prerequisites: { vi: 'Cần sẵn', en: 'Prerequisites' },
  quickstart: { vi: 'Cài đặt', en: 'Install' },
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
    vi: 'Trang vai này chưa có prose. Bằng chứng bên dưới là dữ liệu thật.',
    en: 'No prose for this role yet. The evidence below is live data.',
  },
  backHome: { vi: 'Về trang chủ →', en: 'Back to home →' },
  seeItRun: { vi: 'Xem nó chạy', en: 'Watch it run' },
  armSkill: { vi: 'Xem skill codex-arm →', en: 'View the codex-arm skill →' },
  trackerReq: { vi: 'Yêu cầu số 5', en: 'Requirement 5' },

  /* ── skills catalog ── */
  skillsTitle: { vi: 'Skill có sẵn', en: 'The skills' },
  skillsAll: { vi: 'Xem toàn bộ skill →', en: 'Browse all skills →' },
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
  hooksAll: { vi: 'Xem bốn hook →', en: 'See all four hooks →' },

  /* ── why ── */
  whyTitle: { vi: 'Vì sao', en: 'Why' },
  whyAll: { vi: 'Xem năm lý do thiết kế →', en: 'See the five design decisions →' },

  /* ── tech stack ── */
  stackTitle: { vi: 'Astragentic chạy trên gì', en: 'What this runs on' },
  stackAll: { vi: 'Xem toàn bộ tech stack →', en: 'View the full tech stack →' },
  stackRequired: { vi: 'bắt buộc', en: 'required' },
  stackOptional: { vi: 'tuỳ chọn', en: 'optional' },

  /* ── structure ── */
  structureTitle: { vi: 'Cấu trúc', en: 'Structure' },
  structureAll: { vi: 'Xem cấu trúc →', en: 'See the structure →' },
  goodParts: { vi: 'Các phần hay', en: 'The good parts' },
  openLedger: { vi: 'Mở ledger →', en: 'Open the ledger →' },
  layers: { vi: 'Bốn lớp', en: 'Four layers' },

  /* ── nav ── */
  repoAria: { vi: 'Astragentic trên GitHub', en: 'Astragentic on GitHub' },
  langAria: { vi: 'Ngôn ngữ', en: 'Language' },

  /* ── 404 ── */
  notFoundCode: { vi: '404', en: '404' },
  notFoundTitle: { vi: 'Không có trang này', en: 'No page here' },
  notFoundLine: {
    vi: 'Đường dẫn này không trỏ tới trang nào. Trang có thể đã đổi tên, hoặc địa chỉ bị gõ nhầm.',
    en: 'This address points at nothing. The page may have been renamed, or the address mistyped.',
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
