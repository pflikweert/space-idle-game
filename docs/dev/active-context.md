# Active Context

- status: first playable web prototype exists
- huidige focus: VOID DRIFTER Core Fun
- route: `/void-drifter`
- entry vanaf home: `Open VOID DRIFTER`
- laatste verificatie: `npm run typecheck`, `npm run lint`, browser-smoke en `npm run docs:bundle:verify` groen
- runtime status: VOID DRIFTER gameplay is split into `src/game/core`, `src/game/runtime`, and `src/game/systems`
- Godot status: eerste Godot 4.x MVP-port staat in `godot/void-drifter` en `/void-drifter` embedt de Godot web-export zodra die lokaal is gebouwd
- lokale browsercheck: voortaan Browser Use proberen volgens `docs/dev/local-browser-testing.md`; als de runtime niet beschikbaar is, expliciet melden en alleen fallback smoke checks gebruiken

## Gebouwd

- Geisoleerde Expo Router route voor VOID DRIFTER.
- Browser-speelveld met drie VOID DRIFTER parallax background layers.
- Background scroll speeds: far stars 12 px/sec, mid nebula 24 px/sec, near asteroids 48 px/sec.
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
- Interne pure TypeScript game-runtime met centrale `WorldState`, `createInitialWorld()` en `updateWorld(world, input, deltaMs)`.
- Gameplay systems zijn opgesplitst voor player movement, enemy spawning/movement, weapons, projectiles, collisions en effects.
- Godot 4.x project met `project.godot`, `scenes/main.tscn`, GDScript gameplay loop en gekopieerde bestaande player/background assets.
- Godot-port bevat dezelfde Core Fun: start, movement, enemies, auto-shooting, collisions, HP/kills/time HUD, death en restart.
- Expo route `/void-drifter` is nu de Godot embed shell.
- Expo route `/void-drifter-expo` bewaart de React Native prototypeversie als fallback/reference.
- Script `npm run godot:export:web` exporteert Godot naar `public/godot/void-drifter`.
- LCARS-neon UI richting is vastgelegd in `docs/project/void-drifter-ui-style-guide.md`.
- Luma UI reference assets staan in `godot/void-drifter/assets/ui/luma_reference/`.
- Godot HUD/start/death UI gebruikt LCARS-neon panels, meters, chips, scanlines en gestylede buttons.
- Lokale browser-verificatieafspraak is vastgelegd in `docs/dev/local-browser-testing.md` en `.agents/skills/local-browser-testing/SKILL.md`.

## Nog Niet Gedaan

- Boost sprite is aanwezig als asset, maar nog niet gekoppeld omdat er geen boost-trigger bestaat.
- Enemies zijn nog placeholder shapes, geen final enemy assets.
- Background asteroids zijn alleen visueel; geen collision/hazards.
- Geen player upgrades, XP, pickups, leveling of meta-progressie.
- Geen uitgewerkte wave-design/balancing voorbij een lichte scaling-pass.
- Geen keyboard controls.
- Geen audio, screen shake, pause, settings of accessibility pass.
- Geen upgrade/shop UI implementatie; Luma upgrade mockup is alleen referentie.
- Geen backend, accounts, save system, analytics of store/live-ops werk.
- Geen gecommit Godot web-export output; `public/godot/void-drifter` is lokaal/generated.
- Geen native mobile Godot-in-Expo integratie; de integratie is web-first via Expo route + Godot HTML export.
- Geen gedeelde runtime tussen Expo TypeScript en Godot GDScript; dit is een eerste port naast de bestaande webversie.
- Geen externe ECS-framework.

## Volgende Kleine Stap

Maak de volgende Core Fun stap klein en toetsbaar:

- optie A: test `/void-drifter` via Expo met de embedded Godot build
- optie B: kleine visual clarity pass voor enemy silhouettes tegen de parallax achtergrond
- optie C: eerste upgrade/shop screen pas plannen nadat de run visueel klopt
