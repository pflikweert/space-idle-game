# VOID DRIFTER — Complete Game Reference

> **Purpose.** This is the canonical, standalone description of the current VOID
> DRIFTER prototype. Upload the generated `docs/upload/chatgpt-project-context.md`
> to a ChatGPT Project when the project needs to understand the game without this
> repository. It describes the current working tree, including work that may not
> yet be committed.

## 1. What the game is

VOID DRIFTER is a local-first, web-playable survival/idle-defense prototype. The
player pilots a small upward-facing gunship through a dark space sector. They can
steer it, but it automatically aims and fires its Railgun at valid nearby targets.
The long-term loop is deliberately compact:

`steer or hold position → survive enemy waves → earn cash, coins, modules and Railgun XP → buy run upgrades or choose cards → end/retire a run → improve the next run`

It is a prototype, not a released game or a production service. There are no
accounts, backend, cloud sync, monetization, ads, analytics, multiplayer, offline
earnings, store-release work, audio content, or native mobile embedding. The
playable experience is Godot 4 exported for the web and embedded by an Expo web
route at `/void-drifter`. It is intended to be readable on desktop and touch web
viewports; the primary verification surface is the web build.

The visual language is original LCARS-inspired arcade UI: dark navy transparent
panels, cyan system/player information, magenta/purple progression and epic cards,
orange danger/boss emphasis, compact high-contrast text, and bright local combat
effects. It is inspiration only, not a Star Trek product or visual copy.

## 2. Player journey and controls

### Entering, starting and ending a run

- The Expo home screen links into `/void-drifter`; when the Godot web export is
  present, the route embeds it in an iframe. Without an export it shows the exact
  local export command instead of a React Native gameplay fallback.
- The Godot main menu offers **Start Run**, the Enemy Codex, the Workshop,
  Railgun information/upgrade screens, and developer-only controls. A new run
  starts with 30 cash, base stats plus permanent Workshop levels, a level-1
  Railgun, and a fresh card state.
- An unfinished run is serialized locally and resumes **paused**. Going to the
  browser background also pauses/saves the run. There is no simulation or income
  while it is closed.
- Player hull reaching zero ends the run. The result screen records the run once;
  explicit retirement has the same banking behavior. Duplicate settlement is
  guarded by a run id. Coins and boss modules are banked only at settlement;
  cash and temporary run upgrades disappear.

### Flight, targeting and combat speed

- Click/touch-drag sets the desired ship position. The ship moves smoothly inside
  a playfield that reserves room for the top HUD and bottom weapon strip. There
  are no keyboard controls.
- The player may hold position; manual steering temporarily overrides Auto-Dodge.
  Auto-Dodge becomes purchasable only after reaching wave 30 and spending 1,000
  coins. Once unlocked, its saved on/off toggle samples nine nearby destinations,
  avoids enemy bodies and projectile paths, and prefers staying still when safe.
- The saved speed setting cycles through **1x, 2x, 3x, 4x, 5x, and 10x**. It
  changes simulation speed, not the local persistence model. Visual timers freeze
  when paused.
- The game can be paused manually. Pause exposes resume, retirement, settings and
  navigation to run upgrades/Railgun build information. Card choice also freezes
  combat unless Auto Cards is enabled.

### Core player defenses

The player begins at these level-0 values: 140 hull, 30 shield, 0.5 hull
regeneration per second, 0.5 shield points per second, and no armor. Shield damage
is absorbed before hull damage. Any hit delays shield recharge by 3 seconds;
afterward the shield recharges up to its current capacity. Armor reduces incoming
damage by its percentage while preserving a positive minimum. A first collision
with an enemy deals twice its scaled contact damage; later collisions use that
enemy's normal contact cadence. Enemy projectiles use twice their calculated base
damage before armor.

The HUD distinguishes cyan shield absorption from warm hull damage, with local
impact effects, short damage numbers, screen shake when enabled, hull damage art,
and a proximity shield contour when enemies are nearby. Combat feedback is visual;
it does not add hidden damage systems.

## 3. Waves, enemies and rewards

### Wave director

Each wave lasts 35 simulation seconds: **26 seconds spawning** followed by **9
seconds cooldown** with no new normal spawns. Existing enemies and projectiles
continue during cooldown. Wave number is `1 + floor(elapsedSeconds / 35)`.

- Normal spawn interval: `max(0.45, 1.10 − 0.02 × (wave − 1))` seconds.
- At most 40 normal enemies and four bosses can exist. A blocked spawn attempt is
  discarded rather than queued.
