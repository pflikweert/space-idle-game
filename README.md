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

The old React Native prototype remains available as a fallback/reference:

```text
http://localhost:8081/void-drifter-expo
```

If `godot` is not available in PATH, set `GODOT_BIN=/path/to/Godot` before running `npm run godot:export:web`.

## Verify commands

```bash
npm run lint
npm run typecheck
```

Prepare a small docs upload bundle for ChatGPT:

```bash
npm run docs:upload
```

This writes one generated upload bundle at `docs/upload/chatgpt-project-context.md`.

## Current structure

- `src/app/*` is the route entry and assembly layer
- `src/game/core/*` holds VOID DRIFTER types, tuning constants, math, and collision helpers
- `src/game/runtime/*` holds world creation and the central `updateWorld` simulation step
- `src/game/systems/*` holds small pure-TypeScript gameplay systems
- `src/game/state/*` holds lightweight prototype state
- `src/game/ui/*` holds screen-level game UI
- `godot/void-drifter/*` holds the first Godot 4.x VOID DRIFTER MVP port
- `public/godot/void-drifter/*` is the ignored generated Godot web export target
- `docs/project/*` holds game direction and MVP scope
- `docs/dev/*` holds workflow and temporary execution context

## Current prototype

- Home route: `src/app/index.tsx`
- VOID DRIFTER route: `src/app/void-drifter/index.tsx` embeds the Godot web build when exported
- Expo fallback route: `src/app/void-drifter-expo/index.tsx`
- Expo fallback screen: `src/game/ui/void-drifter-prototype-screen.tsx`
- Runtime entry: `src/game/runtime/updateWorld.ts`
- Current gameplay: dark playfield, controllable player ship, enemy spawns, enemies chase the player, auto-shooting, bullet/enemy collisions, player damage, death overlay, restart.
- Godot port: `godot/void-drifter/scenes/main.tscn`

## What this project is not yet

- not a full gameplay implementation or balanced run
- not a backend-enabled app
- not a Supabase or OpenAI project
- not a monetized product
- not a store-ready release
- not a final heavy 3D production setup
- not using final game art, final enemies, upgrades, XP, procedural maps, audio, or persistence
