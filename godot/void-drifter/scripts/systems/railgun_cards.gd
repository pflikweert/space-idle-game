extends RefCounted

const Upgrades := preload("res://scripts/systems/upgrade_registry.gd")
const MAX_LEVEL := 20
const FIRST_LEVEL_DAMAGE_GAIN := 2
const DAMAGE_STEP_EVERY := 3
# Index zero purchases Lv.1 -> Lv.2. No purchase exists at MAX_LEVEL.
const LEVEL_PRICES := [
	[1000,10], [2500,50], [5000,150], [10000,300],
	[15000,450], [25000,700], [30000,900], [40000,1200],
	[50000,1500], [65000,1900], [75000,2250], [90000,2700],
	[105000,3150], [125000,3700], [140000,4200], [160000,4800],
	[180000,5400], [205000,6100], [225000,6750],
]

const VERSION := 5
const FIRST_CHOICE_XP := 160
const XP_LEVEL_GROWTH := 2.0
const MAX_CHOICES := 25
const MAX_EXTRA_PRIMARY_PROJECTILES_PER_INSTANCE := 2
const MAX_PRIMARY_PROJECTILES_PER_INSTANCE_VOLLEY := 3
const MAX_SHATTER_FRAGMENTS_PER_PRIMARY := 4
const MAX_SHATTER_FRAGMENTS_PER_INSTANCE_VOLLEY := 8
const MAX_TOTAL_PROJECTILES_PER_INSTANCE_VOLLEY := 11
const MAX_PIERCE_TARGETS_PER_PROJECTILE := 7
const MAX_EXTRA_MAGAZINE := 10
const MIN_RELOAD_FACTOR := 0.35
const MIN_RELOAD_SECONDS := 0.8
const MAX_CRITICAL_CHANCE := 1.0
const MAX_RAMPAGE_STEPS := 5
const EPIC_CHOICES := [4, 9, 16, 25]
const XP := {"void_drone": 1, "red_scout": 2, "ranged_shooter": 3, "void_tank": 4, "void_boss": 15, "armored_drone": 3}
const CATALOG := [
	{"id":"power", "art_key":"hero", "short_effect":"+20% damage", "name":"Power Railgun", "epic":false, "unlock":1, "cap":0, "effect":"+20% damage", "icon":"＋"},
	{"id":"reload", "art_key":"hero", "short_effect":"Reload ×0.90", "name":"Quick Reload", "epic":false, "unlock":1, "cap":0, "effect":"Reload time ×0.90", "icon":"↻"},
	{"id":"magazine", "art_key":"hero", "short_effect":"+1 round", "name":"Extended Magazine", "epic":false, "unlock":1, "cap":0, "effect":"+1 round per magazine", "icon":"▥"},
	{"id":"piercer", "art_key":"piercing", "short_effect":"+2 pierced targets", "name":"Hyper-Piercer", "epic":true, "unlock":1, "cap":4, "effect":"On kill: pierce +2 extra enemies", "icon":"»"},
	{"id":"twin", "art_key":"twin", "short_effect":"+1 projectile", "name":"Railgun Twin", "epic":true, "unlock":1, "cap":4, "effect":"+1 projectile per shot", "icon":"Ⅱ"},
	{"id":"core", "art_key":"overcharge", "short_effect":"+50% damage\n+10% crit dmg", "name":"Overcharged Core", "epic":true, "unlock":1, "cap":4, "effect":"+50% damage · +10% crit damage", "icon":"✦"},
	{"id":"caliber", "art_key":"hero", "short_effect":"+25% damage\n+25% crit dmg", "name":"Heavy Caliber", "epic":false, "unlock":2, "cap":3, "effect":"+25% damage · +25% crit damage", "icon":"⬡"},
	{"id":"shredder", "art_key":"piercing", "short_effect":"+1 pierced target", "name":"Armor Shredder", "epic":false, "unlock":6, "cap":3, "effect":"On kill: pierce +1 extra enemy", "icon":"»"},
	{"id":"critical", "art_key":"overcharge", "short_effect":"+5% crit chance", "name":"Critical Railgun", "epic":false, "unlock":10, "cap":3, "effect":"+5% critical chance", "icon":"✧"},
	{"id":"shatter", "art_key":"shatter", "short_effect":"+2 fragments\n50% damage", "name":"Shatter Railgun", "epic":true, "unlock":14, "cap":4, "effect":"First hit: +2 aimed fragments at 50% damage", "icon":"⋔"},
	{"id":"rampage", "art_key":"rampage", "short_effect":"+15% per hit\nMax 5 steps", "name":"Railgun Rampage", "epic":true, "unlock":18, "cap":4, "effect":"+15% damage per pierced enemy (max 5)", "icon":"ϟ"},
	{"id":"super_missiles", "art_key":"overcharge", "short_effect":"30% chance per rocket\n3× damage · tighter turn", "name":"Super Missiles", "epic":true, "unlock":1, "cap":1, "requires_blueprint":"micro_missile_rack", "effect":"30% per rocket: gold Super Missile, 3× damage and faster homing", "icon":"✦"},
]

