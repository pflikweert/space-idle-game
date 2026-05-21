# VOID DRIFTER Prototype Plan

## Current Goal

Prove that one short browser-playable run feels readable and fun before adding systems.

## Built

- Isolated web route: `/void-drifter`
- Home entry button: `Open VOID DRIFTER`
- Dark cosmic playfield with star dots
- Placeholder player ship with engine glow/trail
- Click/touch-drag ship movement
- Enemies spawn from playfield edges
- Enemies chase the player position
- Player auto-shoots at nearest enemy
- Bullets can kill enemies
- Enemies can damage the player
- HUD shows HP, kills, elapsed time, enemy count
- Death overlay shows kills/time
- Restart resets the run

## Not Built Yet

- Final player ship sprite or imported/generated game assets
- Start screen inside the VOID DRIFTER route
- Player upgrades, XP, pickups, or level-up choices
- Enemy wave design, difficulty curve, or balanced tuning
- Keyboard controls
- Audio, pause, settings, screen shake, or polish pass
- Save data, accounts, backend, analytics, monetization, live ops, or store release
- Godot or any heavy game-engine migration

## Next Step Options

1. Add a start overlay with `Start Run` and a tiny controls hint.
2. Tune the first 30 seconds: movement speed, spawn rate, enemy speed, fire rate, damage.
3. Add the first pickup/XP placeholder after enemy kills.

Default recommendation: tune the first 30 seconds before adding progression.
