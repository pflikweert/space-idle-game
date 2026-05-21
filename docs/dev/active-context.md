# Active Context

- status: first playable web prototype exists
- huidige focus: VOID DRIFTER Core Fun
- route: `/void-drifter`
- entry vanaf home: `Open VOID DRIFTER`
- laatste verificatie: `npm run typecheck` en `npm run lint` groen

## Gebouwd

- Geisoleerde Expo Router route voor VOID DRIFTER.
- Browser-speelveld met dark space achtergrond en star dots.
- Player ship placeholder in neon/pixelachtige stijl.
- Click/touch-drag movement: ship vliegt smooth naar target.
- Enemies spawnen vanaf randen en bewegen naar de actuele player positie.
- Auto-shooting met bullets richting dichtstbijzijnde enemy.
- Bullet/enemy collisions, kills, eenvoudige explosion particles.
- Enemy/player collisions met HP damage.
- HUD met HP, kills, elapsed time en enemy count.
- Death overlay met score, time en restart.
- Restart reset de run.

## Nog Niet Gedaan

- Geen final ship asset of uploaded reference-art implementatie.
- Geen player upgrades, XP, pickups, leveling of meta-progressie.
- Geen start-run menu binnen de VOID DRIFTER route.
- Geen enemy waves/balancing/difficulty curve.
- Geen keyboard controls.
- Geen audio, screen shake, pause, settings of accessibility pass.
- Geen backend, accounts, save system, analytics of store/live-ops werk.
- Geen Godot/heavy engine stap.

## Volgende Kleine Stap

Maak de run beter leesbaar en leuker door een kleine start/death flow of tuning-pass te kiezen:

- optie A: start overlay met `Start Run` en korte controls-hint
- optie B: tuning-pass voor movement/enemy speed/fire rate/HP
- optie C: eerste pickup/XP placeholder na kills
