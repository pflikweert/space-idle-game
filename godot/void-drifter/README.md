# VOID DRIFTER Godot MVP

First Godot 4.x port of the VOID DRIFTER Core Fun prototype.

## Run

The preferred local flow is through Expo:

```bash
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
- three parallax background layers
- enemy spawning from edges
- enemy chase movement
- auto-shooting at nearest enemy
- bullet/enemy collision
- enemy/player damage
- HP/kills/time/enemy HUD
- death overlay and restart

## Notes

- This is a Godot port, not a final architecture.
- Expo remains in the repo for comparison while the Godot prototype proves the same run.
- Collision uses gameplay radii and is intentionally separate from sprite size.
- Boost, XP, upgrades, pickups, audio, save data, and final enemies are not implemented.
