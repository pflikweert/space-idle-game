---
name: expo-rn-screen-workflow
description: Small workflow for Expo and React Native screens, routes, and UI structure.
---

# Use when
Use for screen work, route work, or lightweight UI implementation.

# Workflow
1. Inspect the current route structure first.
2. Keep route files focused on assembly and hand off feature UI to `src/game/ui/*` when helpful.
3. Reuse existing theme and layout patterns before adding new ones.
4. Keep the primary action obvious and the copy compact.
5. Avoid extra dependencies for simple screens.
6. For VOID DRIFTER, Expo screens are shell/codex UI only; gameplay belongs in Godot.

# Do not
- Do not add unrelated state, data, or infra work during a screen task.
- Do not introduce multiple new visual patterns in one pass.
- Do not rebuild a React Native gameplay fallback for VOID DRIFTER.
