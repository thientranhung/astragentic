import type { Lang } from './site';

type Dict = Record<Lang, string>;

/** The anchor tables for the four pages built out of `## <slug>` sections
 *  (build spec 4 §3 and §6). The writer owns the prose in
 *  `src/content/pages/<lang>/<page>.md`; this file owns the order, the anchor ids and
 *  the one line each card shows before the prose lands. Everything here is read off
 *  `harness/.claude/settings.json`, the hook scripts and the ledger — no new claims. */

/* ── /hooks ─────────────────────────────────────────────────────────────── */

export interface HookCard {
  id: string;
  /** Event name as Claude Code spells it. Never translated. */
  event: string;
  /** The script the hook shells out to, or null when the body is inline. */
  script: string | null;
  when: Dict;
  effect: Dict;
  /** The ledger entry that measured the failure this hook answers. */
  ast: string;
}

export const HOOKS: HookCard[] = [
  {
    id: 'pre-tool-use',
    event: 'PreToolUse · Bash',
    script: 'scripts/hook-git-guard.py',
    when: {
      vi: 'Trước mỗi lệnh Bash, lúc quyền còn chưa được quyết.',
      en: 'Before every Bash command, while permission is still being decided.',
    },
    effect: {
      vi: 'Tách argv ra rồi từ chối lệnh git phá việc của người khác. Nó chỉ từ chối, không bao giờ tự chạy gì.',
      en: 'Tokenises argv and denies the git commands that destroy someone else’s work. It only denies; it never acts.',
    },
    ast: 'AST-102',
  },
  {
    id: 'worktree-remove',
    event: 'WorktreeRemove',
    script: 'scripts/release-worktree-resources.sh',
    when: { vi: 'Khi một worktree bị gỡ.', en: 'When a worktree is removed.' },
    effect: {
      vi: 'Reap các tiến trình mọc trong worktree, rồi gọi plug riêng của project nếu có, và ghi một dòng vào log hook.',
      en: 'Reaps the processes rooted in the worktree, calls the project’s own release plug if it has one, and logs a line.',
    },
    ast: 'AST-100',
  },
  {
    id: 'session-start',
    event: 'SessionStart · compact',
    script: 'scripts/hook-contract-reload.py',
    when: { vi: 'Ngay sau khi context bị nén.', en: 'Right after the context is compacted.' },
    effect: {
      vi: 'Nạp lại contract của vai, vì bản đọc bằng Read là thứ bị nén đi trước nhất.',
      en: 'Re-arms the role contract, because a contract read with the Read tool is what compaction drops first.',
    },
    ast: 'AST-069',
  },
  {
    id: 'subagent-stop',
    event: 'SubagentStop',
    script: null,
    when: { vi: 'Khi một subagent dừng.', en: 'When a subagent stops.' },
    effect: {
      vi: 'Ghi loại agent, id và session vào /tmp/harness-hook-events.log. Không chặn gì cả.',
      en: 'Logs the agent type, id and session to /tmp/harness-hook-events.log. It blocks nothing.',
    },
    ast: 'AST-102',
  },
];

/* ── /tech-stack ────────────────────────────────────────────────────────── */

export interface StackItem {
  id: string;
  /** Product name. Never translated. */
  name: string;
  line: Dict;
  required: boolean;
}

