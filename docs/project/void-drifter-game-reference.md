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

`steer or hold position → survive enemy waves → earn cash, coins and modules → buy run upgrades or improve modules → end/retire a run → improve the next run`

It is a prototype, not a released game or a production service. There are no
accounts, backend, cloud sync, monetization, ads, analytics, multiplayer, offline
earnings, store-release work, or audio content. The playable experience is Godot
4 exported for the web and embedded by an Expo web route at `/void-drifter`, with
an Android debug build for device testing. Native mobile uses the device sensor
orientation and scales command-deck menus, HUD controls, and combat visuals to
the safe viewport; the primary verification surface remains the web build.

The visual language is original LCARS-inspired arcade UI: dark navy transparent
panels, cyan system/player information, magenta/purple progression and module milestones,
orange danger/boss emphasis, compact high-contrast text, and bright local combat
effects. Menus share a reusable command-deck backdrop, elevated header treatment,
bevelled action controls and a common navigation-icon set; screen-specific views
add content rather than inventing their own UI chrome. It is inspiration only, not
a Star Trek product or visual copy.

## 2. Player journey and controls

### Entering, starting and ending a run

- The Expo home screen links into `/void-drifter`; when the Godot web export is
  present, the route embeds it in an iframe. Without an export it shows the exact
  local export command instead of a React Native gameplay fallback.
- The Godot main menu offers **Start Run**, **Hangar**, Enemy Codex, Settings,
  and developer-only controls. Hangar contains loadout, individual equipment
  progression and permanent Ship Systems. A new run starts with 30 cash, base
  stats plus permanent Ship Systems levels, a level-1
  Railgun and a fresh run-module counter.
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
  navigation to run upgrades/Railgun build information. Run upgrades are temporary;
  Workshop upgrades are permanent account progression.

### Core player defenses

The starter ship blueprint provides these level-0 chassis values: 140 hull, 0.5 hull
regeneration per second, and no armor. Shield capacity and recharge come from the
equipped Shield Core, not from the chassis. Shield damage
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
the runtime before the universal projectile double-damage rule. Enemy rail shots
and guided rockets reuse the player's smooth sampled-path presentation with thin
tapered glow/core trails and clear projectile heads, tinted subtly red/orange to
remain immediately distinguishable. Enemy muzzle and rocket-impact feedback use
the same compact visual language without changing projectile behavior.

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

### Damage types and enemy interactions

The data model supports the damage type IDs `kinetic`, `electricity`, `explosive`,
`plasma` and `beam`. Weapon family and damage type remain separate: family selects
shared weapon behaviour, while damage type selects enemy interactions. Railgun is
`family = railgun` and `damage_type = kinetic`.

Enemy blueprints expose `resistances`, `weaknesses` and reserved `immunities` as
explicit `{target_kind, target_id, multiplier}` entries. The runtime resolves
damage in one fixed order: resolved weapon damage × family modifier × damage-type
modifier. Modifiers clamp to `0.5..1.5`; direct damage never reaches zero through
an immunity entry, and conflicting resistance/weakness entries resolve safely to
neutral. Missing or unknown entries use `1.0`. Immunities currently reserve
secondary effects and do not add stun, slow, burning or chain reactions.

The current active enemy roster has empty interaction arrays, so kinetic Railgun
damage, rewards, armor and shield behavior remain unchanged. Synthetic resistance,
weakness, beam, swarm and immunity fixtures exist only in automated tests; no new
player weapon families or player-facing resistance counter-builds are shipped yet.

### Archived, non-spawning roster

The Codex also retains designs that currently **do not spawn**: Void Swarm (wave
3 design; 8 hull, 82 speed, 6 contact, 1 coin), Nova Dart (wave 5; 20 hull, 92
speed, 20 explosive contact, 4 coins), Split Core (wave 6; 44 hull, 36 speed, 14
contact, 6 coins), and Elite Hunter (wave 8; 130 hull, 54 speed, 28 contact, 16
coins). Their source art and registry entries are preserved as archive/reference
content, not enabled game features. Earlier Red Surge, elite modifiers, pickups,
and XP systems are likewise not part of the active loop.

## 4. Railgun and upgrades

### Railgun

