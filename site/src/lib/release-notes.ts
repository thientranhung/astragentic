import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export interface ReleaseEntry {
  version: string;
  date: string | null;
  summary: string;
}

// RELEASE-NOTES.md format (checked 2026-09-04): each release starts with a
// top-level heading `# Astragentic <version>`, followed by a prose paragraph
// (the summary) before the first `## ` subsection. The file carries no date
// per release, so the date is recovered from the git commit that introduced
// that exact heading line (`git log -S"<heading>"`), which matches the repo's
// actual release cadence rather than a value we would otherwise have to invent.
export function getRecentReleases(count: number): ReleaseEntry[] {
  const candidates: string[] = [];
  try {
    const siteRoot = path.dirname(path.dirname(path.dirname(fileURLToPath(import.meta.url))));
    candidates.push(path.join(path.dirname(siteRoot), 'RELEASE-NOTES.md'));
    candidates.push(path.join(siteRoot, '..', 'RELEASE-NOTES.md'));
  } catch {
    /* import.meta.url may not be a file URL under some dev transforms */
  }
  candidates.push(path.resolve(process.cwd(), '..', 'RELEASE-NOTES.md'));
  candidates.push(path.resolve(process.cwd(), 'RELEASE-NOTES.md'));

  let text: string | null = null;
  let repoRoot = process.cwd();
  for (const candidate of candidates) {
    try {
      text = readFileSync(candidate, 'utf-8');
      repoRoot = path.dirname(candidate);
      break;
    } catch {
      /* try next */
    }
  }
  if (text === null) return [];

  const lines = text.split('\n');
  const headingIndices: number[] = [];
  lines.forEach((line, i) => {
    if (/^# Astragentic /.test(line)) headingIndices.push(i);
  });

  const entries: ReleaseEntry[] = [];
  for (let h = 0; h < Math.min(count, headingIndices.length); h++) {
    const idx = headingIndices[h];
    const heading = lines[idx].trim();
    const version = heading.replace(/^# Astragentic /, '').trim();

    let summary = '';
    for (let j = idx + 1; j < lines.length; j++) {
      const line = lines[j];
      if (/^#{1,2} /.test(line)) break;
      if (line.trim()) {
        summary += (summary ? ' ' : '') + line.trim();
      } else if (summary) {
        break;
      }
    }
    const firstSentence = summary.match(/(.+?\.)(\s|$)/);
    summary = firstSentence ? firstSentence[1] : summary;

    let date: string | null = null;
    try {
      date = execFileSync(
        'git',
        ['log', '-1', '--format=%ad', '--date=short', '-S' + heading, '--', 'RELEASE-NOTES.md'],
        { cwd: repoRoot, encoding: 'utf-8' },
      ).trim() || null;
    } catch {
      date = null;
    }

    entries.push({ version, date, summary });
  }

  return entries;
}
