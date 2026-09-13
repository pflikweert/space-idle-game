# Railgun pulse VFX v2

Own transparent vector artwork, authored 2026-09-11. `generate.py` deterministically creates the 20 SVG runtime frames in `godot/void-drifter/assets/vfx/railgun_pulses`.

Five four-frame clips on stable 64×32 canvases: cyan pulse, violet fragment, muzzle spark, cyan impact and violet fragment impact. Forward direction is +X; origins are centered. The trace renderer anchors the right edge at the last physical contact position and never draws beyond that point.

Runtime sizes: pulse at most 20×6 game units; fragment at most 8×3. Impacts use heights 11 and 5 respectively. No baked backgrounds, bloom filters or gameplay changes. Vector files are the editable artwork; no external raster source is required.
