# Active Context

- status: first playable web prototype exists
- huidige focus: VOID DRIFTER Core Fun
- route: `/void-drifter`
- entry vanaf home: `Open VOID DRIFTER`
- laatste verificatie: `npm run typecheck`, `npm run lint`, browser-smoke en `npm run docs:bundle:verify` groen

## Gebouwd

- Geisoleerde Expo Router route voor VOID DRIFTER.
- Browser-speelveld met dark space achtergrond en star dots.
- Player ship gebruikt echte VOID DRIFTER PNG sprites uit de MVP asset pack.
- Sprite-state switching: idle, bank-left, bank-right en low-HP damaged.
- Click/touch-drag movement: ship vliegt smooth naar target.
- Enemies spawnen vanaf randen en bewegen naar de actuele player positie.
- Auto-shooting met bullets richting dichtstbijzijnde enemy.
- Bullet/enemy collisions, kills, eenvoudige explosion particles.
- Enemy/player collisions met HP damage.
- HUD met HP, kills, elapsed time en enemy count.
- Start overlay met `Start Run` en korte controls-hint.
- Run start pas na `Start Run`; ready-state blijft enemy-free.
- Death overlay met `Signal Lost`, kills, survived time, score en restart.
- Restart start direct een nieuwe run.
- Eerste tuning-pass voor HP, movement, fire rate, spawn pacing, enemy speed en lichte difficulty scaling.

## Nog Niet Gedaan

- Boost sprite is aanwezig als asset, maar nog niet gekoppeld omdat er geen boost-trigger bestaat.
- Enemies zijn nog placeholder shapes, geen final enemy assets.
- Geen player upgrades, XP, pickups, leveling of meta-progressie.
- Geen uitgewerkte wave-design/balancing voorbij een lichte scaling-pass.
- Geen keyboard controls.
- Geen audio, screen shake, pause, settings of accessibility pass.
- Geen backend, accounts, save system, analytics of store/live-ops werk.
- Geen Godot/heavy engine stap.

## Volgende Kleine Stap

Maak de volgende Core Fun stap klein en toetsbaar:

- optie A: kleine visual clarity pass voor enemy silhouettes
- optie B: eerste pickup/XP placeholder na kills
- optie C: 30-seconden tuning review met Pieter's speelervaring
