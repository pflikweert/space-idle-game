# VOID DRIFTER Godot MVP

First Godot 4.x port of the VOID DRIFTER Core Fun prototype.

## Run

The preferred local flow is through Expo:

```bash
npm run godot:check
npm run godot:export:web
npm run web
```

Then open:

```text
http://localhost:8081/void-drifter
```

This requires Godot 4.x and Web export templates. If Godot is not in PATH, set `GODOT_BIN`:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot npm run godot:export:web
```

## Included

- start overlay and `Start Run`
- click/touch-drag ship movement
- player ship sprites
- rotating sector backgrounds with parallax, midfield, and foreground environment layers
- enemy spawning from edges
- enemy chase movement
- semi-transparent red enemy visuals with core glow, hit flash, attack telegraph, and death VFX
- auto-shooting at nearest enemy
- plasma bolt trails/glow, hit sparks, shield-impact contact feedback, and explosion debris
- minimal Red Scout Drone enemy projectiles after telegraph charge
- Red Surge bonus waves every 12 Red Scout Drone kills, with breach VFX and clear bonus score
- bullet/enemy collision
- enemy/player damage
- sector/wave/time/score top HUD and hull/loadout-style bottom HUD
- death overlay and restart

## Notes

- This is a Godot port, not a final architecture.
- Expo remains in the repo for comparison while the Godot prototype proves the same run.
- Collision uses gameplay radii and is intentionally separate from sprite size.
- Red Surge Waves are short MVP bonus events layered on the endless run; they are not a full wave-completion, boss, or reward-choice system yet.
- Enemy attack beams now back a minimal projectile attack, but patterns and enemy weapon variety are not implemented yet.
- Boost, XP, upgrades, pickups, audio, save data, and final enemies are not implemented.

## Environment Layers

Background assets live in `assets/backgrounds/`:

- `sectors/`: full-screen biome bases. The game cycles these roughly once per minute.
- `parallax/`: deep-space layers behind gameplay.
- `midfield/`: subtle haze/texture layers behind gameplay.
- `foreground/`: low-opacity overlays drawn over ships/projectiles but below HUD.

Draw order is fixed as: sector base, parallax, midfield, gameplay, foreground overlays, HUD, modal overlays. This keeps the interface readable and always in front while still allowing cockpit/nebula foreground depth over the playfield.

To add a layer, place a PNG in the matching folder and add one entry to `BACKGROUND_SECTORS`, `PARALLAX_LAYERS`, `MIDFIELD_LAYERS`, or `FOREGROUND_LAYERS` in `scripts/void_drifter_game.gd`. Keep foreground opacity low so the player ship remains readable.
