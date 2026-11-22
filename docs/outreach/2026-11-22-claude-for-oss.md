# Claude for Open Source — application 2026-11-22

- **Form:** https://claude.com/contact-sales/claude-for-oss (6 months of Claude Ultra; thresholds not met, applied under "Don't quite fit?")
- **Sent:** 2026-11-22, by browser-skill in the owner's Chrome, on his word ("xong em bấm gửi đi nha")
- **Account email:** the owner's personal Claude account (as given by him)
- **GitHub:** verified @thientranhung, repository thientranhung/astragentic
- **Result page:** "Thank you for applying to the Claude for Open Source program. If approved, you'll get a link to activate Claude Max on your account for the subscription period."
- **Status:** pending. If refused, the owner wants to apply again: update the numbers below and resend.

## Owner's rulings on the wording

- Lead with value and seriousness, not with "we do not qualify". 4 stars = no marketing yet.
- Never name the company or its projects (confidential). Say "real projects I cannot name".
- Free for the community: no paid tier, no subscription. Passion; his future way of practising the craft.
- With Ultra: apply and test on many more projects than today's one or two, because the failures that matter only show up on real projects.

## Numbers used (measured 2026-11-22)

| số đo | nguồn |
|---|---|
| 654 commits, 255 `v*` tags, first commit 2026-08-10 (105 days) | `git rev-list --count HEAD`, `git ls-remote --tags origin 'v*'` |
| commits on 66 distinct days, in all 24 hours of the day | `git log --format=%ad` |
| 67 failure modes recorded | `harness/.agents/memory/recurring-failure-modes.md` |
| 4 stars | `gh repo view` |
| v6.1.20 current | `VERSION` |

## Text sent

### Reach and impact
Astragentic is an open-source (Apache-2.0) framework that lets one engineer run a whole team of Claude agents the way a client works with a disciplined outsourcing company. The engineer sits in the client's seat and talks to one representative agent; the team runs the full project lifecycle in six roles: a BA clarifies the problem from the user's seat, a Shaper writes the spec and cuts tickets, a Builder builds each ticket in its own git worktree (test-first, a three-lens review, then a second vendor reads it), QA uses the running product like a real user, a Quick Builder handles small owner changes, and the representative merges only when every gate has left a receipt.

I use Astragentic every day on real projects (confidential, so I cannot name them) and share it free with the community: no paid tier, no subscription. Every defect a real project hits is measured, fixed in the harness and released again, so each version carries lessons from real collisions.

How seriously it is built, in numbers: 654 commits and 255 version tags in 105 days, commits on 66 different days and in all 24 hours of the day (the agents run around the clock), 67 multi-agent failure modes recorded and turned into rules, and every review change measured blind before it ships.

It is built on the whole Anthropic platform, not prompts alone: a custom agent per role, hooks on six Claude Code events, a Claude Code mod that dispatches panes and wakes the representative, four review subagents, the built-in code-review and simplify, the advisor, and cross-session messaging. It runs on the Herdr and Orca terminal hosts, with Claude Code as the reference runtime.

Why only 4 stars: all my time has gone into making it work on real projects, and I have not invested in marketing yet. The GitHub history shows the pace: it is updated continuously.

### How the subscription will be used
Astragentic is how I practise software engineering from now on, and I am passionate about it.

Today it runs on one or two projects, because my usage covers a full agent team for about that many. With Claude Ultra I will:

1. Apply and test it on many more projects. The failures that matter most in a multi-agent system cannot be predicted; they only appear when a real project is deployed. The more real projects it meets, the more of those failures get found and fixed.
2. Run the full lifecycle in live sessions for every release (Thomas, Builders and QA as parallel Opus sessions), instead of checking parts of it against stubs.
3. Publish what I measure. Every defect found and its fix goes into the public RELEASE-NOTES, with numbers, so everyone building on Claude Code benefits.

### Other info
Website: https://astragentic.thisistool.com/ . Release notes, where every change carries its measurement and source: https://github.com/thientranhung/astragentic/blob/main/RELEASE-NOTES.md . Thank you for considering it.