- Active normal enemies are selected by the listed weights after their first wave.
  A Void Dreadnought is scheduled on every tenth wave.
- Hull and contact damage begin growing after wave 10. With `E = max(0, wave −
  10)`, each type uses its own base value times `1.115^min(E,25) ×
  1.025^min(max(E−25,0),10000)` for hull, and `1.14^min(E,25) ×
  1.01^min(max(E−25,0),10000)` for contact damage. Speed stays fixed.
- Spawns use saved random state, enter just outside a valid playfield edge, and
  retain a run-wide clockwise/counter-clockwise orbit choice. Active ships use
  inward spiral movement, velocity-facing hulls, short state hysteresis, and
  separation only where needed. Ranged ships hold an outer firing orbit before
  continuing inward.

Completing a wave grants `(10 + 2 × completedWave + CashPerWave) × CashBonus`
cash and `2 × CoinBonus` coins. Kills award the cash/coin values below, also
modified by the respective income bonuses. Fractional rewards accumulate while
the UI displays whole amounts.

### Active roster

All figures below are base values before wave scaling, player armor, or income
bonuses. **First impact** is two times contact damage. Enemy projectiles are
telegraphed; a rail/rocket description lists the source damage multiplier used by
the runtime before the universal projectile double-damage rule.

| Enemy | Starts | Weight | Hull | Speed | Contact / cadence | Kill reward | Behavior |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| Void Drone | wave 1 | 60 | 16 | 70 | 1 / 0.30s | 2 cash, 1 coin, 1 XP | Smallest, fastest inward spiral; one low-damage rail shot per 16s after 0.45s warning. |
| Red Scout | wave 3 | 20 | 12 | 59.5 | 1 / 0.45s | 4 cash, 2 coins, 2 XP | Fast inward passes; one low-damage rail shot per 20s after 0.35s warning while approaching. |
| Rift Shooter | wave 5 | 10 | 24 | 28 | 1 / 0.55s | 6 cash, 3 coins, 3 XP | Orbits near player range, then spirals in; three-round rail salvo, 6s reload, 0.3s warning. |
| Void Tank | wave 7 | 10 | 80 | 17.5 | 1 / 0.75s | 8 cash, 4 coins, 4 XP | Slow armored spiral; two-round rail salvo, 1s between rounds, 14s reload, 0.5s warning. |
| Void Dreadnought | waves 10, 20… | scheduled | 400 | 10 | 3 / 1.00s | 100 cash, 25 coins, 15 XP, modules | Boss spiral; guided rockets, one per 4s after 0.6s warning, maximum two live rockets per boss. |

The Dreadnought has a distinct large armored hull, named hull bar, animated
engines/core, staggered explosions and a central final blast. Normal ships use
fixed transparent movement canvases so direction or hit frames never shift their
gameplay pivot. Collisions use independently defined gameplay radii, not opaque
art bounds.

### Archived, non-spawning roster

The Codex also retains designs that currently **do not spawn**: Void Swarm (wave
3 design; 8 hull, 82 speed, 6 contact, 1 coin), Nova Dart (wave 5; 20 hull, 92
speed, 20 explosive contact, 4 coins), Split Core (wave 6; 44 hull, 36 speed, 14
contact, 6 coins), and Elite Hunter (wave 8; 130 hull, 54 speed, 28 contact, 16
coins). Their source art and registry entries are preserved as archive/reference
content, not enabled game features. Earlier Red Surge, elite modifiers, pickups,
and XP systems are likewise not part of the active loop.

## 4. Railgun, cards and upgrades

### Railgun

Railgun is the only live player weapon. It targets the nearest visible enemy whose
centre is within the current Range circle; shots cannot continue damaging enemies
outside the visible playable area. It fires at 1,600 units/second with thin
white/cyan traces, muzzle light, directed impacts, and up to two units of visual
recoil. It uses six rounds per magazine, fires every 0.5 seconds, and reloads for
3 seconds. Each projectile has a travel budget established at firing time. A
critical hit doubles its damage. Swept segment/circle collision finds intersections
in travel order; piercing shots stop only after their target limit.

The bottom HUD shows the illustrated Railgun card, level/stars, ammunition and a
full-card radial reload mask. Four adjacent equal-sized slots are intentionally
noninteractive placeholders: no other weapons, loadouts, or unlock rules exist.

### Railgun XP cards

