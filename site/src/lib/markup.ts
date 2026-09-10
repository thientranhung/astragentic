// Tiny inline markup for owner-written strings: `**text**` becomes a highlighted span
// and a backtick span becomes inline code, because a file path or a flag inside a
// sentence is a literal string the reader will type (design system §Typography).
// Everything else is HTML-escaped, so YAML copy can never inject markup by accident.
// Product and tool names the owner wants readable at a glance: bold, ink, no colour.
// Longest first so "Claude Code" wins over "Claude". Applied outside code spans only.
const BRANDS = [
  'Claude Code', 'OpenCode', 'Codex', 'Claude', 'herdr', 'mattpocock-skills', 'Matt Pocock',
  'Superpowers',
  'GitHub Issues', 'GitHub', 'Jira', 'Linear', 'SendMessage', 'ListAgents', 'Monitor', 'Astragentic', 'Astraler',
];
const BRAND_RE = new RegExp(`(^|[^\\w-])(${BRANDS.map((b) => b.replace(/[-]/g, '\\-')).join('|')})(?![\\w-])`, 'g');

function boldBrands(html: string): string {
  // split on existing tags so we never touch text inside <code> or attributes
  const parts = html.split(/(<[^>]+>)/);
  let inCode = 0;
  return parts
    .map((part) => {
      if (part.startsWith('<')) {
        if (/^<code\b/.test(part)) inCode++;
        if (/^<\/code>/.test(part)) inCode--;
        return part;
      }
      if (inCode > 0) return part;
      return part.replace(BRAND_RE, '$1<strong class="brand">$2</strong>');
    })
    .join('');
}

export function hl(text: string): string {
  const esc = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  return boldBrands(
    esc
    .replace(/\*\*([^*\n]+)\*\*/g, '<strong class="hl">$1</strong>')
    .replace(/`([^`\n]+)`/g, '<code lang="en">$1</code>')
    .replace(/\n/g, '<br>')
  );
}
