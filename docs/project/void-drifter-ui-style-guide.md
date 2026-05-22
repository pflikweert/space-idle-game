# VOID DRIFTER UI Style Guide

## Direction

VOID DRIFTER uses an LCARS-inspired mobile arcade interface: modular sci-fi panels, rounded asymmetric blocks, neon edge glow, transparent overlays, and compact information density.

This is inspiration, not a direct Star Trek copy. Do not use Star Trek marks, iconography, Federation colors, or references.

## Palette

- Primary cyan: `#00E5FF`
- Player blue: `#1565C0`
- Magenta accent: `#FF00FF`
- Purple panel: `#6A1B9A`
- Warning orange: `#FF6D00`
- Health teal: `#00E676`
- Background dark: `#0A0A14`
- Panel dark: `#121228`
- Panel mid: `#1A1A3E`
- Text primary: `#E0E0FF`
- Text secondary: `#6070A0`

## Gameplay HUD Rules

- Keep gameplay readable first.
- Use semi-transparent panels; never cover the playfield with large opaque blocks.
- HUD should stay compact, roughly 15% of the screen where possible.
- Top HUD: sector, wave, time, score, kills, and enemy count presentation.
- Bottom HUD: hull/health and compact weapon charge/boost information; reserve playfield space on short/mobile viewports so gameplay never sits underneath it.
- Weapon strips may show locked/loadout placeholders, but they must be clearly non-interactive until upgrades and inventory are actually implemented.
- Text is small, uppercase, and high contrast.
- Use cyan for player/system info, magenta for special/progression, orange for danger, teal for positive status.

## MVP Visual Direction

- The playfield should read as a dark sector frame with bright pixel/neon combat feedback.
- Keep the center darker than the edges so player, drones, bullets, and VFX stay readable.
- Player plasma should use short cyan/blue trails and glow, not long opaque beams.
- Red Scout Drone readability comes from subtle red aura/outline, hit flash, and small HP feedback rather than larger hitboxes.
- Deaths should feel punchier through explosion sprite bursts plus small debris particles.
- Player contact damage may use `shield_impact` as feedback only; do not imply a real shield mechanic until one exists.

## Components

- Panels: LCARS-like asymmetric rounded panels, dark translucent fill, colored header block, subtle glow border.
- Buttons: cyan/magenta neon panel buttons, no native platform look.
- Bars/meters: capsule or LCARS bars with glowing fills and dark tracks.
- Overlays: central LCARS frames for start, pause, death, or run summary.
- Effects: scanlines, subtle flicker/glow, and chromatic-neon feeling are preferred over flat UI.

## Assets

Luma reference assets live under:

```text
godot/void-drifter/assets/ui/luma_reference/
```

These files are source inspiration and review references. Runtime UI should remain scalable Godot drawing or properly sliced future UI sprites, not full-screen mockup images pasted over gameplay.
