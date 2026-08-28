# 📖 User Guide — BMAD Roles (distilled)

This kit turns the **BMAD** method into a lightweight "virtual department" for software work. Each role is an AI specialist you can call into the conversation when a task needs deeper expertise. It is designed to be dropped into the documentation of a project and used as a practical playbook for better, more structured AI collaboration.

---

## 1. Why this is useful

This works especially well when you want an AI to behave less like a generic assistant and more like a specialist team.

- Put it inside the docs of a project so the agent can reference it as part of the project context.
- Use it when a prompt needs a role such as architect, PM, developer, tester, or UX designer.
- Use it to make outputs more accurate, more structured, and more aligned with real software delivery practices.
- Use it to spawn a small team of agents and let them play different roles in a discussion, review, or problem-solving session.

---

## 2. How I use it in practice

### A. Drop it into project docs

Add this folder to the documentation area of a project so the AI can see the roles and capabilities as part of the project’s context.

This is useful when the project already has:
- requirements
- architecture notes
- implementation plans
- technical constraints
- team conventions

The kit then acts like a reusable operating manual for the AI.

### B. Use it when a prompt needs a specialist role

Instead of asking a general question, ask the AI to play a specific role.

Example:
> "Play the role of Winston in the BMAD roster and design the architecture for this feature."

This tends to produce better answers because the AI is following a clear domain-specific workflow instead of answering in a vague, general way.

### C. Spawn a team of agents

For harder problems, you can bring multiple roles into the same conversation.

A common pattern is:
- Mary for analysis and discovery
- John for planning and requirements
- Winston for architecture
- Amelia for implementation
- Murat for testing and quality

That creates a more realistic collaboration flow where each role contributes its part of the solution.

---

## 3. Quick start

1. Open [roster.md](roster.md) and pick the role that matches the task.
2. Ask the AI to play that role and load the capability file you need.
3. For larger work, bring in multiple roles and let them collaborate.

Example template:
> "Play the role of Winston in distilled/roster.md, following distilled/capabilities/architecture.md. Design the architecture for: [project description]."

> 💡 For most sessions, load only 1–3 files (one role + one or two capabilities) to stay token-efficient.

---

## 4. Who's on the team?

| Role | Use it when you need | Key capabilities |
|---|---|---|
| 📊 **Mary** — Analyst | Research, brainstorming, idea validation | brainstorming, product-brief, market/domain/technical-research, prfaq, forge-idea |
| 📚 **Paige** — Tech Writer | Documentation, editing, project context | document-project, generate-project-context, editorial-review-* |
| 📋 **John** — PM | Requirements, PRD, story breakdown, readiness | prd, create-epics-and-stories, check-implementation-readiness |
| 🎨 **Sally** — UX | UX flows and experience design | ux |
| 🏗️ **Winston** — Architect | Architecture, system design, database decisions | architecture, spec |
| 💻 **Amelia** — Dev | Implementation, coding tasks, reviews | dev-story, quick-dev, code-review, create-story |
| 🧪 **Murat** — Test Architect | Test strategy, edge cases, CI, traceability | testarch-* |
| 🛠️ **Builder** | New agents, workflows, modules | builder-agent, workflow-builder, module-builder |

There are also shared capabilities that can be used across roles: advanced-elicitation, party-mode, review-adversarial-general, and review-edge-case-hunter.

---

## 5. Recommended usage patterns

### Single-role expert mode
Use one role when you want a focused specialist response.

### Team mode
Bring several roles together for planning, architecture, implementation, or review.

### Handoff mode
Have one role produce an artifact, then hand off to the next role for the next phase.

### Review mode
Ask a different role to challenge the solution, test assumptions, or improve quality.

---

## 6. Example prompts

**Explore an idea:**
> "Play Mary following capabilities/brainstorming.md and help me explore this idea."

**Write requirements:**
> "Play John following capabilities/prd.md and write a PRD for this feature."

**Design architecture:**
> "Play Winston following capabilities/architecture.md and design the architecture for this system."

**Implement a story:**
> "Play Amelia following capabilities/dev-story.md and implement this story."

**Run a roundtable discussion:**
> "Use capabilities/party-mode.md and have Winston, Amelia, and Murat debate this design decision."

---

## 7. Folder structure

```
distilled/
├── README.md           ← this file
├── roster.md           ← the roles and links to capabilities
└── capabilities/       ← self-contained capability files
```

Each capability file is a compact workflow guide for a specific role and task, so the AI can act with a clearer method rather than a generic answer.
