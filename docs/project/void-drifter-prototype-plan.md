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
- Expo route `/void-drifter` embeds the Godot web export when `public/godot/void-drifter/build-info.json` exists
- Expo route `/void-drifter-expo` keeps the React Native prototype available as fallback/reference
- `npm run godot:export:web` exports the Godot build into Expo's public folder

## Not Built Yet

- Boost sprite behavior; the boost PNG exists but is not wired because there is no boost trigger yet
- Final enemy sprites or imported/generated enemy assets
- Background asteroid collision or hazards; parallax is visual only
- Player upgrades, XP, pickups, or level-up choices
- Full enemy wave design or complete balance pass
- Keyboard controls
- Audio, pause, settings, screen shake, or polish pass
- Save data, accounts, backend, analytics, monetization, live ops, or store release
- Committed Godot web export output; the export is local/generated and ignored
- Native mobile Godot embedding inside Expo
- Editor import metadata verification in Codex; Godot is not installed in this environment
- External ECS/runtime framework; current runtime is intentionally small and local to the Expo codebase
- Shared gameplay source between Expo TypeScript and Godot GDScript

## Next Step Options

1. Install Godot 4.x + Web export templates, then run `npm run godot:export:web`.
2. Test `/void-drifter` through Expo with the embedded Godot web build.
3. Improve visual readability for enemy silhouettes against the parallax background.

Default recommendation: verify the embedded Godot route before adding progression.
