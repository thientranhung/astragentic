"""Field-declaration parser for marker commit bodies.

Imported by `check-simplify-markers.sh` from its own `lib/` directory. It answers one question:
which physical lines of a marker commit body are a declared field, and which are prose that
merely starts with, or contains, a field-shaped word.

Why it is a module and not inline: a marker body routinely holds prose, and prose wraps. A
paragraph that wraps so the word `Output:` lands at the start of a line must not be read as a
second `Output:` declaration. Measured downstream: three Builders were refused on exactly that,
for a marker whose real field was fine.

CONTRACT. A line is in the field region only if it is itself token-prefixed (unindented, starts
with a known field token) AND every earlier line of its own paragraph — the run of non-blank
lines since the last blank line — was too. The first line of a paragraph that carries no token
ends field recognition for the rest of that paragraph. A prose paragraph never contributes
anything, wherever in the body it sits.

It is per paragraph, not "one field block at the top", because both shapes occur in real
markers: a `Pass:` paragraph at the very END of the body after free prose, a leading
`Supersedes:` paragraph, a packed `Range:`/`Reviewed:`/`Vendor:` paragraph, one `Output:` line
per pass. "Accept only the first occurrence of a field" fails the same data: the second of two
legitimate consecutive `Output:` lines would be demoted to prose and never validated.

RESIDUAL. A genuine second field line is indistinguishable from an accidental wrap that lands
on the very next physical line after a real field line, with no prose between. No measured
marker does that; the rule matches the corpus it was built from, it is not a proof.
"""
import re


def build_field_line_re(field_tokens):
    """Compile the "line STARTS with a recognised token" regex. Longest-first in the
    alternation, so a token is never shadowed by a shorter one that is its prefix."""
    return re.compile(
        "^(?:" + "|".join(re.escape(t) for t in sorted(field_tokens, key=len, reverse=True)) + ")"
    )


def field_line_flags(body, field_line_re):
    """(lines, flags): `flags[i]` is True where `lines[i]` is structurally a field declaration.

    Callers that must tell WHICH line a declaration is on use this, not `field_region`: two
    lines with identical text at different positions are different declarations, and a
    text-membership test against the region silently skipped a duplicated `Supersedes:` line
    whose text also appeared once, legitimately, inside the region."""
    lines = body.split("\n")
    flags = []
    at_paragraph_start = True
    active = False
    for line in lines:
        if line.strip() == "":
            flags.append(True)  # a blank separator stays in the region text; harmless either way
            at_paragraph_start = True
            active = False
            continue
        if at_paragraph_start:
            active = bool(field_line_re.match(line))
            at_paragraph_start = False
        elif active:
            active = bool(field_line_re.match(line))
        flags.append(active)
    return lines, flags


def field_region(body, field_line_re):
    """Every line of `body` that is structurally a field declaration, rejoined. Every field
    lookup should read THIS, never the raw body."""
    lines, flags = field_line_flags(body, field_line_re)
    return "\n".join(l for l, f in zip(lines, flags) if f)
