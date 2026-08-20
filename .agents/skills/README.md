# Project-scoped content skills

These skills are vendored for the Astragentic storytelling project only. They do not modify
the machine-wide Codex or Claude skill installations.

| Skill | Role in this project | Source |
|---|---|---|
| `brand` | Message architecture, voice and content consistency | `ui-ux-pro-max-skill` local installation |
| `excalidraw-diagram-generator` | Workflow, role and technology diagrams | Codex local installation |
| `omnilogin-agent-browser` | OmniLogin profile lifecycle and browser capture | `omini-browser-research` local source |
| `hyperframes` | Entry point for edited video and motion work | Agent skills local installation |
| `hyperframes-core` | Renderable composition contract | Agent skills local installation |
| `hyperframes-creative` | Art direction and scene design | Agent skills local installation |
| `hyperframes-animation` | Motion patterns and transitions | Agent skills local installation |
| `hyperframes-keyframes` | Seek-safe keyframes and timelines | Agent skills local installation |
| `hyperframes-cli` | HyperFrames production loop | Agent skills local installation |
| `hyperframes-registry` | Reusable HyperFrames blocks | Agent skills local installation |
| `media-use` | Capture processing, media, captions and audio | Agent skills local installation |

The system-provided `imagegen` skill remains a runtime dependency rather than a vendored copy.

## Routing

- Writing, positioning, headline or narrative work starts with `brand`.
- Architecture and process diagrams use `excalidraw-diagram-generator`.
- Logged-in browser capture uses `omnilogin-agent-browser`; OmniLogin owns the profile and
  its skill hands interaction to the installed `agent-browser` CLI over CDP.
- Creating or editing a composed video starts with `hyperframes`, which routes to the other
  HyperFrames and media skills.
- Generating a new conceptual raster image uses the system `imagegen` skill.

