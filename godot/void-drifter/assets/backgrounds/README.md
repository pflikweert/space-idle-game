# VOID DRIFTER Background Layers

Runtime background assets are grouped by depth:

- `sectors/`: full-screen biome bases that rotate during a run.
- `parallax/`: slow deep-space layers behind gameplay.
- `midfield/`: haze and texture layers behind gameplay.
- `foreground/`: very subtle overlays above gameplay but below HUD.

The Godot draw order is:

```text
sector -> parallax -> midfield -> gameplay -> foreground -> HUD -> overlays/buttons
```

Add new PNG files to the relevant folder, then register them in `scripts/void_drifter_game.gd`. Keep foreground overlays low opacity; they may pass over ships, but the HUD must remain the top visual layer.
