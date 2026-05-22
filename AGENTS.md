# AGENTS.md

## Sources

Use this order:

1. `README.md`
2. relevant docs in `docs/project/*`
3. relevant workflow notes in `docs/dev/*`
4. a matching skill in `.agents/skills/*`

Read only task-relevant files. Do not adopt a "read everything" workflow.

`docs/upload/**` is generated upload output for ChatGPT handoff, not canonical source.

## Scope guardrails

- This repo is a lightweight prototype foundation for `space-idle-game`.
- Prefer the smallest working step.
- Avoid feature creep and avoid re-deciding documented choices without a reason.
- MVP scope stays narrow: one playable prototype screen, placeholder progression, no production systems.
- Do not add backend, Supabase, OpenAI, monetization, account systems, analytics, live ops, or store-release work unless explicitly requested in a later phase.
- Do not swap to a heavy game engine without an explicit decision.
- VOID DRIFTER UI must follow `docs/project/void-drifter-ui-style-guide.md`: LCARS-inspired, neon, semi-transparent, arcade-readable, and Godot-first for the primary route.

## Working style

- Analyze the existing code before changing structure.
- Reuse existing Expo and React Native patterns before adding new ones.
- Keep route files thin and let `src/game/*` hold prototype-specific UI, state, and core helpers.
- For VOID DRIFTER, `/void-drifter` is Godot-first and there is no React Native gameplay fallback. Update `godot/void-drifter` gameplay, HUD, menus, start screen, and assets first.
- For Godot animation work, use `.agents/skills/godot-animation-workflow`: choose the simplest suitable node (`AnimationPlayer`, `AnimationTree`, `AnimatedSprite2D`, or `Tween`), keep animation FSM separate from gameplay FSM, and verify Godot changes with `npm run godot:check`.
- For VOID DRIFTER enemy work, use the enemy sheets under `assets/game/enemies/**/sheets` as the source, generate fixed `frames-cell` canvases for Godot gameplay, generate `preview.png` for Enemy Codex cards, and reserve `frames-tight` for VFX/debug only after alpha/bounds checks. Mirror Godot enemy folders as snake_case under `godot/void-drifter/assets/enemies/*`. Do not reintroduce old non-transparent sheets or old `move-*` v1 frames.
- Keep enemy/player movement sprites on stable transparent canvases; do not draw gameplay sprites from tightly cropped frames when that would move the pivot or make side/hit frames appear sliced. Enemy visual state should use short timers and direction hysteresis instead of swapping state/direction every frame. When combat frames read like death/explosion art, keep the movement sprite as the primary and show hit/attack as FX overlays.
- Keep bottom HUD and weapon strips responsive on short/mobile viewports; reserve playfield space so the player is not clamped behind UI.
- Keep VOID DRIFTER enemy definitions data-driven in `src/game/core/enemies.ts` and mirrored in `godot/void-drifter/scripts/void_drifter_game.gd`. Spawning should use active status, run-level gates, and weights rather than hardcoded one-off enemy ids.
- Enemy overview/codex navigation for the primary game belongs in the Godot root/start interface first, not only in Expo route wrapper panels.
- For localhost/browser verification, use `.agents/skills/local-browser-testing` and `docs/dev/local-browser-testing.md`: prefer Browser Use, search for the Node REPL `js` tool if needed, and never claim a visual browser check without a screenshot, DOM snapshot, or console log inspection.
- For larger changes, start with a short plan or checklist.
- Prefer small, reviewable edits over broad refactors.

## Verification

- Do not start a long-lived dev server unless explicitly asked.
- After relevant code changes, run `npm run lint` and `npm run typecheck` when available.
- If a verification command does not exist, say so clearly instead of pretending it ran.
- After docs changes that affect ChatGPT handoff context, run `npm run docs:upload` and optionally `npm run docs:bundle:verify`.

## Security

- Never commit secrets, tokens, or local env files.
- Keep this repo frontend-only unless a later phase explicitly introduces more.
