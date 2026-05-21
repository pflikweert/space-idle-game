---
name: scope-guard
description: Keep prototype tasks small, cheap, and inside the agreed game scope.
---

# Use when
Use for any task that risks growing beyond the current prototype slice.

# Checklist
1. Treat project docs as the source of scope truth.
2. Prefer the smallest working change.
3. Keep work inside the active prototype goal.
4. Do not add backend, accounts, monetization, store work, or AI integrations during MVP.
5. Do not introduce a new engine or major framework shift without an explicit decision.
6. For VOID DRIFTER, keep `/void-drifter` Godot-first and avoid moving primary game UI back into Expo wrappers.
7. Stop scope creep early and call out assumptions clearly.

# Do not
- Do not turn a small prototype task into an architecture project.
- Do not add speculative systems "for later".
- Do not widen gameplay scope without a documented decision.