Railgun is the only live player weapon. It targets the nearest visible enemy whose
centre is within the current Range circle; shots cannot continue damaging enemies
outside the visible playable area. It fires at 1,600 units/second with long,
thin tapered cyan/white energy traces, a distinct white projectile tip, compact
muzzle light, directed impacts, and up to two units of visual recoil. All Railgun
instances share this presentation, so simultaneous fire remains readable. It uses
six rounds per magazine, fires every 0.5 seconds, and reloads for
3 seconds. Each projectile has a travel budget established at firing time. A
critical hit doubles its damage. Each shot stays locked to its live, visible target
and corrects its heading as that enemy moves, so a valid Railgun shot cannot miss.
Swept segment/circle collision finds intersections in travel order; piercing shots
stop only after their target limit.

The bottom HUD shows the active Railgun instance with a dedicated
high-detail Railgun portrait matching the Micro Missile Rack slot style,
level/stars, ammunition and a full-card radial reload mask. This HUD portrait is
independent from the unchanged Railgun card artwork. Four adjacent equal-sized slots remain
noninteractive placeholders in this milestone; multi-weapon combat is not yet
implemented.

### Hangar and loadout architecture

The current ship is the data-driven `starter_ship` blueprint. It owns its base
stats, Hangar/combat art references, four weapon hardpoints and two system
hardpoints, normalized hardpoint anchors, per-slot equipment compatibility,
future utility/system caps, and explicit active-weapon/family caps. The global
design ceiling remains `MAX_ACTIVE_WEAPON_FAMILIES = 5`; the starter currently
uses a ship cap of four because it has four physical weapon hardpoints.

Equipment is independent of ships. The current profile owns two stable instances:
`railgun-001` and `shield-core-001`. The starter ship loadout references
those instances from W1 and S1; W2–W4 and S2 are empty. Inventory contains all
owned instance ids and reserve is derived from the instances not referenced by
the selected ship loadout. Validation rejects unknown instances, incompatible
equipment types and the same instance in more than one hardpoint.

Active-loadout validation is centralized and data-driven. A loadout may contain at
most `MAX_ACTIVE_WEAPONS = 5` weapons and at most
`MAX_ACTIVE_WEAPON_FAMILIES = 5` families, further reduced by the active ship's
caps and the number of compatible weapon hardpoints. Multiple instances from one
family are allowed; reserve, system and utility items do not count. Validation is
applied on installation, profile sanitization/save and active-run snapshotting.
Architecture-only assault, support and specialist ship fixtures exercise larger
hardpoint counts and lower caps; they are not registered as playable ships.

During a run, the validated active loadout is frozen into a generic runtime map
with one independent ammo, reload timer, fire timer, target and hardpoint anchor
per active weapon instance. Multiple Railgun instances can therefore fire
independently, while reserve items receive no runtime state. Active-run
snapshots use version 3 and persist the complete weapon runtime map for pause,
background and resume. The mobile weapon strip renders only the active instances,
up to five modules with no pagination. There is no random card layer in combat.
Every equipped weapon resolves its base damage from the current effective Ship
Attack and its own module coefficient: Railgun uses `effectiveShipAttack × 1.0`,
while Micro Missile Rack uses `effectiveShipAttack × 1.3 + 2.0 × (level - 1)`.
Module level multipliers and milestones apply afterward. Enemy resistances and additional
player-facing weapon families remain out of scope.