static func definition(id: String) -> Dictionary:
	for card in CATALOG:
		if card.id == id: return card
	return {}

static func fresh(seed_value: int = 1) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	return {"version":VERSION, "xp":0, "choices":0, "ranks":{"super_missiles":0}, "offer":[], "rng":str(random.state), "modules":0}

static func threshold(state: Dictionary) -> int:
	return ceili(FIRST_CHOICE_XP * pow(XP_LEVEL_GROWTH,clampi(int(state.choices),0,MAX_CHOICES)))

static func is_epic(state: Dictionary) -> bool:
	return EPIC_CHOICES.has(int(state.choices) + 1)

static func epic_count(state: Dictionary) -> int:
	var count := 0
	for milestone in EPIC_CHOICES:
		if int(state.choices) >= milestone: count += 1
	return count

static func progress_text(state: Dictionary) -> String:
	var previous := 0
	for milestone in EPIC_CHOICES:
		if int(state.choices) < milestone:
			return "Next epic  %d / %d" % [int(state.choices) - previous, milestone - previous - 1]
		previous = milestone
	return "MAX"

static func stars(state: Dictionary) -> String:
	var count := epic_count(state)
	return "★".repeat(count) + "☆".repeat(4-count) if count > 0 else "★".repeat(mini(3, int(state.choices))) + "☆".repeat(maxi(0, 3-int(state.choices)))

static func is_unlocked(card: Dictionary, level: int, preserved: Array = []) -> bool:
	return level >= int(card.unlock) or preserved.has(card.id)

static func effective_cap(card: Dictionary) -> int:
	var cap := int(card.get("cap",0))
	# Epic cards are build-defining choices: one equipped rank is the hard cap.
	if bool(card.get("epic",false)): return 1
	return cap

static func ensure_offer(state: Dictionary, level: int, base_crit := 0.0, preserved: Array = [], equipped_blueprints: Array = []) -> bool:
	if int(state.choices) >= MAX_CHOICES:
		state.offer = []
		return false
	if not state.offer.is_empty(): return true
	if int(state.xp) < threshold(state): return false
	var pool: Array = []
	for card in CATALOG:
		if bool(card.epic) != is_epic(state) or not is_unlocked(card,level,preserved): continue
		var required_blueprint := str(card.get("requires_blueprint", ""))
		if not required_blueprint.is_empty() and not equipped_blueprints.has(required_blueprint): continue
		var cap := effective_cap(card)
		if cap > 0 and int(state.ranks.get(card.id, 0)) >= cap: continue
		if card.id == "critical" and base_crit + 0.05 * int(state.ranks.get("critical", 0)) >= 1.0: continue
		pool.append(card.id)
	var random := RandomNumberGenerator.new()
	if pool.size() < 3:
		state.offer = []
		return false
	random.state = int(state.rng)
	for index in range(3):
		var picked := random.randi_range(0, pool.size()-1)
		state.offer.append(pool[picked])
		pool.remove_at(picked)
	state.rng = str(random.state)
	return true

static func auto_pick(state: Dictionary) -> String:
	if state.offer.is_empty(): return ""
	var random := RandomNumberGenerator.new()
	random.state = int(state.rng)
	var id: String = state.offer[random.randi_range(0, state.offer.size()-1)]
	state.rng = str(random.state)
	return id

static func choose(state: Dictionary, id: String) -> bool:
	if int(state.choices) >= MAX_CHOICES or not state.offer.has(id) or int(state.xp) < threshold(state): return false
	var selected := definition(id)
	var cap := effective_cap(selected)
	if cap > 0 and int(state.ranks.get(id,0)) >= cap: return false
	state.xp = int(state.xp) - threshold(state)
	state.choices = int(state.choices) + 1
	state.ranks[id] = int(state.ranks.get(id, 0)) + 1
	state.offer = []
	return true

static func permanent_base_damage(level: int) -> float:
	var damage := Upgrades.value("damage",0)
	for current in range(1,clampi(level,1,MAX_LEVEL)):
		damage += FIRST_LEVEL_DAMAGE_GAIN + floori(float(current-1)/DAMAGE_STEP_EVERY)
	return damage

# Preserve cash/Workshop -> permanent -> cards, with criticals applied afterward.
static func permanent_damage_multiplier(level: int) -> float:
	return permanent_base_damage(level) / Upgrades.value("damage",0)

