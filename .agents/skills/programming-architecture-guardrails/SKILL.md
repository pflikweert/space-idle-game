---
name: programming-architecture-guardrails
description: Keep prototype code small, testable, and easy to grow without over-architecting.
---

# Use when
Use for stateful UI, repeated logic, helpers, or files that are starting to grow.

# Guardrails
1. Put pure calculations and content constants in `src/game/core/*`.
2. Put stateful prototype hooks in `src/game/state/*`.
3. Put reusable screen-level UI in `src/game/ui/*`.
4. Keep route files focused on wiring and composition.
5. Extract only when it improves readability, reuse, or testability right now.

# Do not
- Do not add abstraction layers without a concrete need.
- Do not refactor broad areas during a small prototype task.