export const STACK: StackItem[] = [
  {
    id: 'claude-code',
    name: 'Claude Code',
    line: {
      vi: 'Runtime gốc. Mọi vai chạy được ở đây, và gate milestone không có đường lui nào khác.',
      en: 'The root runtime. Every role can run here, and the milestone gate has no fallback.',
    },
    required: true,
  },
  {
    id: 'codex',
    name: 'Codex CLI',
    line: {
      vi: 'Cánh tay cross-vendor: một AI của hãng khác (Codex) đọc lại diff trước khi nó merge.',
      en: 'The cross-vendor arm: a different vendor re-reads the diff before it merges.',
    },
    required: false,
  },
  {
    id: 'opencode',
    name: 'OpenCode CLI',
    line: {
      vi: 'Runtime thứ ba để dispatch role, dùng khi bạn không muốn khoá vào một hãng.',
      en: 'A third runtime for role dispatch, for when you would rather not be locked to one vendor.',
    },
    required: false,
  },
  {
    id: 'git-worktree',
    name: 'git worktree',
    line: {
      vi: 'Ranh giới cách ly. Một Builder, một worktree, một người viết duy nhất ở đó.',
      en: 'The isolation boundary. One Builder, one worktree, one writer in it.',
    },
    required: true,
  },
  {
    id: 'herdr',
    name: 'herdr',
    line: {
      vi: 'Chỗ đứng của các pane. Việc đang chạy phải nhìn thấy được, không phải đoán.',
      en: 'Where the panes live. Work in flight has to be visible, not inferred.',
    },
    required: true,
  },
  {
    id: 'mattpocock-skills',
    name: 'mattpocock-skills',
    line: {
      vi: 'Phương pháp kỹ thuật của dự án: wayfinder, grill, spec, ticket, implement, review.',
      en: "The project's engineering method: wayfinder, grill, spec, tickets, implement, review.",
    },
    required: true,
  },
  {
    id: 'trackers',
    name: 'GitHub · Jira · Linear',
    line: {
      vi: 'Tracker giữ trạng thái. Cái gì sẵn để làm là một câu truy vấn, không phải trí nhớ của một session.',
      en: 'The tracker holds the state. What is ready is a query, not something a session remembers.',
    },
    required: true,
  },
  {
    id: 'scripts',
    name: 'Python · Bash',
    line: {
      vi: 'Script chạy được bằng tay: git guard, watchdog, ledger-index. Hook nào cũng gọi ra một file đọc được.',
      en: 'Scripts you can run by hand: the git guard, the watchdog, the ledger index. Every hook shells out to a readable file.',
    },
    required: true,
  },
  {
    id: 'archify',
    name: 'archify',
    line: {
      vi: 'Mọi diagram trên site này sinh từ JSON, nên sửa được bằng cách sửa dữ liệu, không vẽ lại tay.',
      en: 'Every diagram on this site is generated from JSON, so it is corrected by editing data, not redrawn by hand.',
    },
    required: false,
  },
];

/* ── /vi-sao ────────────────────────────────────────────────────────────── */

export interface WhyCard {
  id: string;
  question: Dict;
  /** Two sentences, standing in until the writer's `why.md` section lands. Each one is
   *  a compression of something already written down in the ledger, the ADRs or the
   *  role contracts — no new claim is made here. */
  answer: Dict;
}

