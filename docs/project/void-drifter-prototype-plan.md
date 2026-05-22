# VOID DRIFTER Prototype Plan

## Current Goal

Prove that one short browser-playable run feels readable and fun before adding systems.

## Built

- Isolated web route: `/void-drifter`
- Home entry button: `Open VOID DRIFTER`
- Three-layer parallax space background
- Background scroll speeds: far stars 12 px/sec, mid nebula 24 px/sec, near asteroids 48 px/sec
- Godot sector presentation now uses a darker center mask, rotating sector bases, extra parallax/midfield layers, and low-opacity foreground overlays where available
- Player ship PNG sprites from the current Luma gameplay sheet
- Player sheet extraction keeps idle, bank-left, bank-right, boost, damaged, shield, and icon sprites under `godot/void-drifter/assets/player_ship/`
- Ship sprite-state switching for idle, bank-left, bank-right, and low-HP damaged
- Godot bullets, hit sparks, engine trail, and enemy death bursts use cropped VFX sheet sprites from `godot/void-drifter/assets/vfx/`
- Enemy Asset Pack v2 is installed under `assets/game/enemies/` with transparent Red Scout Drone, Red Fighter, Red Cruiser, and shared enemy VFX frames
- Red Scout Drone, Red Fighter, and Red Cruiser use transparent fixed 384x512 `frames-cell` idle/thrust/attack/hit direction sprites plus shared enemy death VFX
- Enemy sheet extraction recenters alpha content on fixed gameplay canvases so direction and hit frames keep a stable pivot; it also generates per-enemy `preview.png` assets for the Codex. `frames-tight` is reserved for VFX/debug use after alpha/bounds checks.
- Godot combat feedback pass: plasma bolt trails/glow, subtle enemy aura/outline, velocity-based direction frames with hysteresis, hit as flash/spark overlay instead of death-looking primary sprites, event-based attack warmup as telegraph/FX, enemy HP feedback, calmer death burst/debris, and shield-impact contact feedback for player damage
- Future VFX assets are also cropped and import-ready: player laser beam, enemy red bullet, enemy purple shot, shield impact, and level-up burst
- Sheet extraction helpers exist at `scripts/godot/extract-void-drifter-sheets.gd` and `scripts/godot/extract-void-drifter-enemies.gd`
- Click/touch-drag ship movement
- Start overlay with `Start Run` and controls hint
- Run stays enemy-free until started
- Red Scout Drone, Red Fighter, and Red Cruiser are active enemy types
- Enemy registry added for data-driven overview data; Godot mirrors the gameplay definitions for weighted run-level spawning
- Red enemies spawn from playfield edges
- Enemies chase the player position
- Enemy attack warmup shows a short red telegraph, then fires a simple red enemy projectile
- Red Surge Waves in Godot: every 12 kills starts a short bonus surge with 5-9 red hostiles, paused normal spawning, edge/layer breach VFX, bonus score, and `RED SURGE` / `SURGE CLEARED` feedback
- Enemy stats now scale through simple run-level progression: `1 + floor(elapsed / 30)`
- In-run plasma weapon boosts are automatic and temporary: kills fill charge, then level 2/3/4 briefly improve fire rate, damage, and shot count before returning to level 1
- Player auto-shoots at nearest enemy
- Bullets can kill enemies
- Enemies can damage the player
- Enemy projectiles can damage the player and trigger shield-impact feedback
- HUD shows HP, kills, elapsed time, enemy count, score, plasma boost level, charge, and timer
- Death overlay shows kills, survived time, score, earned score, best score, and lifetime score
- Local Godot profile persistence stores lifetime score/kills, total runs, best score/time/wave/surge, highest weapon level, and last-run summary in `user://void_drifter_profile.json`
- Restart starts a new run immediately
- Light tuning pass: calmer first seconds, responsive movement, faster bullets, slower early enemies, spawn/max-enemy scaling
- First Godot 4.x MVP port under `godot/void-drifter`
- Godot scene includes start flow, ship movement, parallax, enemy spawning/chase, auto-shooting, collisions, HUD, death, and restart
- Godot start screen regression is fixed: script parse/load is clean, `Start Run` starts the run, `Restart` is hidden in ready state, and the `Enemy Codex` entry belongs to the Godot start/death UI instead of the Expo iframe shell
- Expo route `/void-drifter` embeds the Godot web export when `public/godot/void-drifter/build-info.json` exists
- Expo route `/void-drifter/enemies` shows Red Scout Drone, Red Fighter, and Red Cruiser as active with stats, scaling, run-level unlocks, spawn weights, abilities, and sprite previews
- `npm run godot:export:web` exports the Godot build into Expo's public folder
- LCARS-neon UI style guide under `docs/project/void-drifter-ui-style-guide.md`
- Luma reference UI assets under `godot/void-drifter/assets/ui/luma_reference/`
- Godot HUD/start/death UI uses LCARS-neon panels, compact meters, chips, scanlines, and styled neon buttons
- Godot HUD now leans toward the MVP reference: top sector/wave/time/score/kills, Red Surge status in the wave module during surge events, and responsive bottom hull plus plasma weapon boost strip
- `npm run godot:check` performs a headless Godot scene-load check and fails on script parse/load errors before web export

## Not Built Yet

- Boost and shield ship sprites exist as assets, but boost/shield gameplay behavior is not wired because there is no trigger/system yet
- Sector and loadout UI are presentation-only; no real sector progression, loadout selection, weapon inventory, shop, or reward-choice system exists yet
- Enemy projectile gameplay is intentionally minimal: straight shots, simple cooldown, no enemy-specific pattern variants yet
- Red Surge Waves are short bonus events on top of endless spawning, not a full wave-completion game, boss system, or reward-choice loop
- React Native gameplay fallback has been removed; VOID DRIFTER gameplay is Godot-only
- Background asteroid collision or hazards; parallax is visual only
- XP, pickups, level-up choices, shop, or persistent upgrade purchases
- Upgrade/shop UI implementation; the Luma upgrade mockup is reference only
- Full enemy wave design or complete balance pass beyond the first Red Surge MVP
- Keyboard controls
- Audio, pause, settings, screen shake, or polish pass
- Accounts, backend, analytics, monetization, live ops, or store release; persistence is local Godot JSON only
- Committed Godot web export output; the export is local/generated and ignored
- Native mobile Godot embedding inside Expo
- External ECS/runtime framework; current runtime is intentionally small and local to the Expo codebase
- Shared gameplay source between Expo TypeScript and Godot GDScript

## Next Step Options

1. Start `npm run web` and visually test `/void-drifter` through Expo with the embedded Godot web build.
2. Visually verify Enemy Codex navigation and Fighter/Cruiser spawning around runLevel 2/4.
3. Tune temporary plasma boost thresholds/durations after visual browser verification.

Default recommendation: visually verify the LCARS-neon Godot run on desktop, mobile, and short-height viewports before adding any shop or reward-choice systems.
