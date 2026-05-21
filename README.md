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

## Local commands

Install dependencies:

```bash
npm install
```

Start locally when needed:

```bash
npm run web
npm run ios
npm run android
```

## Verify commands

```bash
npm run lint
npm run typecheck
```

## Current structure

- `src/app/*` is the route entry and assembly layer
- `src/game/core/*` holds simple content and pure helpers
- `src/game/state/*` holds lightweight prototype state
- `src/game/ui/*` holds screen-level game UI
- `docs/project/*` holds game direction and MVP scope
- `docs/dev/*` holds workflow and temporary execution context

## What this project is not yet

- not a full gameplay implementation
- not a backend-enabled app
- not a Supabase or OpenAI project
- not a monetized product
- not a store-ready release
- not a heavy 3D or dedicated game-engine setup
