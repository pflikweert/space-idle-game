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

## Not Built Yet

- Boost sprite behavior; the boost PNG exists but is not wired because there is no boost trigger yet
- Final enemy sprites or imported/generated enemy assets
- Background asteroid collision or hazards; parallax is visual only
- Player upgrades, XP, pickups, or level-up choices
- Full enemy wave design or complete balance pass
- Keyboard controls
- Audio, pause, settings, screen shake, or polish pass
- Save data, accounts, backend, analytics, monetization, live ops, or store release
- Godot or any heavy game-engine migration

## Next Step Options

1. Improve visual readability for enemy silhouettes against the parallax background.
2. Add the first pickup/XP placeholder after enemy kills.
3. Do a focused 30-second tuning review after hands-on play.

Default recommendation: improve enemy readability before adding progression.
