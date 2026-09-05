#!/usr/bin/env node
// Rebuilds site/src/data/*.json from the repo's own ledger, why.md, README.md and git log.
// No dependencies outside Node's stdlib. Never invents a value: missing source -> null + warning.
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(SITE_ROOT, '..');
const DATA_DIR = path.join(SITE_ROOT, 'src', 'data');
const GITHUB_BLOB_BASE = 'https://github.com/thientranhung/astragentic/blob/main/';

const warnings = [];
function warn(msg) {
  warnings.push(msg);
  console.warn(`[build-data] WARNING: ${msg}`);
}

function readRepoFile(relPath) {
  const abs = path.join(REPO_ROOT, relPath);
  if (!existsSync(abs)) {
    warn(`missing source file: ${relPath}`);
    return null;
  }
  return readFileSync(abs, 'utf8');
}

// ---------------------------------------------------------------------------
// ledger.json
// ---------------------------------------------------------------------------

const INDEX_PATH = 'harness/.agents/memory/INDEX.md';
const LEDGER_PATH = 'harness/.agents/memory/recurring-failure-modes.md';
const SKILLS_CONTENT_DIR = path.join(SITE_ROOT, 'src', 'content', 'skills');

function listSkillNames() {
  if (!existsSync(SKILLS_CONTENT_DIR)) return new Set();
  return new Set(
    readdirSync(SKILLS_CONTENT_DIR)
      .filter((f) => f.endsWith('.md') && !f.startsWith('_'))
      .map((f) => f.replace(/\.md$/, ''))
  );
}

function findHarnessPath(name) {
  // Search harness/ for a file or directory with this exact basename.
  try {
    const out = execSync(
      `find harness -name ${JSON.stringify(name)}`,
      { cwd: REPO_ROOT, encoding: 'utf8' }
    ).trim();
    if (!out) return null;
    // Several runtimes carry a copy of the same role file; prefer the canonical one.
    const priority = ['harness/.claude/agents/', 'harness/.agents/', 'harness/.claude/'];
    const rank = (p) => {
      const i = priority.findIndex((pre) => p.startsWith(pre));
      return i === -1 ? priority.length : i;
    };
    return out.split('\n').sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))[0];
  } catch {
    return null;
  }
}

function buildRefs(citedBy, skillNames) {
  return citedBy.map((name) => {
    if (skillNames.has(name)) {
      return { name, kind: 'skill', href: `/skills/${name}` };
    }
    const found = findHarnessPath(name);
    if (found) {
      return { name, kind: 'file', href: GITHUB_BLOB_BASE + found };
    }
    warn(`ledger citedBy "${name}" resolved to no skill page and no harness file — href null`);
    return { name, kind: 'file', href: null };
  });
}

function parseIndex(indexText) {
  const lines = indexText.split('\n');
  const rows = [];
  lines.forEach((line, i) => {
    const m = line.match(/^\|\s*`(AST-\d+)`\s*\|\s*(.*?)\s*\|\s*(\S+)\s*\|\s*(\d+)\s*\|\s*(.*?)\s*\|\s*$/);
    if (!m) return;
    const [, id, lesson, status, words, citedByRaw] = m;
    const citedBy = citedByRaw
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    rows.push({ id, lesson, status, words: Number(words), citedBy, indexLine: i + 1 });
  });
  return rows;
}

function parseLedgerEntries(ledgerText) {
  const lines = ledgerText.split('\n');
  const headingRe = /^### (AST-\d+) — (.*)$/;
  const headings = [];
  lines.forEach((line, i) => {
    const m = line.match(headingRe);
    if (m) headings.push({ id: m[1], titleLine: m[2], lineNo: i + 1 });
  });

  const entries = new Map();
  headings.forEach((h, idx) => {
    const start = h.lineNo - 1; // 0-indexed
    const end = idx + 1 < headings.length ? headings[idx + 1].lineNo - 1 : lines.length;
    let entry = lines.slice(start, end).join('\n').trim();
    if (entry.length > 1200) {
      // cut at the last sentence end before the cap, never mid-word or inside **bold**
      const cut = entry.slice(0, 1200);
      const stop = Math.max(cut.lastIndexOf('. '), cut.lastIndexOf('.\n'));
      entry = (stop > 400 ? cut.slice(0, stop + 1) : cut.replace(/\s+\S*$/, '')) + ' …';
    }
    const dateMatch = h.titleLine.match(/promoted (\d{4}-\d{2}-\d{2})/);
    entries.set(h.id, {
      entry,
      entryLine: h.lineNo,
      promotedOn: dateMatch ? dateMatch[1] : null,
    });
  });
  return entries;
}