static func stats(state: Dictionary, level: int, base_damage: float, base_crit: float) -> Dictionary:
	var ranks: Dictionary = state.ranks
	var shots := mini(MAX_PRIMARY_PROJECTILES_PER_INSTANCE_VOLLEY,1 + mini(MAX_EXTRA_PRIMARY_PROJECTILES_PER_INSTANCE,int(ranks.get("twin",0))))
	var fragments := mini(MAX_SHATTER_FRAGMENTS_PER_PRIMARY,2 * int(ranks.get("shatter",0)))
	fragments = mini(fragments,mini(MAX_SHATTER_FRAGMENTS_PER_INSTANCE_VOLLEY,maxi(0,floori(float(MAX_TOTAL_PROJECTILES_PER_INSTANCE_VOLLEY) / float(maxi(1,shots))) - 1)))
	return {
		"damage": base_damage * permanent_damage_multiplier(level) * (1.0 + 0.20 * int(ranks.get("power",0)) + 0.50 * int(ranks.get("core",0)) + 0.25 * int(ranks.get("caliber",0))),
		"crit": minf(1.0, base_crit + 0.05 * int(ranks.get("critical",0))),
		"crit_multiplier": 2.0 + 0.10 * int(ranks.get("core",0)) + 0.25 * int(ranks.get("caliber",0)),
		"reload": maxf(MIN_RELOAD_SECONDS,3.0 * maxf(MIN_RELOAD_FACTOR,pow(0.90, int(ranks.get("reload",0))))),
		"magazine": 6 + mini(MAX_EXTRA_MAGAZINE,int(ranks.get("magazine",0))),
		"shots": shots,
		"hits": mini(MAX_PIERCE_TARGETS_PER_PROJECTILE,1 + 2 * int(ranks.get("piercer",0)) + int(ranks.get("shredder",0))),
		"width": 1.0,
		"fragments": fragments,
		"rampage": 0.15 * mini(MAX_RAMPAGE_STEPS,int(ranks.get("rampage",0))),
	}

static func preview(id: String, state: Dictionary, level: int, damage: float, crit: float) -> String:
	var after := state.duplicate(true)
	after.ranks[id] = int(after.ranks.get(id,0)) + 1
	var a := stats(state,level,damage,crit)
	var b := stats(after,level,damage,crit)
	match id:
		"power": return "Damage %.1f → %.1f" % [a.damage,b.damage]
		"caliber", "core": return "Damage %.1f → %.1f\nCrit damage %.2fx → %.2fx" % [a.damage,b.damage,a.crit_multiplier,b.crit_multiplier]
		"reload": return "Reload %.2fs → %.2fs" % [a.reload,b.reload]
		"magazine": return "Magazine %d → %d" % [a.magazine,b.magazine]
		"piercer", "shredder": return "Targets %d → %d" % [a.hits,b.hits]
		"twin": return "Projectiles %d → %d" % [a.shots,b.shots]
		"critical": return "Crit %.0f%% → %.0f%%" % [a.crit*100,b.crit*100]
		"shatter": return "Fragments %d → %d" % [a.fragments,b.fragments]
		"rampage": return "Per hit +%.0f%% → +%.0f%%" % [a.rampage*100,b.rampage*100]
	return ""

static func price(level: int) -> Dictionary:
	if level < 1 or level >= MAX_LEVEL: return {"coins":0,"modules":0}
	var amounts: Array = LEVEL_PRICES[level-1]
	return {"coins":amounts[0],"modules":amounts[1]}

static func next_unlock(level: int, preserved: Array = []) -> String:
	for card in CATALOG:
		if not is_unlocked(card,level,preserved): return "Next: %s · Lv.%d" % [card.name,card.unlock]
	return "All railgun cards unlocked"

static func progress_fraction(state: Dictionary) -> float:
	var previous := 0
	for milestone in EPIC_CHOICES:
		if int(state.choices) < milestone:
			return clampf(float(int(state.choices)-previous)/float(milestone-previous-1),0.0,1.0)
		previous = milestone
	return 1.0

static func migrate(state: Dictionary) -> Dictionary:
	if int(state.get("version",1)) >= VERSION:
		if not state.has("ranks") or not state.ranks is Dictionary: state.ranks = {}
		state.ranks.super_missiles = int(state.ranks.get("super_missiles", 0))
		return state
	var n := int(state.choices)
	var old_version := int(state.get("version",1))
	var old_threshold := 40 + 20*n + 4*n*n
	if old_version == 2: old_threshold = 20 + 10*n + 2*n*n
	elif old_version == 1: old_threshold = 10 + 5*n
	state.xp = floori(float(state.xp) / old_threshold * threshold(state))
	if int(state.choices) >= MAX_CHOICES:
		state.offer = []
	elif not state.offer.is_empty():
		state.xp = maxi(int(state.xp),threshold(state))
	if not state.has("ranks") or not state.ranks is Dictionary: state.ranks = {}
	state.ranks.super_missiles = int(state.ranks.get("super_missiles", 0))
	state.version = VERSION
	return state
