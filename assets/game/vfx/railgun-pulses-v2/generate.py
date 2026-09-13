"""Deterministic transparent vector animation frames; no gameplay data."""
from pathlib import Path
root = Path(__file__).resolve().parents[4]
out = root / 'godot/void-drifter/assets/vfx/railgun_pulses'
out.mkdir(parents=True, exist_ok=True)
for frame in range(4):
    fade = [1, .85, .55, .22][frame]
    for kind in ['pulse', 'fragment', 'impact', 'fragment_impact', 'muzzle']:
        cyan = '#87eeff' if 'fragment' not in kind else '#b9a4ff'
        head = f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" viewBox="0 0 64 32"><g opacity="{fade}">'
        if kind == 'pulse':
            shape = f'<path d="M3 16L42 9 62 16 42 23z" fill="{cyan}" opacity=".16"/><path d="M12 16l31-4 14 4-14 4z" fill="#37c9ff"/><path d="M24 16l20-2 11 2-11 2z" fill="#edffff"/><path d="M7 12h12M7 20h12" stroke="{cyan}" stroke-width="1"/>'
        elif kind == 'fragment':
            shape = f'<path d="M9 16l23-10 25 10-25 10z" fill="{cyan}" opacity=".18"/><path d="M20 16l13-5 20 5-20 5z" fill="#9078ff"/><path d="M29 16l7-2 13 2-13 2z" fill="#e2f5ff"/>'
        elif kind == 'muzzle':
            shape = f'<path d="M23 16L9 7l22 6L48 9l-8 7 8 7-17-4-22 6z" fill="{cyan}" opacity=".6"/><ellipse cx="29" cy="16" rx="{7-frame}" ry="3" fill="#efffff"/><path d="M36 16h{18-frame*4}" stroke="{cyan}" stroke-width="2"/>'
        else:
            radius = 3 + frame * 3
            shape = f'<ellipse cx="32" cy="16" rx="{radius*1.2}" ry="{radius}" fill="none" stroke="{cyan}" stroke-width="1.2"/><path d="M32 {16-radius-3}v4M32 {16+radius-1}v4M{32-radius-4} 16h4M{32+radius} 16h4" stroke="{cyan}" stroke-width="2"/><ellipse cx="32" cy="16" rx="{max(1,5-frame)}" ry="{max(1,4-frame)}" fill="#efffff"/>'
        (out / f'{kind}-{frame}.svg').write_text(head + shape + '</g></svg>\n')