Hangar is a mobile-first flow: the Overview shows the active ship, its actually
mounted equipment, core stats and navigation. The starter presentation is an
original dark-navy modular gunship with four physical weapon cradles (W1–W4) and
two equal circular system bays (S1–S2) on its centreline. Compact cyan/purple
slot badges remain visible on the Hangar hull; equipped weapon and system mount
art is drawn at those shared blueprint anchors in both Hangar and combat. Every
hardpoint also declares its physical mount bounds, so installed art fills its
cradle without per-slot render exceptions. Every weapon first places a complete
armoured socket cover: railguns add a separately pivoted head which tracks their
combat target, while the Missile Rack adds a fixed, cradle-filling payload. The
Shield Core is centred and sized from the same circular S1 geometry. Hangar labels are
deliberately subdued and all installed modules have a quiet idle pulse. In combat,
actual rail shots and missile launches trigger short mount feedback, the Shield
Core reacts to shield impact, and the registered engine nozzles render a stronger
cyan plume while the ship moves. The Shield Core mounts in S1 and its hexagonal
contour derives its size from the active ship presentation, while its shield
mechanics remain unchanged. The Overview stat console shows
HULL, SHIELD, DAMAGE and ARMOR using permanent Workshop values only; its five
bar segments are continuously filled from each Workshop level divided by that
upgrade's cap. Shield reads zero when the Shield Core is not equipped. Loadout is
a ship-art-free W1–W4 /
S1–S2 grid of reusable equipment bays with dedicated loadout art. Empty bays use
neutral dark steel, while installed equipment uses its rarity colour (normal
cyan-steel, advanced blue, epic violet and legendary amber). Selecting installed
equipment keeps the player on Loadout and opens a compact selection panel below
the bays. This panel has a **Details** action only: it never spends resources or
removes equipment directly. Details opens the selected instance's full
progression screen, showing its existing art, current-versus-next-level stats,
available milestones and the explicit Upgrade / Unequip controls. Each installed
module also has a small in-context enabled switch; it can be toggled from Loadout
while a run is paused, immediately rebuilding the active run's weapon/system
runtime without removing the module. Its stat
comparison is a single framed, scan-friendly table: each
row pairs a stat icon and bold label with **Current**, a cyan double-chevron and
the **Next Level** value. A changed next value is green; an unchanged value stays
neutral light grey. Blueprint Detail is a repeatable build screen
with level-one preview, costs and owned count, while upgrades are only shown from
a specific equipment instance in its full detail screen. That full screen's amber Upgrade control always shows the exact
next Credits and Boss Modules cost; it switches to a visibly muted, disabled
variant when the item is capped, the player cannot afford either currency, or a
run locks Hangar changes;
and Ship Systems owns the former Workshop. Empty slots show only compatible,
valid reserve items, and built equipment is never installed automatically. During
an active run this flow remains readable but all mutations are locked. The
underlying hardpoint data remains blueprint-driven rather than assuming W1–W4/S1–S2
in the implementation. An unlocked, unbuilt Blueprint Detail shows a level-one
stat preview, exact owned/required Credits and Boss Modules, and the remaining
shortfall. Build is disabled until both currencies are affordable and no run is
active. A successful build creates the next numbered reserve instance, keeps the
blueprint selected, and immediately offers another build when the player can afford
one. The starter ship owns one Railgun instance, `railgun-001`, installed in W1.
The Railgun blueprint is the same equipment definition and builds additional
identical instances for 5,000 coins and 2 boss modules: `railgun-002`,
`railgun-003` and so on, up to the ship's active-copy limit. New copies remain in
reserve until installed in a compatible weapon hardpoint. Each instance has its
own level, upgrade costs and milestone progression, while all copies use the same
Railgun stats and presentation. Legacy Starter/Auxiliary IDs are accepted only
during profile migration and are never exposed by the runtime or UI. Costs remain
data-driven provisional balance values pending real wave/module economy testing.
The starter Shield Core remains protected by the existing loadout rules. Extra
playable ships, mastery UI and enemy resistance gameplay remain out of scope.

### Railgun module milestones

The Railgun has no random card draft, card XP, card catalogue or Auto Cards
setting. Its permanent level determines base damage and predictable milestones.

| Level | Permanent effect |
| ---: | --- |
| 5 | Normal — Heavy Caliber: +60% bullet damage and +5 percentage points critical chance |
| 10 | Normal — Split Fire: +1 bullet, −20% damage per bullet |
| 15 | Normal — Shatter Railgun: first hit splits into 2 small bullets at 50% damage each |
| 20 | Epic — Void Burst: 50% damage explosion on primary hit, 42-unit radius |
| 25 | Normal — Phase Penetrator: 30% faster reload |
| 30 | Normal — Deep Penetrator: +2 penetration |
| 35 | Normal — Rampage Matrix: +20% damage per penetration, capped at +100% |
| 40 | Epic — Twin Rampage Core: +2 bullets, +30% Void Burst damage and +30% Void Burst radius |

Equipment instances persist a rarity, XP and milestone state. The shared roadmap
is Common levels 1–40, Rare 41–80, Epic 81–120 and Legendary 121–160. Later
rarity promotion is intentionally staged rather than active content.

