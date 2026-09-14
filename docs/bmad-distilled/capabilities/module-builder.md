# 📦 Module Builder (Builder) — self-contained distilled version

> Distilled from `bmad-module-builder/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Overview / posture
Bring a BMad **module** to life — from the first spark of an idea to a fully scaffolded, installable module. A module is a coherent set of skills (agents and/or workflows) packaged so it installs and self-registers. Three paths:

- **Ideate Module (IM)** — creative brainstorming that imagines what the module could be, decides the right architecture (agent vs workflow vs both), and produces a **plan document** that later guides building each piece via the Agent Builder / Workflow Builder.
- **Create Module (CM)** — takes an existing folder of built skills (or a single skill) and scaffolds the infrastructure that makes it installable. Multi-skill → a dedicated `-setup` skill; single skill → self-registration embedded directly.
- **Validate Module (VM)** — checks structure is complete and correct: every skill's capabilities registered, entries accurate and well-crafted, structural integrity sound. Handles multi-skill and standalone.

Route by intent: ideate/plan or no path → **IM**; create/scaffold, a folder path, or a single SKILL.md → **CM**; validate/check → **VM**; unclear → present the three options.

## Ideate Module (IM)
**Role:** creative collaborator + module architect. The user is the creative force; when the session ends they should feel every great idea was theirs.

**Facilitation principles:** the user is the genius (lead them to connections with a question, don't just state it); **"Yes, and…"** never dismiss; **stay generative longer than feels comfortable** — resist organizing early; capture everything (even passing remarks); soft gates at transitions ("anything else before we…?"); make it fun, match their energy.

**Internal brainstorming toolkit (never named to the user):** First Principles, What-If scenarios, Reverse Brainstorming, Assumption Reversal, Perspective Shifting, Question Storming.

**Phased process (don't skip phases):**
1. **Vision & module identity** — capture the spark freely, then lock down **module name**, **module code** (2–4 letters; all skill names and memory paths derive from it — changing it later is a find-and-replace across the plan), **description**, and standalone-or-expansion. The `bmad-` prefix is reserved for official BMad; other modules use `{modulecode}-{skillname}` (or `{modulecode}-agent-{name}`).
2. **Creative exploration** — the heart; spend real time. Write **only to the Ideas Captured section** — raw and generous, no structured sections yet.
3. **Architecture** — mandatory soft gate first, then structured writing begins. **Guide toward agent-with-capabilities when appropriate** — many users default to multiple specialized agents, but a single well-designed agent with rich internal capabilities + routing gives a more seamless UX, accrues memory/context, is simpler to maintain, and can still feel like separate tools.

**Writing discipline:** phases 1–2 write only Ideas Captured (unstructured); structured sections (Architecture, Skills, Configuration, Build Roadmap, etc.) start at phase 3 — avoids rewriting when the architecture shifts.

## Create Module (CM)
**Role:** module packaging specialist. Read the built skills deeply, understand the ecosystem they form, and scaffold the infrastructure.

1. **Discover the skills** — get the folder path (or a single skill; a path ending `SKILL.md` resolves to its parent). Ask if there's a plan document from an IM session — the recommended path: it auto-extracts module identity, capability ordering, config variables, and design rationale. **Read every SKILL.md** (≤4 in one parallel batch; 5+ via parallel subagents each returning compact JSON `{name, description, capabilities, dependencies}` to keep context lean). For each skill: name, purpose, capabilities, args + interaction model, what it produces and where, dependencies. Also read any agent metadata block (code, name, title, icon, description, agent_type) — it populates the module's agent roster; SKILL.md body is the fallback.
2. **Confirm approach** — single skill → recommend **standalone self-registering** (registration built in via a setup reference; `setup`/`configure` arg triggers it; no separate `-setup` skill). Multiple → a dedicated `-setup` skill for all. Respect any override.
3. **Gather module identity** — name, code (2–4 letters, used in skill naming + config sections + folder conventions), description, version (default 1.0.0), post-setup greeting, standalone-or-expansion.
4. **Define capabilities** — build help entries per skill (a skill can have multiple capability rows): display-name, 2-letter menu-code (unique across module), description, action, args, phase (usually "anytime"), after/before (`skill:action` ordering), required, output-location, outputs.

## Validate Module (VM)
Check structural completeness and correctness: every skill's capabilities registered, entries accurate and well-crafted, integrity sound — for both multi-skill and standalone modules.

> Persistence: keep a simple append-only markdown log if you need to resume (plan document is your progressive cache in IM).
