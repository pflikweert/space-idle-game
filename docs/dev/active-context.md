# Active Context

- status: first playable Godot web prototype exists with transparent fixed-canvas enemy roster, local profile persistence, and temporary weapon boosts
- huidige focus: VOID DRIFTER Core Fun
- route: `/void-drifter`
- entry vanaf home: `Open VOID DRIFTER`
- laatste verificatie: `npm run typecheck`, `npm run lint`, `npm run godot:check`, `npm run godot:export:web` en `npm run docs:upload` groen; `curl -I` smoke checks op `localhost:8082/void-drifter` en `/void-drifter/enemies` geven 200, `/void-drifter-expo` geeft 404
- runtime status: VOID DRIFTER gameplay runs in Godot; TypeScript is shell/Codex data only
- Godot status: eerste Godot 4.x MVP-port staat in `godot/void-drifter` en `/void-drifter` embedt de Godot web-export zodra die lokaal is gebouwd
- enemy status: Enemy Asset Pack v2 is opnieuw uit de aangeleverde 1536x1024 sheets gesneden; Red Scout Drone, Red Fighter en Red Cruiser zijn active data-driven enemies met run-level gated weighted spawning
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
- Red Scout Drone, Red Fighter en Red Cruiser gebruiken Enemy Asset Pack v2 fixed 384x512 `frames-cell` gameplay sprites: idle/thrust/attack/hit per richting, transparante PNGs en shared enemy death VFX.
- Enemy frames worden met `scripts/godot/extract-void-drifter-enemies.gd` opnieuw uit de source sheets gegenereerd; de extractor centreert alpha-content op vaste canvases en maakt per enemy een aparte `preview.png` voor de Codex.
- Enemy Codex previews gebruiken `preview.png`; gameplay gebruikt fixed `frames-cell` canvases. Gebruik `frames-tight` niet als gameplay-anchor en alleen nog voor VFX/debug na alpha/bounds-checks.
- Godot run heeft een visual clarity pass: plasma bolt trails, subtiele enemy aura/outline, velocity-based richtingframes met hysteresis, korte hit-state als flash/spark overlay, event-based attack warmup als telegraph/FX, HP feedback, rustige death burst + debris en shield-impact feedback bij player contact damage.
- Overige VFX sprites staan alvast import-ready klaar: player laser beam, enemy red bullet, enemy purple shot, shield impact en level-up burst.
- Script `scripts/godot/extract-void-drifter-sheets.gd` snijdt de player/VFX sheets opnieuw uit.
- Click/touch-drag movement: ship vliegt smooth naar target.
- Red enemies spawnen vanaf randen en bewegen naar de actuele player positie.
- Red enemies gebruiken een rustige event-based attack warmup/projectile loop; hit en attack wisselen niet naar onbetrouwbare combat/death-looking primary sprites. Contact damage blijft daarnaast bestaan.
- Red Surge Waves zijn Godot-first gebouwd: elke 12 kills start een korte bonus-surge met 5-9 red hostiles, tijdelijke pauze op normale spawning, edge/layer breach VFX, bonus score en `RED SURGE` / `SURGE CLEARED` feedback.
- Enemy registry toegevoegd in Expo/TypeScript voor Enemy Codex data; Godot spiegelt de gameplay-definities.
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
- Godot 4.x project met `project.godot`, `scenes/main.tscn`, GDScript gameplay loop en gekopieerde bestaande player/background assets.
- Godot-port bevat dezelfde Core Fun: start, movement, enemies, auto-shooting, collisions, HP/kills/time HUD, death en restart.
- Expo route `/void-drifter` is nu de Godot embed shell.
- `/void-drifter` startscherm-regressie is gefixt: het Godot script parse't weer, `Start Run` koppelt opnieuw aan de run-state, `Restart` is niet zichtbaar op ready, en de `Enemy Codex` entry zit in de Godot start/death-flow in plaats van als losse Expo iframe-overlay.
- Script `npm run godot:export:web` exporteert Godot naar `public/godot/void-drifter`.
- LCARS-neon UI richting is vastgelegd in `docs/project/void-drifter-ui-style-guide.md`.
- Luma UI reference assets staan in `godot/void-drifter/assets/ui/luma_reference/`.
- Godot HUD/start/death UI gebruikt LCARS-neon panels, meters, chips, scanlines en gestylede buttons.
- Godot HUD toont sector/wave/time/score bovenin en een responsive bottom HUD met hull + plasma weapon boost/charge status; de wave-module toont tijdens Red Surge echte surge-status, terwijl sector/loadout nog presentatie-only zijn.
- Godot player clamp houdt nu rekening met de gereserveerde bottom HUD-ruimte op korte/mobile viewports.
- Persistent local profile toegevoegd via `user://void_drifter_profile.json`: lifetime score/kills, total runs, best score/time/wave/surge, highest weapon level en last-run summary.
- In-run main weapon upgrades toegevoegd als automatische tijdelijke plasma boosts op basis van kill-charge: level 2 sneller/sterker, level 3 twin-shot, level 4 triple/sterker.
- Script `npm run godot:check` laadt de Godot scene headless en faalt op parse/load errors voordat web export wordt gestart.
- Lokale browser-verificatieafspraak is vastgelegd in `docs/dev/local-browser-testing.md` en `.agents/skills/local-browser-testing/SKILL.md`.

## Nog Niet Gedaan

- Boost en shield sprites zijn aanwezig als assets, maar nog niet gekoppeld omdat er geen boost/shield-trigger bestaat.
- Background asteroids zijn alleen visueel; geen collision/hazards.
- Geen XP, pickups, leveling, shop, inventory of reward-choice systeem.
- Sector/loadout HUD is presentatie-only; er is nog geen echte sector progression, inventory of loadout selectie.
- Enemy projectile gameplay is bewust minimaal: bestaande rechte kogelbaan, simpele cooldown, geen patroonvarianten per enemy type.
- Red Surge Waves zijn korte dopamine-events bovenop endless spawning, geen volledige wave-game met wave completion, boss, rewardskeuzes of run-lock.
- Geen React Native gameplay fallback meer; VOID DRIFTER gameplay is Godot-only.
- Geen keyboard controls.
- Geen audio, screen shake, pause, settings of accessibility pass.
- Geen upgrade/shop UI implementatie; Luma upgrade mockup is alleen referentie.
- Geen backend, accounts, analytics of store/live-ops werk; persistence is alleen lokale Godot profile JSON.
- Geen gecommit Godot web-export output; `public/godot/void-drifter` is lokaal/generated.
- Geen native mobile Godot-in-Expo integratie; de integratie is web-first via Expo route + Godot HTML export.
- Geen gedeelde runtime tussen Expo TypeScript en Godot GDScript; dit is een eerste port naast de bestaande webversie.
- Geen externe ECS-framework.

## Volgende Kleine Stap

Maak de volgende Core Fun stap klein en toetsbaar:

- optie A: start `npm run web` en test `/void-drifter` visueel in de browser met de embedded Godot build
- optie B: visuele browsercheck van Enemy Codex previews en Fighter/Cruiser spawning rond runLevel 2/4
- optie C: tune tijdelijke plasma boost thresholds/durations nadat de run visueel klopt