function buildLedger(ledgerCommitIndex) {
  const indexText = readRepoFile(INDEX_PATH);
  const ledgerText = readRepoFile(LEDGER_PATH);
  if (!indexText || !ledgerText) return [];

  const skillNames = listSkillNames();
  const rows = parseIndex(indexText);
  const entries = parseLedgerEntries(ledgerText);

  return rows.map((row) => {
    const found = entries.get(row.id);
    if (!found) {
      warn(`ledger entry ${row.id} named in INDEX.md but not found in recurring-failure-modes.md`);
    }
    return {
      id: row.id,
      lesson: row.lesson,
      status: row.status,
      words: row.words,
      citedBy: row.citedBy,
      indexLine: row.indexLine,
      entryLine: found ? found.entryLine : null,
      promotedOn: found ? found.promotedOn : null,
      entry: found ? found.entry : null,
      refs: buildRefs(row.citedBy, skillNames),
      commits: ledgerCommitIndex.get(row.id) || [],
    };
  });
}

// ---------------------------------------------------------------------------
// failures.json
// ---------------------------------------------------------------------------

// Stage mapping is fixed by content/site/07-rebuild-spec.md §3, màn 2 (Hình dạng):
// claim AST-131; build AST-097, AST-092; arm AST-015; merge AST-074, AST-056.
const STAGE_BY_AST = {
  'AST-131': 'claim',
  'AST-097': 'build',
  'AST-092': 'build',
  'AST-015': 'arm',
  'AST-074': 'merge',
  'AST-056': 'merge',
};

function buildFailures() {
  const whyText = readRepoFile('content/site/pages/why.md');
  if (!whyText) return [];

  const sectionMatch = whyText.match(/## 3\. Defect cards[\s\S]*?(?=\n## 4\.)/);
  if (!sectionMatch) {
    warn('why.md: could not find "## 3. Defect cards" section');
    return [];
  }
  const section = sectionMatch[0];

  const cardRe = /\*Cost:\*\s*([\s\S]*?)\n`(AST-\d+)`/g;
  const failures = [];
  let m;
  while ((m = cardRe.exec(section))) {
    const costLine = m[1].replace(/\s+/g, ' ').trim();
    const id = m[2];
    const stage = STAGE_BY_AST[id];
    if (!stage) warn(`why.md defect card ${id} has no stage mapping`);
    failures.push({ id, stage: stage || null, costLine });
  }
  if (failures.length !== 6) {
    warn(`why.md: expected 6 defect cards, found ${failures.length}`);
  }
  return failures;
}

// ---------------------------------------------------------------------------
// adopt.json
// ---------------------------------------------------------------------------

function buildAdopt() {
  const readme = readRepoFile('README.md');
  if (!readme) return { prerequisites: [], commands: [] };

  // Prerequisites: a blockquote line starting "> **Prerequisites:**" that may wrap
  // across several "> " continuation lines until a blank line.
  const preBlockMatch = readme.match(/^> \*\*Prerequisites:\*\*[\s\S]*?(?=\n\n)/m);
  let prerequisites = [];
  if (!preBlockMatch) {
    warn('README.md: could not find Prerequisites blockquote');
  } else {
    const raw = preBlockMatch[0]
      .split('\n')
      .map((l) => l.replace(/^>\s?/, ''))
      .join(' ')
      .replace(/\*\*Prerequisites:\*\*/, '')
      .trim();
    const items = raw.split(',').map((s) => s.trim()).filter(Boolean);
    prerequisites = items.map((item) => {
      const linkMatch = item.match(/^\[([^\]]+)\]\(([^)]+)\)(.*)$/);
      let name;
      let href = null;
      let rest = item;
      if (linkMatch) {
        name = linkMatch[1];
        href = linkMatch[2];
        rest = linkMatch[3].trim();
      } else {
        name = item;
        rest = '';
      }
      const versionMatch = (linkMatch ? rest : item).match(/(>=?\s*[\d.]+.*)$/);
      let version = null;
      if (versionMatch) {
        version = versionMatch[1].trim();
      }
      if (!linkMatch) {
        // e.g. "Git (with worktree support)" — no version token, no link.
        name = item.replace(/\(>=?\s*[\d.]+.*\)/, '').trim();
      } else if (rest) {
        // e.g. "plugin >= 1.2.3" trailing the link -> fold into name minus version.
        const nameSuffix = rest.replace(/>=?\s*[\d.]+.*$/, '').trim();
        if (nameSuffix) name = `${name} ${nameSuffix}`.trim();
      }
      if (items.length !== 4) {
        // handled after loop via warning below
      }
      return { name, version, href };
    });
    if (prerequisites.length !== 4) {
      warn(`README.md: expected 4 prerequisites, found ${prerequisites.length}`);
    }
  }

  // Quickstart: fenced ```bash block with four "# N." numbered steps.
  const qsMatch = readme.match(/## Quickstart\s*\n+```bash\n([\s\S]*?)```/);
  let commands = [];
  if (!qsMatch) {
    warn('README.md: could not find Quickstart bash block');
  } else {
    const body = qsMatch[1].replace(/\n$/, '');
    const lines = body.split('\n');
    const steps = [];
    let current = null;
    for (const line of lines) {
      if (/^#\s*\d+\./.test(line.trim())) {
        current = [];
        steps.push(current);
      } else if (line.trim() !== '') {
        if (!current) {
          current = [];
          steps.push(current);
        }
        current.push(line);
      }
    }
    commands = steps.map((stepLines) => stepLines.join('\n'));
    if (commands.length !== 4) {
      warn(`README.md: expected 4 quickstart commands, found ${commands.length}`);
    }
  }

  return { prerequisites, commands };
}

