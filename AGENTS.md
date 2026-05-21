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
- For VOID DRIFTER, `/void-drifter` is Godot-first. Update `godot/void-drifter` gameplay, HUD, menus, start screen, and assets first; keep `/void-drifter-expo` as fallback/reference unless explicitly asked.
- For VOID DRIFTER enemy work, use `assets/game/enemies/**/frames-tight` as the source of transparent sprites. Mirror Godot enemy folders as snake_case under `godot/void-drifter/assets/enemies/*`. Do not reintroduce old non-transparent sheets or old `move-*` v1 frames.
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