Shatter Railgun creates exactly two small, impact-only railgun bullets on the
first primary hit; each inherits 50% of the resolved hit damage and can hit one
additional enemy. Void Burst uses the same baseline as the missile payload:
50% of resolved bullet damage and a 42-unit radius. Twin Rampage Core multiplies
only those Void Burst values by 1.30; it does not increase Rampage. Phase
Penetrator multiplies the weapon magazine reload time by 0.70, while fire
interval remains owned by the Railgun's normal level curve.

### Run upgrades and Workshop upgrades

Run upgrades cost cash and reset when the run settles. Workshop upgrades cost
banked coins and are unavailable while an unfinished run exists. Both layers use
the same multiplier contract but are tracked separately: permanent Workshop
levels multiply the ship/module baseline and temporary Run levels multiply the
same effective layer during a run. The shop groups upgrades into Attack, Defense
and Utility, and supports Buy 1 or Buy 10. Run purchase price is
`ceil(8 × 1.08^level)`; Workshop price is `ceil(20 × 1.12^level)`.
Each completed wave also grants `10 + 2×completedWave + cashWaveBonus`, then
applies the Cash Bonus multiplier. Bosses continue to award a fixed 2 Boss
Modules; the module cost curve, rather than escalating boss rewards, controls
long-term module progression.

| Category | Upgrade | Value at total level L | Cap |
| --- | --- | --- | ---: |
| Attack | Ship Attack | `shipAttackBase × (1 + 0.06L)` | 100 |
| Attack | Critical Chance | `shipCritBase + 1% × L` | 50 |
| Attack | Range | `chassisRange + 3L` units | 30 |
| Defense | Hull | `chassisHull × (1 + 0.06L)` | 100 |
| Defense | Hull Regeneration | `chassisRegen × (1 + 0.06L)` HP/s | 100 |
| Defense | Shield Capacity | `shieldCoreCapacity × (1 + 0.05L)` SP | 100 |
| Defense | Shield Recharge | `shieldCoreRecharge × (1 + 0.05L)` SP/s | 100 |
| Defense | Armor | `2.5% × L` | 30 |
| Utility | Cash Bonus | `1 + 0.05L` multiplier | 100 |
| Utility | Cash per Wave | `7.5L` cash | 100 |
| Utility | Coin Bonus | `1 + 0.05L` multiplier | 100 |

Fire Rate is intentionally absent from Workshop. Fire Rate, reload and magazine
belong to each weapon module. Targeting Range remains a ship sensor stat, while
weapons may add a module-specific range bonus. Workshop has no zero-based absolute
values; the UI shows each multiplier and the resulting effective value. If no
Shield Core is equipped, shield Workshop rows show `NO MODULE`.

#### Stat ownership contract

Keep this layering when adding ships or equipment:

```text
effective chassis stat = ship chassis base × Workshop multiplier × Run multiplier
effective shield       = Shield Core output × Workshop multiplier × Run multiplier
effective weapon damage = effective Ship Attack × weapon coefficient
                          × module-level multiplier × module milestones
critical chance         = shipCritBase + Workshop/run Critical Chance levels
weapon fire interval   = weapon module interval at its level
```

The chassis owns hull, regeneration, armor, base attack, critical chance and targeting range.
Every active weapon receives the ship's effective Critical Chance; a weapon may
still define its own critical multiplier or milestone modifier. The
Shield Core is the only source of shield capacity and recharge. A weapon owns
damage coefficient, fire interval, magazine, reload, projectile range and its
own level/milestones. Percentage-point stats such as armor and critical chance
remain additive; missing ship base stats resolve to zero and never receive a
hidden fallback baseline. Multiplier stats never use zero as their base value. The UI
must label raw ship/module values as `Base`, calculated output as `Effective`,
and show `NO MODULE` instead of a misleading zero when a required module is absent.

Workshop reset is allowed only with no active run. It refunds tracked Workshop
spending, resets all Workshop levels and Auto-Dodge, preserves Railgun progress,
records and Codex history, and leaves the player able to choose the default
Auto-Dodge setting after the next unlock.

### Permanent Railgun levels

The Railgun begins at level 1. Its module level applies a predictable `+2.5%`
damage multiplier per level after level 1; milestones then add their deterministic
effects. The next-level cost is `800 + 300×(L−1) + 35×(L−1)^2` coins and
`L + 1` Boss Modules, where `L` is the current level. Railgun
copies and the original starter Railgun use this exact same blueprint and
progression; there is no separate Auxiliary Railgun.

