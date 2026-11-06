---
name: codex-simplify
description: "Simplify a completed Astragentic increment after review without changing its behavior or expanding scope."
---

# Simplify the finished increment

Pin the brief's base and current head/tree. Read the actual increment and review
findings. Look for duplicate logic, unnecessary indirection, speculative abstraction,
confusing names and avoidable state. Respect project conventions; do not redesign
unrelated code or add dependencies to make a small change elegant.

Make only supported, behavior-preserving improvements inside the authorized write-set.
A no-change pass is a valid outcome. Run the checks affected by edits and preserve
review validity for the final tree; changes not covered by review require renewed
coverage of those changes. Save what was inspected, what changed and why, command
results and final artifact identity. Never mint a success receipt just for loading
this skill. Do not manufacture an empty commit when commits are not authorized.