export const WHY: WhyCard[] = [
  {
    id: 'why-astragentic',
    question: {
      vi: 'Mô hình orchestrator agent: bạn định hướng, Thomas điều phối',
      en: 'The orchestrator agent model: you set direction, Thomas coordinates',
    },
    answer: {
      vi: 'Coding agent đã đảm nhận được phần thi công; thời gian còn dồn vào trả lời và review chúng. Thomas nhận phần đó để bạn tập trung định hướng và quyết định.',
      en: 'A coding agent can carry the build; the time now goes to answering and reviewing it. Thomas takes that part so you can focus on direction and decisions.',
    },
  },
  {
    id: 'why-tracker',
    question: {
      vi: 'Issue tracker giữ trạng thái, không phải file markdown',
      en: 'The issue tracker holds the state, not a markdown file',
    },
    answer: {
      vi: 'Ô tick trong file markdown phụ thuộc vào việc agent nhớ quay lại sửa. Status, assignee và blocking edge trên board là dữ liệu máy đọc được, và bạn mở board ra là thấy.',
      en: 'A checkbox in a markdown file depends on the agent remembering to go back and edit it. Status, assignee and blocking edges on a board are machine-readable data, and you can open the board and see them.',
    },
  },
  {
    id: 'why-not-subagents',
    question: {
      vi: 'Subagent và agent team tốt trong một session; điều phối thì không nằm ở đó',
      en: 'Subagents and agent teams are good inside one session; coordination is not',
    },
    answer: {
      vi: 'Astragentic vẫn dùng cả hai: subagent trong session Builder, agent team khi Thomas khảo sát. Nhưng chúng chạy ẩn trong tiến trình cha, nên không phải chỗ đặt điều phối cả team.',
      en: 'Astragentic uses both: subagents inside a Builder session, agent teams when Thomas surveys. But they run hidden in the parent process, so they are not where a team’s coordination belongs.',
    },
  },
  {
    id: 'why-mattpocock',
    question: {
      vi: 'Phương pháp phát triển đến từ mattpocock-skills',
      en: 'The engineering method comes from mattpocock-skills',
    },
    answer: {
      vi: 'Phương pháp này hỏi cho hết ở đầu quy trình, nên quyết định được chốt trước khi viết code. Astragentic không viết lại phần đó, chỉ bọc điều phối quanh nó.',
      en: 'This method loops at the start of the process and settles decisions before code is written. Astragentic does not rewrite that part; it wraps coordination around it.',
    },
  },
  {
    id: 'why-cross-vendor',
    question: {
      vi: 'Review chéo: một AI của hãng khác đọc lại diff',
      en: 'Cross review: an AI from another vendor re-reads the diff',
    },
    answer: {
      vi: 'Một model đọc lại diff của chính nó thì đọc lại luôn giả định của nó. Vendor khác không mang giả định đó, và receipt buộc vào đúng SHA đã được đọc.',
      en: 'A model re-reading its own diff re-reads its own assumptions with it. A second vendor does not carry them, and the receipt is bound to the SHA that was actually read.',
    },
  },
];

/* ── /cau-truc ──────────────────────────────────────────────────────────── */

export interface Layer {
  id: string;
  title: Dict;
  line: Dict;
  /** What sits in this band of the `structure` diagram. Names, never translated. */
  parts: string;
}

export const LAYERS: Layer[] = [
  {
    id: 'runtime',
    title: { vi: 'Runtime', en: 'Runtime' },
    line: {
      vi: 'Cái thực sự chạy agent. Astragentic không sở hữu lớp này, nó chỉ không được khoá vào một hãng.',
      en: 'What actually runs an agent. Astragentic does not own this layer; it only refuses to be locked to one vendor.',
    },
    parts: 'Claude Code · Codex · OpenCode',
  },
  {
    id: 'harness',
    title: { vi: 'Harness', en: 'Harness' },
    line: {
      vi: 'Phần tôi viết: vai, skill, hook, và ledger giữ lại mọi lần hỏng đo được.',
      en: 'The part I wrote: the roles, the skills, the hooks, and the ledger that keeps every measured failure.',
    },
    parts: 'Roles: 5 · Skills: 16 · Hooks: 4 · Ledger',
  },
  {
    id: 'coordination',
    title: { vi: 'Điều phối', en: 'Coordination' },
    line: {
      vi: 'Chỗ trạng thái nằm ngoài đầu agent: board, pane, worktree. Ba thứ nhìn được bằng mắt.',
      en: 'Where state lives outside an agent’s head: the board, the panes, the worktrees. Three things you can look at.',
    },
    parts: 'Tracker · herdr panes · git worktrees',
  },
  {
    id: 'project',
    title: { vi: 'Project của bạn', en: 'Your project' },
    line: {
      vi: 'Repo thật. Harness không viết vào đây ngoài những file project tự khai.',
      en: 'The real repo. The harness writes nothing here beyond the files the project declares itself.',
    },
    parts: 'repo · CONTEXT.md · ADR',
  },
];

export interface GoodPart {
  id: string;
  title: Dict;
  line: Dict;
}

