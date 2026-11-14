# After 6.1.14 (batch for 6.1.15): three rules taken from upstream skills, one cut not made

Owner 2026-11-14, upstream pane, after reading the BMAD and Matt Pocock leads: "làm đi rồi release version
mới". No field incident of ours stands behind these rules; the numbers below say how often the skills run
and what was not measured.

| số đo | nguồn |
|---|---|
| `astra-grill-with-docs` briefs since 2026-10-29: nizzy 6, inception 12; `astra-to-spec`: 12 Skill calls and 12 briefs across both | downstream transcripts, Skill tool calls and brief first lines |
| lines in `astra-grill-with-docs` or `astra-to-spec` that keep an inference from being written as the owner's: 0 (`ba.md` line 50 has one) | payload at v6.1.14 |
| Matt Pocock #1424 (open, 2026-11-12): since "word each question so yes accepts", grilling rounds drift to yes-only questions; our grill skill carries that sentence | upstream issue; `astra-grill-with-docs/SKILL.md` |
| BMAD `bmad-facilitate` (main, 2026-11-08): "a yes to a group accepts nothing", unconfirmed inference logged as an assumption, "name the three decisions you are least confident about" | upstream `skills/core-tools/bmad-facilitate/SKILL.md` |
| specs or grill rounds of ours where an inference was written as the owner's, or a round was answered with one yes | chưa đo; 1 round found in the `❓ Q` format, answered by Thomas in 2,086 characters |
| `RELEASE-NOTES.md`: 607,066 characters, 204 version headings; downstream reads of it in 30 days: 1 Read with a limit (11,917 characters) and 4 shell extracts (largest 9,736); whole-file reads 0 | downstream transcripts since 2026-10-15 |

Changed (skill text, both mirrors; Codex where it carries the rule):

- `astra-grill-with-docs`: a decision between real alternatives names them beside the recommendation; a
  yes to the whole round settles nothing, each question is settled by its own answer.
- `astra-to-spec`: nothing is written as the owner's that was not said or accepted in Align, an inference
  goes under Open questions as an assumption; the hand-back names the three decisions the Shaper is least
  sure of. `codex-astra-to-spec` gains the hand-back clause; it already forbids filling a choice from
  assumption, and the Codex grill skill has no yes-accepts sentence to balance.
- `prompts/ADAPT-HARNESS.md`: the stale size of the release notes (34k words, 111 headings) corrected.

Not done, on the number: `RELEASE-NOTES.md` is not split or indexed. No agent read it whole in 30 days;
the prompt already hands out the one-section extract.

Not taken from `bmad-facilitate`: its fresh-reader review (the spec arm already reads the spec cold), its
templates, memlog and customization layer. `bmad-ingest`, `bmad-shard-pro`, the rebuilt advanced
elicitation and the Founder module: nothing taken.