### Ship chassis levels

Each ship has its own Chassis Bay progression from level 0 to 40. Chassis
upgrades change the ship baseline before Workshop and run multipliers are
applied: `+8` hull, `+0.04` hull regeneration, `+0.3` percentage points armor
and `+0.5` base attack per level. Movement speed is a fixed ship characteristic,
not a chassis upgrade. The next chassis level costs
`750 + 300×L + 60×L²` coins, where `L` is the current chassis level. This
keeps future ships distinct through their base stats, slots and characteristics
without making Workshop own ship identity.

### Shield Core and module upgrade costs

Shield capacity and recharge originate only from the equipped Shield Core.
Each module level adds `+2.5` capacity and `+0.06` recharge per second before
milestones. Workshop and run upgrades multiply those module outputs; without an
equipped Shield Core the UI reports `NO MODULE` rather than a fake zero-valued
module. Shield Core upgrades cost `500 + 300×(L−1) + 40×(L−1)^2` coins and
`L + 1` Boss Modules.

Micro Missile Rack upgrades use `600 + 300×(L−1) + 35×(L−1)^2` coins and
`L + 1` Boss Modules. Micro Missile Rack damage is `effectiveShipAttack × 1.3` plus
`2.0` flat damage per level above 1. Fire interval, reload, magazine and
projectile range remain weapon-owned stats and are never Workshop stats. Its
baseline payload is impact damage plus 50% explosion damage in a 42-unit radius;
the missile milestones are:

| Level | Permanent effect |
| ---: | --- |
| 5 | Normal — Power Missile: +60% impact and explosion damage |
| 10 | Normal — Missile Volley: +3 missiles, −20% damage per missile |
| 15 | Normal — Blast Amplifier: +30% radius and explosion damage |
| 20 | Epic — Enhanced Missile: 30% chance for a ×3 Super Missile with +20% radius |
| 25 | Normal — Splinter Missiles: 2 impact-only splinters at 25% damage |
| 30 | Normal — Impact Burst: small missiles have 30% chance to explode on impact |
| 35 | Normal — Shatter Strike Core: missile bursts into 4 impact fragments at 25% damage |
| 40 | Epic — Echo Detonation: Super Missiles trigger a second explosion at 60% explosion damage and 150% radius |

## 5. Menus, information and persistence

### Interfaces

- **Run HUD:** the LCARS-inspired header shows the current sector (currently
  fixed to sector 1), wave number with progress bar, elapsed game time and
  cash/coins/modules with icon assets. Hull and shield use stacked capsule bars
  above the unchanged bottom weapon strip. Pause, speed, run shop, Railgun build
  and Auto-Dodge controls are arranged in a floating, vertically
  centred right command rail that does not narrow or shift the header/footer;
  the centre wave readout remains the Wave Intel touch target. The header has
  no enclosing border so menus/popups can layer over it cleanly.
- **Run Upgrades:** a paused cash shop with Attack, Defense and Utility tabs.
- **Ship Systems:** permanent coin upgrades, Buy 1/10, refund/reset, Auto-Dodge
  unlock, and an active-run lock; reached through Hangar.
- **Hangar:** a mobile-first ship overview with separate Loadout, Blueprint and
  equipment-detail screens. Its real Godot controls are generated from the active
  ship blueprint, loadout and reserve inventory.
- **Railgun screens:** upgrade roadmap, current/next stat preview, module
  milestones and loadout/build controls. They use scalable Godot controls, not
  baked screenshots.
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
Godot's browser filesystem persistence. The current save version is **11**. Version
8 added item-local rarity, XP and milestone state. Version 9 removes legacy card
state. Version 10 moves permanent shield capacity and recharge into the Shield Core,
preserving legacy Workshop investment as a module-local bonus. Version 11 removes
permanent Workshop Fire Rate, makes Workshop rows multiplier-only, and converts
legacy active-run card module currency into the run module counter.

### Progression ownership

- **Workshop** remains account-wide and supplies multipliers for Ship Attack, Hull,
  regeneration and Shield Core output. It does not own weapon fire rate.
