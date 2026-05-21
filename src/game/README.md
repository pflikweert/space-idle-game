# Game Module

This folder holds the prototype game foundation.

- `core/` for VOID DRIFTER types, tuning constants, math, and collision helpers
- `runtime/` for world creation and the central simulation update
- `systems/` for small pure-TypeScript gameplay systems
- `state/` for lightweight prototype state
- `ui/` for reusable screen-level game UI

Current VOID DRIFTER playable screen:

- `ui/void-drifter-prototype-screen.tsx`
- `runtime/createInitialWorld.ts`
- `runtime/updateWorld.ts`

Keep route files thin. React Native screens own input and rendering; pure TypeScript runtime files own world state and gameplay simulation.
