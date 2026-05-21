# VOID DRIFTER Prototype Plan

## Current Goal

Prove that one short browser-playable run feels readable and fun before adding systems.

## Built

- Isolated web route: `/void-drifter`
- Home entry button: `Open VOID DRIFTER`
- Three-layer parallax space background
- Background scroll speeds: far stars 12 px/sec, mid nebula 24 px/sec, near asteroids 48 px/sec
- Player ship PNG sprites from the MVP asset pack
- Ship sprite-state switching for idle, bank-left, bank-right, and low-HP damaged
- Click/touch-drag ship movement
- Start overlay with `Start Run` and controls hint
- Run stays enemy-free until started
- Enemies spawn from playfield edges
- Enemies chase the player position
- Player auto-shoots at nearest enemy
- Bullets can kill enemies
- Enemies can damage the player
- HUD shows HP, kills, elapsed time, enemy count
- Death overlay shows kills, survived time, score
- Restart starts a new run immediately
- Light tuning pass: calmer first seconds, responsive movement, faster bullets, slower early enemies, spawn/max-enemy scaling
- Internal pure TypeScript game runtime under `src/game/core`, `src/game/runtime`, and `src/game/systems`
- Central `WorldState`, `createInitialWorld()`, and `updateWorld(world, input, deltaMs)` preserve gameplay outside the React render layer
- First Godot 4.x MVP port under `godot/void-drifter`
- Godot scene includes start flow, ship movement, parallax, enemy spawning/chase, auto-shooting, collisions, HUD, death, and restart

## Not Built Yet

- Boost sprite behavior; the boost PNG exists but is not wired because there is no boost trigger yet
- Final enemy sprites or imported/generated enemy assets
- Background asteroid collision or hazards; parallax is visual only
- Player upgrades, XP, pickups, or level-up choices
- Full enemy wave design or complete balance pass
- Keyboard controls
- Audio, pause, settings, screen shake, or polish pass
- Save data, accounts, backend, analytics, monetization, live ops, or store release
- Godot export/build pipeline, editor import metadata verification, or platform packaging
- External ECS/runtime framework; current runtime is intentionally small and local to the Expo codebase
- Shared gameplay source between Expo TypeScript and Godot GDScript

## Next Step Options

1. Open the Godot port in the editor and verify the Core Fun run hands-on.
2. Improve visual readability for enemy silhouettes against the parallax background.
3. Decide whether the Expo prototype is frozen as reference or kept in parallel.

Default recommendation: verify the Godot port manually before adding progression.