export const GOOD_PARTS: GoodPart[] = [
  {
    id: 'ledger',
    title: { vi: 'Ledger', en: 'The ledger' },
    line: {
      vi: 'Mỗi luật trong harness đến từ một lần hỏng đo được, và dòng ledger tương ứng vẫn đọc lại được.',
      en: 'Every rule in the harness came from a measured failure, and the ledger line is still there to read.',
    },
  },
  {
    id: 'cross-vendor-arm',
    title: { vi: 'Cánh tay cross-vendor', en: 'The cross-vendor arm' },
    line: {
      vi: 'Claude build, Codex đọc lại, receipt buộc vào đúng SHA đã đọc.',
      en: 'Claude builds, Codex re-reads, and the receipt is bound to the SHA that was read.',
    },
  },
  {
    id: 'tracker-substrate',
    title: { vi: 'Tracker là nền, không phải báo cáo', en: 'The tracker is substrate' },
    line: {
      vi: 'Trạng thái nằm trên board. Một session chết đi không mang theo thứ gì.',
      en: 'State lives on the board. A session can die without taking anything with it.',
    },
  },
  {
    id: 'claim-before-worktree',
    title: { vi: 'Claim trước worktree', en: 'Claim before worktree' },
    line: {
      vi: 'Assignee được ghi rồi đọc lại trước khi có branch, nên hai Builder không thể cùng nhận một ticket.',
      en: 'The assignee is written and read back before a branch exists, so two Builders cannot take one ticket.',
    },
  },
  {
    id: 'one-round-review',
    title: { vi: 'Review một vòng', en: 'One round of review' },
    line: {
      vi: 'Standards và Spec chạy đúng một lượt trên cả increment, rồi dừng. Không có vòng thứ hai để trốn vào.',
      en: 'Standards and Spec run exactly once over the whole increment, then stop. There is no second round to hide in.',
    },
  },
];


/* ── /tips ──────────────────────────────────────────────────────────────── */

/** The four techniques for running several agents on one machine. They are not peers:
 *  the first is the technique, the next two are what make it affordable, and the last
 *  is what it is for. The order carries that argument, so the rail reads in it too. */
export interface TipItem {
  id: string;
  /** The section head. A Dict, not a bare string: two of the four are tool names that
   *  are the same in both languages, and two are descriptions that are not. Typed as a
   *  name that never translates, the English page shipped a Vietnamese heading. */
  name: Dict;
  line: Dict;
  /** What the section contributes to the argument, printed above the heading. */
  role: Dict;
}

export const TIPS: TipItem[] = [
  {
    id: 'runtime-per-worktree',
    name: { vi: 'runtime theo worktree', en: 'runtime per worktree' },
    role: { vi: 'Kỹ thuật', en: 'The technique' },
    line: {
      vi: 'Mỗi worktree một stack riêng, và tên stack suy ra từ tên nhánh chứ không ai đặt.',
      en: 'One stack per worktree, its name derived from the branch rather than chosen by anyone.',
    },
  },
  {
    id: 'pnpm',
    name: { vi: 'pnpm', en: 'pnpm' },
    role: { vi: 'Điều kiện · disk', en: 'Condition · disk' },
    line: {
      vi: 'Một store, hardlink vào từng bản. N thư mục node_modules gần như một bản byte trên disk.',
      en: 'One store, hardlinked into each copy. N node_modules are almost one copy of bytes on disk.',
    },
  },
  {
    id: 'portless',
    name: { vi: 'portless', en: 'portless' },
    role: { vi: 'Điều kiện · cổng', en: 'Condition · ports' },
    line: {
      vi: 'Docker cấp cổng, portless gắn tên lên cổng đó. Không ai phải chọn số.',
      en: 'Docker assigns the port, portless puts a name on it. Nobody picks a number.',
    },
  },
  {
    id: 'browser-qa',
    name: { vi: 'QA walk', en: 'QA walk' },
    role: { vi: 'Lý do', en: 'The reason' },
    line: {
      vi: 'Một agent lái sản phẩm đang chạy như người dùng, và để lại file bằng chứng đọc lại được.',
      en: 'An agent drives the running product as a user, and leaves a readable evidence file.',
    },
  },
];