Enemy kills award Railgun XP directly. First choice costs 160 XP; each next
threshold doubles (`160 × 2^choices`), with at most 25 choices. Choice numbers
4, 9, 16 and 25 are guaranteed epic offers; ordinary offers and epic offers each
draw three eligible cards without replacement. A manual offer pauses combat until
one card is selected and equipped. **Auto Cards** is a saved setting that chooses
a random card from the same offer, leaves combat running, and queues a small
noninteractive notification. It is off by default.

| Card | Kind | Unlock | Rank cap | Effect per rank |
| --- | --- | ---: | ---: | --- |
| Power Railgun | ordinary | Railgun 1 | unlimited | +20% damage |
| Quick Reload | ordinary | Railgun 1 | unlimited | reload ×0.90 |
| Extended Magazine | ordinary | Railgun 1 | unlimited | +1 round |
| Hyper-Piercer | epic | Railgun 1 | 4 | on kill, pierce +2 targets |
| Railgun Twin | epic | Railgun 1 | 4 | +1 projectile per shot |
| Overcharged Core | epic | Railgun 1 | 4 | +50% damage, +10% critical damage |
| Heavy Caliber | ordinary | Railgun 2 | 3 | +25% damage, +25% critical damage |
| Armor Shredder | ordinary | Railgun 6 | 3 | on kill, pierce +1 target |
| Critical Railgun | ordinary | Railgun 10 | 3 | +5% critical chance |
| Shatter Railgun | epic | Railgun 14 | 4 | first hit creates 2 aimed fragments at 50% damage |
| Railgun Rampage | epic | Railgun 18 | 4 | +15% damage per pierced enemy, maximum 5 steps |

Card damage multiplies the normal upgraded weapon damage. The complete derived
Railgun state is: reload `3 × 0.90^QuickReloadRank`; magazine `6 +
ExtendedMagazineRank`; projectiles `1 + TwinRank`; target count `1 + 2 ×
HyperPiercerRank + ArmorShredderRank`; critical chance adds 5% per Critical rank;
critical multiplier is `2 + 0.10 × CoreRank + 0.25 × CaliberRank`; Shatter creates
two fragments per rank; and Rampage adds 15% per preceding pierced hit, capped at
five steps.

### Run upgrades and Workshop upgrades

Run upgrades cost cash and reset when the run settles. Workshop upgrades cost
banked coins, apply to a run's starting level, and are unavailable while an
unfinished run exists. The same levels are added together; there is no separate
permanent multiplier. The shop groups upgrades into Attack, Defense and Utility,
and supports Buy 1 or Buy 10. Run purchase price is `ceil(10 × 1.10^level)`;
Workshop price is `ceil(25 × 1.18^level)`.

| Category | Upgrade | Value at total level L | Cap |
| --- | --- | --- | ---: |
| Attack | Damage | `8 × (1 + 0.15L)` | 500 |
| Attack | Fire Rate | `max(90ms, 500 / (1 + 41L/342))` | 38 |
| Attack | Critical Chance | `1% × L` (base 2× crit) | 50 |
| Attack | Range | `160 + 2L` units | 30 |
| Defense | Max Hull | `140 + 20L` | 500 |
| Defense | Hull Regeneration | `0.5 + 0.5L` HP/s | 100 |
| Defense | Shield Capacity | `30 + 10L` SP | 100 |
| Defense | Shield Recharge | `0.5 + 0.5L` SP/s | 60 |
| Defense | Armor | `2% × L` | 30 |
| Utility | Cash Bonus | `1 + 0.05L` multiplier | 100 |
| Utility | Cash per Wave | `5L` cash | 100 |
| Utility | Coin Bonus | `1 + 0.05L` multiplier | 100 |

Workshop reset is allowed only with no active run. It refunds tracked Workshop
spending, resets all Workshop levels and Auto-Dodge, preserves Railgun progress,
records and Codex history, and leaves the player able to choose the default
Auto-Dodge setting after the next unlock.

### Permanent Railgun levels

The Railgun begins at level 1 and can reach level 20. Every level increases base
Railgun damage: from level 2 onward, add `2 + floor((currentLevel−1)/3)` for each
purchased level before card multipliers and criticals. Each purchase requires both
coins and boss modules:

| Next level | Coins | Modules | Next level | Coins | Modules |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 1,000 | 10 | 12 | 65,000 | 1,900 |
| 3 | 2,500 | 50 | 13 | 75,000 | 2,250 |
| 4 | 5,000 | 150 | 14 | 90,000 | 2,700 |
| 5 | 10,000 | 300 | 15 | 105,000 | 3,150 |
| 6 | 15,000 | 450 | 16 | 125,000 | 3,700 |
| 7 | 25,000 | 700 | 17 | 140,000 | 4,200 |
| 8 | 30,000 | 900 | 18 | 160,000 | 4,800 |
| 9 | 40,000 | 1,200 | 19 | 180,000 | 5,400 |
| 10 | 50,000 | 1,500 | 20 | 205,000 | 6,100 |
| 11 | 65,000 | 1,900 | — | — | — |

