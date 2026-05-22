# space-idle-game

Small Expo-based mobile and web prototype foundation for a future space idle / light defense game.

## Goal

Create a lean prototype base that can evolve toward a pixel / 2.5D-inspired space game without introducing backend, monetization, or heavy engine complexity in the first phase.

## Tech stack

- Expo SDK 55
- React Native
- Expo Router
- TypeScript
- npm
- Godot 4.x prototype port under `godot/void-drifter`

## Local commands

Install dependencies:

```bash
npm install
```

For the integrated Expo + Godot web flow, install Godot 4.x and its Web export templates first.
Then export the Godot build into Expo's public folder:

```bash
npm run godot:check
npm run godot:export:web
```

Start Expo web:

```bash
npm run web
```

Or export Godot and start Expo web in one command:

```bash
npm run godot:web
```

Open VOID DRIFTER through Expo:

```text
http://localhost:8081/void-drifter
```

The home screen at `http://localhost:8081/` includes an `Open VOID DRIFTER` entry button.

If `godot` is not available in PATH, set `GODOT_BIN=/path/to/Godot` before running `npm run godot:export:web`.

## Verify commands

```bash
npm run godot:check
npm run lint
npm run typecheck
```

For local visual checks, use the Codex Browser Use in-app browser against the Expo route. The workflow is documented in `docs/dev/local-browser-testing.md`; fallback `curl` checks are useful, but they are not a replacement for visual browser verification.

Prepare a small docs upload bundle for ChatGPT:

```bash
npm run docs:upload
```

This writes one generated upload bundle at `docs/upload/chatgpt-project-context.md`.

## Current structure

- `src/app/*` is the route entry and assembly layer
- `src/game/core/*` holds shared VOID DRIFTER data for Expo shell screens such as the Enemy Codex
- `src/game/state/*` holds lightweight prototype state
- `src/game/ui/*` holds screen-level game UI
- `godot/void-drifter/*` holds the first Godot 4.x VOID DRIFTER MVP port
- `godot/void-drifter/assets/player_ship/*` holds the current Luma-derived player ship sprites
- `assets/game/enemies/*/sheets` is the source for enemy sheets; generated `frames-cell` keep stable gameplay pivots, `preview.png` is used by the Enemy Codex, and `frames-tight` is only for VFX/debug after alpha checks
- `godot/void-drifter/assets/vfx/*` holds cropped projectile, trail, spark, and explosion sprites
- `godot/void-drifter/assets/backgrounds/*` holds the current sector, parallax, midfield, and foreground environment layers
- `godot/void-drifter/assets/ui/luma_reference/*` holds LCARS-neon Luma reference assets
- `public/godot/void-drifter/*` is the ignored generated Godot web export target
- `scripts/godot/extract-void-drifter-sheets.gd` extracts the current player/VFX sheets into runtime sprites
- `docs/project/*` holds game direction and MVP scope
- `docs/dev/*` holds workflow and temporary execution context
- `docs/dev/local-browser-testing.md` defines the required local browser verification flow for localhost/Expo routes

## Current prototype

- Home route: `src/app/index.tsx`
- VOID DRIFTER route: `src/app/void-drifter/index.tsx` embeds the Godot web build when exported
- Current gameplay: dark sector-framed playfield, controllable player ship, transparent data-driven enemy spawns, enemies chase the player, stable enemy visual states with direction hysteresis, auto-shooting, temporary plasma weapon boosts, simple enemy projectiles, Red Surge bonus waves every 12 Red Scout Drone kills, plasma bolt trails, hit sparks, calmer enemy explosions/debris, player damage feedback, death overlay, restart.
- Current Godot start flow: `/void-drifter` shows the Godot ready screen, `Start Run` starts the run, `Restart` is hidden until running/death states, and the Enemies entry navigates to `/void-drifter/enemies`.
- Current Godot HUD direction: sector/wave/time/score top bar plus responsive hull and plasma weapon boost status at the bottom. The wave module shows Red Surge status during surge events; sector/loadout labels stay presentation-only until real progression systems exist.
- Current local persistence: Godot stores a small VOID DRIFTER profile at `user://void_drifter_profile.json` for lifetime score/kills, total runs, best score/time/wave/surge, highest weapon level, and last-run summary.
- Godot port: `godot/void-drifter/scenes/main.tscn`
- UI style guide: `docs/project/void-drifter-ui-style-guide.md`

## What this project is not yet

- not a full gameplay implementation or balanced run
- not a backend-enabled app
- not a Supabase or OpenAI project
- not a monetized product
- not a store-ready release
- not a final heavy 3D production setup
- not using final game art, final enemies, upgrades, XP, procedural maps, audio, or persistence