- **Chassis Bay** upgrades each ship independently from level 0 to 40. Chassis
  levels raise that hull's durability, recovery, armor and base attack without changing
  its installed modules or slots.
- **Modules** own their rarity and levels. The Railgun and Shield Core begin as
  Common modules (level 1–40), then require a matching rarity blueprint to advance.
  The Shield Core grants capacity, recharge and recharge-delay milestones at levels
  5, 10, 15 and 20.
state; an unfinished legacy run banks unbanked boss modules from its legacy card
payload, but no card choices are restored. Versions 7–9 preserve the canonical
`railgun`/`railgun-001` identifiers, progression,
loadout and active-run state.
A temporary write and same-version `.bak` backup protect the last valid current
profile.

The profile stores currencies and progression records, unlocked ship ids, the
active ship id, per-ship loadout/upgrade/mastery containers, equipment instances,
inventory ids, Workshop levels, settings, active-run snapshot, settlement id and
last-run summary. The permanent Railgun level and its coin/module spend belong to
that equipment instance; boss modules remain global currency.

Version-2 active-run snapshots preserve the active ship id and combat loadout in
addition to run/player state, temporary upgrades, enemies, projectiles, rewards and
relevant visual/navigation state. Old snapshot
versions are not restored. Save failure is surfaced with a retry action.

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

### Shared command-deck visual system

Godot menu surfaces consume `scripts/systems/ui_design_system.gd` for the Oxanium
font variations, typography roles, surface colours, rarity accents, clipped-corner
panels, button states, and empty/disabled contrast. Screen scripts retain their
navigation and data logic but use these shared helpers for presentation.

The visual contract is dark navy command-deck surfaces, restrained technical grid
texture, bold Oxanium display text, cyan active equipment, blue advanced equipment,
violet epic equipment, gold upgrade emphasis, and steel-gray empty/unavailable
states. Equipment frames are clean and reusable; legacy white side strips and
decorative lines must not return. Existing weapon and system artwork is reused
across hangar, loadout, blueprint, detail, and gameplay surfaces. A new screen
should add content through the shared tokens instead of introducing local colours,
fonts, frames, or button treatments.

## 7. Phase 11 explosive vertical slice

The active roster includes one data-driven `armored_drone` from wave 4 onward.
It has 36 hull, speed 38, contact damage 2 at 0.55s cadence, and rewards 5 cash,
3 coins, 3 Railgun XP and 36 score. Kinetic damage is multiplied by 0.75 and
explosive damage by 1.25; other damage types remain neutral.

`micro_missile_rack` is a Normal `explosive` weapon with instance
`micro-missile-rack-001`. Its base damage is
`shipDamage × 1.3 + 2.0 × (level - 1)`, with a 1.4s interval, three-rocket salvo,
magazine 3, 4.0s reload, range 200 (40 more than the standard Railgun) and
projectile speed 210. Its level cap is 40 with milestones at levels 5, 10, 15,
20, 25, 30, 35 and 40. The blueprint unlocks when a settled run contains an
Armored Drone kill; building costs 2,000 coins and does not install the item.
Missiles universally inherit the ship's Critical Chance. Every missile has an
impact payload and an area explosion; the level milestones add super missiles,
splinters, impact bursts, fragments and Echo Detonation as described above.
Echo Detonation is allowed to hit the same enemy again and does not recursively
spawn further missiles, fragments or Echo detonations. A
salvo uses fixed left/middle/right lanes but staggers its rockets by
0.075 seconds, with a short straight boost before homing. Missiles use an 8.0
rad/s turn limit. Their original blue/cyan trail uses densely sampled path
history with visual-only curve interpolation, a narrow tapered glow, bright core,
warm amber launch/exhaust and a clearly visible white missile head. Every impact ends the
missile, whether or not it kills. If its target dies before impact, the missile
retargets the nearest visible live enemy inside its remaining flight zone and
curves the correction over its next 42 flight units (up to a 90-degree change).
With no target, it keeps its course until its flight budget expires.

The missile's target range is its own range plus combined permanent Workshop and
temporary run Range upgrades. Its maximum total flight distance is that current
range plus 400 units, so missile-specific range levels and purchased range both
extend the flight zone.

## 8. Boundaries and maintenance

Not implemented: other playable weapon families, splash/status effects, sector travel
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
