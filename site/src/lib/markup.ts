// Tiny inline markup for owner-written strings: `**text**` becomes a highlighted span.
// Everything else is HTML-escaped, so YAML copy can never inject markup by accident.
export function hl(text: string): string {
  const esc = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  return esc.replace(/\*\*([^*\n]+)\*\*/g, '<strong class="hl">$1</strong>').replace(/\n/g, '<br>');
}