// ---------------------------------------------------------------------------
// commits.json + per-entry ledger commits (spec §7)
// ---------------------------------------------------------------------------

// Reads the FULL git history once and returns every commit whose body carries
// a `Ledger:` trailer, newest first, with the trailer text parsed out.
function readAllLedgerCommits() {
  let raw;
  try {
    raw = execSync(
      "git log --format='%H%x1f%ad%x1f%s%x1f%b%x1e' --date=short",
      { cwd: REPO_ROOT, encoding: 'utf8', maxBuffer: 1024 * 1024 * 64 }
    );
  } catch (e) {
    warn(`git log failed: ${e.message}`);
    return [];
  }

  const records = raw.split('\x1e').map((r) => r.replace(/^\n/, '')).filter((r) => r.trim() !== '');
  const out = [];
  for (const rec of records) {
    const [sha, date, subject, body = ''] = rec.split('\x1f');
    const ledgerMatch = body.match(/^Ledger:.*(?:\n(?!\s*$)(?!Co-Authored-By)(?!Claude-Session)[^\n]*)*/m);
    if (!ledgerMatch) continue;
    const ledger = ledgerMatch[0].replace(/\s+/g, ' ').trim();
    out.push({ sha, date, subject, ledger });
  }
  return out;
}

function buildCommits(allLedgerCommits) {
  return allLedgerCommits.slice(0, 20).map(({ sha, date, subject, ledger }) => ({
    sha,
    date,
    subject,
    ledger,
  }));
}

// Maps each AST id to every commit whose `Ledger:` trailer names it, e.g.
// "Ledger: AST-134, AST-135" -> both AST-134 and AST-135 get this commit.
function buildLedgerCommitIndex(allLedgerCommits) {
  const index = new Map();
  for (const { sha, date, subject, ledger } of allLedgerCommits) {
    const ids = ledger.match(/AST-\d+/g);
    if (!ids) continue;
    for (const id of new Set(ids)) {
      if (!index.has(id)) index.set(id, []);
      index.get(id).push({ sha, date, subject });
    }
  }
  return index;
}

// ---------------------------------------------------------------------------
// meta.json
// ---------------------------------------------------------------------------

// Concatenates every skill content page so "does AST-xxx appear on a skill
// page" is a plain substring search, independent of which name cited it.
function readAllSkillPagesText() {
  if (!existsSync(SKILLS_CONTENT_DIR)) return '';
  return readdirSync(SKILLS_CONTENT_DIR)
    .filter((f) => f.endsWith('.md'))
    .map((f) => readFileSync(path.join(SKILLS_CONTENT_DIR, f), 'utf8'))
    .join('\n');
}

function buildMeta(ledger) {
  const readme = readRepoFile('README.md');
  let version = null;
  if (readme) {
    const vMatch = readme.match(/badge\/version-([\d.]+)-/);
    if (vMatch) version = vMatch[1];
    else warn('README.md: could not find version badge');
  }
  const total = ledger.length;
  const cited = ledger.filter((e) => e.citedBy.length > 0).length;
  const orphan = total - cited;

  // closedChains (spec §7): an id closes all four beats when it has a ref with
  // a live href, its id-string appears on a skill page, AND at least one
  // commit carries it in a `Ledger:` trailer.
  const skillPagesText = readAllSkillPagesText();
  const closedChains = ledger.filter((e) => {
    const hasHrefRef = e.refs.some((r) => r.href !== null);
    const onSkillPage = skillPagesText.includes(e.id);
    const hasCommit = e.commits.length > 0;
    return hasHrefRef && onSkillPage && hasCommit;
  }).length;

  return {
    total,
    cited,
    orphan,
    closedChains,
    generatedAt: new Date().toISOString(),
    version,
  };
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

function writeJson(name, data) {
  const outPath = path.join(DATA_DIR, name);
  writeFileSync(outPath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`[build-data] wrote ${path.relative(REPO_ROOT, outPath)}`);
}

const allLedgerCommits = readAllLedgerCommits();
const ledgerCommitIndex = buildLedgerCommitIndex(allLedgerCommits);

const ledger = buildLedger(ledgerCommitIndex);
const failures = buildFailures();
const adopt = buildAdopt();
const commits = buildCommits(allLedgerCommits);
const meta = buildMeta(ledger);

writeJson('ledger.json', ledger);
writeJson('failures.json', failures);
writeJson('adopt.json', adopt);
writeJson('commits.json', commits);
writeJson('meta.json', meta);

if (warnings.length > 0) {
  console.warn(`[build-data] finished with ${warnings.length} warning(s).`);
} else {
  console.log('[build-data] finished clean.');
}
