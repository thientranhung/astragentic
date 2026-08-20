# Media plan

## Principle

Use images and clips as evidence. A visual earns its place when it proves a claim faster than
prose; decorative art is reserved for the hero and major chapter transitions.

Target mix:

- 70% real evidence: tracker, Herdr, worktrees, diffs, gate files and running-product walks.
- 20% explanatory diagrams: lifecycle, project-management flow, roles and technology layers.
- 10% conceptual imagery: hero and section dividers.

## Priority assets

| Priority | Asset | Claim it proves | Format |
|---|---|---|---|
| P0 | Feature → analysis → tasks → frontier → dispatch | Multi-agent work begins with project management | Diagram + 20–30s clip |
| P0 | Two Builders in separate panes/worktrees | Parallel work is visible and isolated | 8–12s clip |
| P0 | Tracker dependency graph and claim | Assignment and ordering are durable state | 8–12s clip |
| P0 | Gate report bound to a SHA | Review is an artifact, not a status message | Screenshot + 8s clip |
| P1 | Vibe Coding vs Vibe Engineering | The article's central distinction | Diagram |
| P1 | Five-role operating model | Each session boundary has an owner | Diagram |
| P1 | Technology stack by responsibility | Tools are selected for system roles | Layered diagram |
| P2 | Engineering cockpit hero | Emotional identity of the story | Generated image |

## Capture rules

- One clip proves one claim.
- Default duration is 6–15 seconds; the project-management sequence may run 20–30 seconds.
- Capture the real workflow first, then write captions around what actually happened.
- Keep ticket IDs, pane labels and relevant state readable.
- Redact secrets and personal data before capture bytes are written.
- Prefer a static camera and intentional cursor movement; avoid decorative zooms.
- Provide text captions because clips may autoplay muted.

## Browser routing

Use the project-scoped `omnilogin-agent-browser` skill for logged-in browser capture. OmniLogin
owns the browser profile, cookies and CDP lifecycle. The skill hands navigation to the installed
`agent-browser` CLI over the verified CDP port; do not create a separate browser profile.

## Video routing

Raw screen capture does not require HyperFrames. Invoke `hyperframes` and `media-use` when the
work changes from capture to composition: trimming, reframing, captions, transitions, audio,
color treatment or a multi-scene walkthrough.