## 5. Menus, information and persistence

### Interfaces

- **Run HUD:** top bands show portrait, hull/shield values, wave/time, cash/coins/
  modules, run level and XP. Compact controls provide Codex/overview, pause,
  speed, run shop, Railgun build and Auto-Dodge. The Railgun strip is at bottom.
- **Run Upgrades:** a paused cash shop with Attack, Defense and Utility tabs.
- **Workshop:** permanent coin upgrades, Buy 1/10, refund/reset, Auto-Dodge
  unlock, and an active-run lock.
- **Railgun screens:** upgrade roadmap, current/next stat preview, card catalogue,
  locked-card requirements and run build. They use scalable Godot controls plus
  supplied card art, not baked screenshots.
- **Enemy Codex:** available from Godot menus/results and as a secondary Expo
  `/void-drifter/enemies` reference route. It separates Active and Archive,
  orders current enemies by introduction wave, tracks discovery/lifetime kills in
  Godot, and reveals combat details after discovery. The Expo reference route does
  not read the Godot profile.
- **Developer controls:** local prototype-only actions can add coins/modules or
  reset every saved upgrade, currency, record, Codex entry, setting and active
  run. The destructive reset requires confirmation. This is not a player-facing
  production economy feature.

### Local profile

Data is local Godot JSON at `user://void_drifter_profile.json`; web exports use
Godot's browser filesystem persistence. The current save version is **5**. A
temporary write and `.bak` backup protect the last valid profile. The profile
stores coins, tracked Workshop spend, Railgun level/coins/modules/unlocks,
total kills, records, runs played, discovered enemies and per-enemy kills,
permanent upgrade levels, Auto-Dodge state, screen shake/Auto Cards/speed
settings, the current active-run snapshot, settlement id, last-run summary and
update timestamp.

Snapshots preserve run state, player state, temporary upgrades, enemies,
projectiles, card offer/RNG state, rewards and relevant visual/navigation state.
Old Pulse Cannon identifiers map to Railgun. Older profiles are sanitized and
migrated; legacy profiles before save version 3 receive the historical XP Gain
coin refund once, while old Railgun unlock thresholds are preserved through
explicit legacy unlock records. Save failure is surfaced with a retry action.

## 6. Presentation, content and technology

Godot owns gameplay, menus, HUD, local save data, sprites and effects under
`godot/void-drifter`. Expo Router owns route assembly and the iframe shell; the
TypeScript enemy registry supports the secondary Codex and mirrors gameplay data
for reference. There is intentionally no shared runtime between TypeScript and
GDScript.

The environment layers sector backgrounds, distant parallax, midfield haze,
gameplay, restrained foreground overlays, HUD and modals in that order. Combat
keeps the centre dark and uncluttered: one soft nebula/stars, local rail traces,
short cyan/white pulses, orange/red enemy fire, eight-frame transparent explosions,
small debris, enemy hull feedback and no large opaque UI over the playfield.

Player/enemy source sheets live under `assets/game`; Godot mirrors runtime assets
under `godot/void-drifter/assets`. Gameplay movement uses fixed transparent
`frames-cell` canvases for stable pivots; `preview.png` is for Codex cards;
tightly cropped frames are VFX/debug-only. Runtime uses committed local art only;
there is no live ImageGen/Luma/API asset generation.

## 7. Boundaries and maintenance

Not implemented: other playable weapons, real loadouts/inventory, sector travel
or procedural universe generation, final balance, rerolls/banish/synergies,
additional active enemy archetypes, audio/music, settings/accessibility polish,
keyboard input, native mobile Godot embedding, online services, and any
commercial/live-ops system.

For local work, install dependencies, ensure Godot 4 with Web export templates is
available, then run:

```bash
npm run godot:check
npm run godot:export:web
npm run web
```

Use `npm run lint` and `npm run typecheck` for the Expo layer. Build this upload
file with `npm run docs:upload` and check it with `npm run docs:bundle:verify`.

**Documentation maintenance rule:** runtime GDScript and TypeScript are the
source of truth for implemented behavior and numeric values. Update this dossier
in the same change as any player-visible gameplay, progression, content, UI or
platform change; then regenerate the upload artifact. Do not restore QA reports
or historical implementation logs to the upload bundle.
