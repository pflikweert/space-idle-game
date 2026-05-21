# Active Context

- status: first playable Godot web prototype exists with transparent v2 enemy roster
- huidige focus: VOID DRIFTER Core Fun
- route: `/void-drifter`
- entry vanaf home: `Open VOID DRIFTER`
- laatste verificatie: Godot headless scene-load via `npm run godot:check`, `npm run godot:export:web`, `npm run typecheck`, `npm run lint`, Expo static export en `npm run docs:bundle:verify` groen; browser-smoke via `curl` kon niet omdat `localhost:8081` niet draaide
- runtime status: VOID DRIFTER gameplay is split into `src/game/core`, `src/game/runtime`, and `src/game/systems`
- Godot status: eerste Godot 4.x MVP-port staat in `godot/void-drifter` en `/void-drifter` embedt de Godot web-export zodra die lokaal is gebouwd
- enemy status: Enemy Asset Pack v2 is toegevoegd; Red Scout Drone, Red Fighter en Red Cruiser zijn active data-driven enemies met run-level gated weighted spawning
- lokale browsercheck: voortaan Browser Use proberen volgens `docs/dev/local-browser-testing.md`; als de runtime niet beschikbaar is, expliciet melden en alleen fallback smoke checks gebruiken

## Gebouwd

- Geisoleerde Expo Router route voor VOID DRIFTER.
- Browser-speelveld met drie VOID DRIFTER parallax background layers.
- Background scroll speeds: far stars 12 px/sec, mid nebula 24 px/sec, near asteroids 48 px/sec.
- Godot sector background gebruikt een donker center-mask, roterende sector bases, parallax, midfield haze en subtiele foreground overlays.
- Player ship gebruikt nieuwe Luma VOID DRIFTER PNG sprites uit de gameplay sheet.
- Godot player sheet output bevat idle, bank-left, bank-right, boost, damaged, shield en icon sprites.
- Sprite-state switching: idle, bank-left, bank-right en low-HP damaged.
- Godot bullets, hit sparks, engine trail en enemy death bursts gebruiken uitgesneden VFX sheet sprites.
- Red Scout Drone, Red Fighter en Red Cruiser gebruiken Enemy Asset Pack v2 `frames-tight` sprites: idle/thrust/hit per richting, transparante PNGs en shared enemy death VFX.
- Godot run heeft een visual clarity pass: plasma bolt trails, Red Scout Drone aura/outline, richtingframes, hit flash, HP feedback, grotere death burst + debris en shield-impact feedback bij player contact damage.
- Overige VFX sprites staan alvast import-ready klaar: player laser beam, enemy red bullet, enemy purple shot, shield impact en level-up burst.
- Script `scripts/godot/extract-void-drifter-sheets.gd` snijdt de player/VFX sheets opnieuw uit.
- Click/touch-drag movement: ship vliegt smooth naar target.
- Red enemies spawnen vanaf randen en bewegen naar de actuele player positie.
- Red enemies gebruiken de bestaande attack telegraph/projectile loop; contact damage blijft daarnaast bestaan.
- Red Surge Waves zijn Godot-first gebouwd: elke 12 kills start een korte bonus-surge met 5-9 red hostiles, tijdelijke pauze op normale spawning, edge/layer breach VFX, bonus score en `RED SURGE` / `SURGE CLEARED` feedback.
- Enemy registry toegevoegd in Expo/TypeScript voor data-driven stats, overzicht en fallback/reference gameplay.
- Enemy stats schalen via simpele `runLevel = 1 + floor(elapsed / 30)`.
- Enemy Codex route `/void-drifter/enemies` toont Red Scout Drone, Red Fighter en Red Cruiser als active met stats, scaling, run-level unlocks, spawn weights, abilities en sprite preview.
- Auto-shooting met bullets richting dichtstbijzijnde enemy.
- Bullet/enemy collisions, kills, eenvoudige explosion particles.
- Enemy/player collisions met HP damage.
- Enemy projectile/player collisions met HP damage en shield-impact feedback.
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
- `/void-drifter` startscherm-regressie is gefixt: het Godot script parse't weer, `Start Run` koppelt opnieuw aan de run-state, `Restart` is niet zichtbaar op ready, en de `Enemy Codex` entry zit in de Godot start/death-flow in plaats van als losse Expo iframe-overlay.
- Expo route `/void-drifter-expo` bewaart de React Native prototypeversie als fallback/reference.
- Script `npm run godot:export:web` exporteert Godot naar `public/godot/void-drifter`.
- LCARS-neon UI richting is vastgelegd in `docs/project/void-drifter-ui-style-guide.md`.
- Luma UI reference assets staan in `godot/void-drifter/assets/ui/luma_reference/`.
- Godot HUD/start/death UI gebruikt LCARS-neon panels, meters, chips, scanlines en gestylede buttons.
- Godot HUD toont sector/wave/time/score bovenin en hull + compacte non-interactive weapon strip onderin; de wave-module toont tijdens Red Surge echte surge-status, terwijl sector/loadout nog presentatie-only zijn.
- Script `npm run godot:check` laadt de Godot scene headless en faalt op parse/load errors voordat web export wordt gestart.
- Lokale browser-verificatieafspraak is vastgelegd in `docs/dev/local-browser-testing.md` en `.agents/skills/local-browser-testing/SKILL.md`.

## Nog Niet Gedaan

- Boost en shield sprites zijn aanwezig als assets, maar nog niet gekoppeld omdat er geen boost/shield-trigger bestaat.
- Background asteroids zijn alleen visueel; geen collision/hazards.
- Geen player upgrades, XP, pickups, leveling of meta-progressie.
- Sector/loadout HUD is presentatie-only; er is nog geen echte sector progression, inventory, loadout selectie of weapon upgrade systeem.
- Enemy projectile gameplay is bewust minimaal: bestaande rechte kogelbaan, simpele cooldown, geen patroonvarianten per enemy type.
- Red Surge Waves zijn korte dopamine-events bovenop endless spawning, geen volledige wave-game met wave completion, boss, rewardskeuzes of run-lock.
- Expo/React Native fallback `/void-drifter-expo` heeft nog geen Red Surge parity.
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

- optie A: start `npm run web` en test `/void-drifter` visueel in de browser met de embedded Godot build
- optie B: visuele browsercheck van Enemy Codex navigatie en Fighter/Cruiser spawning rond runLevel 2/4
- optie C: eerste upgrade/shop screen pas plannen nadat de run visueel klopt
