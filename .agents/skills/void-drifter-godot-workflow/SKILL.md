---
name: void-drifter-godot-workflow
description: Use for VOID DRIFTER Godot gameplay, UI, enemy, asset, export, and primary /void-drifter route work.
---

# Use when
Use for VOID DRIFTER work that touches the playable game, Godot shell, start/death UI, enemies, sprites, VFX, export, or `/void-drifter`.

# Workflow
1. Treat `/void-drifter` as the Godot primary route and `/void-drifter-expo` as fallback/reference.
2. Inspect `README.md`, relevant `docs/project/*`, and `docs/dev/*` before changing established direction.
3. Update `godot/void-drifter` first for gameplay, HUD, menus, start-screen, and visual behavior.
4. Mirror shared data in `src/game/core/*` and fallback rendering in `src/game/ui/*` only where the Expo reference needs to stay aligned.
5. Keep route files thin; route wrappers should not become the primary VOID DRIFTER UI.

# Enemy Assets
1. Use transparent v2 enemy assets from `assets/game/enemies/**/frames-tight`.
2. Mirror Godot enemy folders in snake_case under `godot/void-drifter/assets/enemies/*`.
3. Use `idle-*` as fallback, `thrust-*` for movement, `hit-*` for short hit feedback, and shared VFX for death.
4. Do not use old non-transparent sprite sheets, old `move-*` v1 frame names, or internet assets.

# Enemy Data
1. Keep enemy stats data-driven in `src/game/core/enemies.ts`.
2. Mirror the same enemy definition shape in `godot/void-drifter/scripts/void_drifter_game.gd`.
3. Spawn enemies by active status, `minRunLevel`, and weight.
4. Add new enemy behavior only when explicitly requested; default to existing chase/contact/projectile behavior already present in Godot.

# Verification
1. Run `npm run typecheck` and `npm run lint` after TypeScript/UI changes.
2. Run `npm run godot:check` after Godot script, scene, or asset changes.
3. Run `npm run godot:export:web` when a web build verification is requested or needed.
4. Run `npm run docs:upload` after docs updates that affect handoff context.

# Do not
- Do not add backend, admin editor, boss systems, live ops, account systems, or monetization during MVP.
- Do not switch engines or move primary game UI out of Godot without an explicit decision.
- Do not claim browser verification unless a screenshot, DOM snapshot, or console output was inspected.
