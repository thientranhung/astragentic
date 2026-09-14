# Project-scoped skills

One skill is vendored here. It does not modify the machine-wide Codex or Claude skill
installations, and nothing in this directory is part of the harness payload — `install.sh`
stages `harness/`, never this.

| Skill | Role in this project | Source |
|---|---|---|
| `omnilogin-agent-browser` | OmniLogin profile lifecycle and browser capture | `omini-browser-research` local source |

## Routing

Logged-in browser capture uses `omnilogin-agent-browser`. OmniLogin owns the profile and
its skill hands interaction to the installed `agent-browser` CLI over CDP — **state in
OmniLogin, control in agent-browser**. The CDP port changes on every open; read it back
from the response rather than remembering the last one.

Content skills that used to be vendored here — brand, diagram and video authoring — were
removed. Where a session still needs one, it comes from the machine-wide installation
(`/hyperframes`, `/media-use`, and the rest), which is where `site/video/*/AGENTS.md`
already points.
