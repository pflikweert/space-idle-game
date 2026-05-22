---
name: void-drifter-godot-workflow
description: Use for VOID DRIFTER Godot gameplay, UI, enemy, asset, export, and primary /void-drifter route work.
---

# Use when
Use for VOID DRIFTER work that touches the playable game, Godot shell, start/death UI, enemies, sprites, VFX, export, or `/void-drifter`.

# Workflow
1. Treat `/void-drifter` as the Godot primary route. There is no React Native gameplay fallback.
2. Inspect `README.md`, relevant `docs/project/*`, and `docs/dev/*` before changing established direction.
3. Update `godot/void-drifter` first for gameplay, HUD, menus, start-screen, and visual behavior.
4. Mirror shared data in `src/game/core/*` only where Expo UI still needs it, such as the Enemy Codex.
5. Keep route files thin; route wrappers should not become the primary VOID DRIFTER UI.

# Enemy Assets
1. Treat `assets/game/enemies/**/sheets` as the authoritative enemy source and regenerate frames deterministically when a new pack lands.
2. Use fixed `frames-cell` / 384x512 canvas frames for gameplay sprites with movement states so pivots do not jitter between directions or hit states.
3. Use generated `preview.png` assets for Codex previews. Use `frames-tight` only for VFX or debug views after alpha/bounds checks, never as a gameplay anchor.
4. Mirror Godot enemy folders in snake_case under `godot/void-drifter/assets/enemies/*`.
5. Use `idle-*` as fallback, `thrust-*` for movement, `hit-*` for short hit feedback, and shared VFX for death.
6. Keep enemy visual state timer-based with direction hysteresis so diagonal movement, hit feedback, and attack warmup do not flicker. If a combat frame reads as a death/explosion frame, keep the movement sprite as primary and render hit/attack as FX overlays instead.
7. Keep generated enemy and VFX art pixel-game friendly: arcade-readable silhouettes, moderate detail, restrained glow/debris, and no max-fidelity photoreal render targets unless explicitly requested.
8. Enemy death/explosion VFX should stay subtle and reusable: short transition frames, optional small debris drift variants, transparent backgrounds, and no screen-filling blasts by default.
9. Do not use old non-transparent sprite sheets, old `move-*` v1 frame names, or internet assets.

# Enemy Data
1. Keep enemy stats data-driven in `src/game/core/enemies.ts`.
2. Mirror the same enemy definition shape in `godot/void-drifter/scripts/void_drifter_game.gd`.
3. Spawn enemies by active status, `minRunLevel`, and weight.
4. Add new enemy behavior only when explicitly requested; default to existing chase/contact/projectile behavior already present in Godot.

# HUD + Progression
1. Keep the primary HUD in Godot and reserve bottom playfield space for hull/weapon UI on mobile and short viewports.
2. Local MVP progress may use `user://void_drifter_profile.json`; do not introduce backend/account systems for persistence.
3. Temporary in-run weapon upgrades should stay small and automatic unless a later request asks for pickups, choices, or shops.

# Verification
1. Run `npm run typecheck` and `npm run lint` after TypeScript/UI changes.
2. Run `npm run godot:check` after Godot script, scene, or asset changes.
3. Run `npm run godot:export:web` when a web build verification is requested or needed.
4. Run `npm run docs:upload` after docs updates that affect handoff context.

# Do not
- Do not add backend, admin editor, boss systems, live ops, account systems, or monetization during MVP.
- Do not switch engines or move primary game UI out of Godot without an explicit decision.
- Do not claim browser verification unless a screenshot, DOM snapshot, or console output was inspected.
