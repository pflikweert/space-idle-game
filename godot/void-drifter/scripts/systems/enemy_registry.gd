extends RefCounted

const GROWTH_START_WAVE := 10
const FAST_HP_GROWTH_WAVES := 25
const LATE_HP_MULTIPLIER := 1.025
const LATE_DAMAGE_MULTIPLIER := 1.01

const BOSS_ID := "void_boss"
const VOID_DRONE_ID := "void_drone"
const RED_SCOUT_ID := "red_scout"
const VOID_TANK_ID := "void_tank"
const RANGED_SHOOTER_ID := "ranged_shooter"
const VOID_SWARM_ID := "void_swarm"
const KAMIKAZE_ID := "kamikaze"
const SPLITTER_ID := "splitter"
const ELITE_HUNTER_ID := "elite_hunter"
const ARMORED_DRONE_ID := "armored_drone"

const DEFINITIONS := {
	"armored_drone": {
		"id":"armored_drone", "asset_key":"armored_drone_v1", "name":"Armored Drone", "role":"Armored chaser",
		"description":"A reinforced chaser with a kinetic shell that yields to explosive impact.", "status":"active", "unlock_wave":4,
		"archetype":"armored_chaser", "movement_behavior":"spiral_orbit", "attack_behavior":"contact", "visual_color":Color("#f59e0b"),
		"flight":{"orbit_strength":0.62,"approach_seconds":35.0,"approach_delay_seconds":1.0,"start_range":Vector2(0.56,0.72)},
		"visual_canvas_height":110.0, "death_vfx_key":"enemy_death_medium", "death_vfx_height":72.0,
		"base_stats":{"hp":36,"speed":38.0,"contact_damage":2,"contact_interval":0.55,"cash_reward":5,"coin_reward":3,"score_reward":36,"radius":17.0},
		"scaling":{"hp_multiplier":1.115,"speed_multiplier":1.0,"damage_multiplier":1.14}, "spawn":{"weight":12,"min_run_level":4},
		"abilities":["spiral_approach","contact_damage"],
		"resistances":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":0.75}],
		"weaknesses":[{"target_kind":"damage_type","target_id":"explosive","multiplier":1.25}], "immunities":[],
	},
	"void_drone": {
		"id": "void_drone",
		"asset_key": "void_drone_v3",
		"name": "Void Drone",
		"role": "Chaser",
		"description": "The smallest ship spirals inward fastest and applies rapid contact pressure.",
		"status": "active",
		"unlock_wave": 1,
		"archetype": "chaser",
		"movement_behavior": "spiral_orbit",
		"attack_behavior": "drone_railgun",
		"visual_color": Color("#ff3b30"),
		"visual_canvas_height": 74.4,
		"death_vfx_key": "enemy_death_small",
		"death_vfx_height": 49.2,
		"base_stats": { "hp": 16, "speed": 70.0, "contact_damage": 1, "contact_interval": 0.30, "cash_reward": 2, "coin_reward": 1, "score_reward": 10, "radius": 10.8 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 60, "min_run_level": 1 },
		"abilities": ["spiral_approach", "contact_damage"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"red_scout": {
		"id": "red_scout",
		"asset_key": "red_scout_v3",
		"name": "Red Scout",
		"role": "Fast scout",
		"description": "A very fast scout that curves inward and strikes in quick repeated passes.",
		"status": "active",
		"unlock_wave": 3,
		"archetype": "fast_scout",
		"movement_behavior": "spiral_orbit",
		"attack_behavior": "scout_railgun",
		"visual_color": Color("#fb7185"),
		"visual_canvas_height": 103.2,
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 62.4,
		"base_stats": { "hp": 12, "speed": 59.5, "contact_damage": 1, "contact_interval": 0.45, "cash_reward": 4, "coin_reward": 2, "score_reward": 24, "radius": 13.2 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 20, "min_run_level": 3 },
		"abilities": ["spiral_approach", "contact_damage"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"void_tank": {
		"id": "void_tank",
		"asset_key": "void_tank_v3",
		"name": "Void Tank",
		"role": "Tank",
		"description": "Slow armored gunship that circles inward while firing two-round railgun salvos.",
		"status": "active",
		"unlock_wave": 7,
		"archetype": "tank",
		"movement_behavior": "spiral_orbit",
		"attack_behavior": "tank_railgun",
		"visual_color": Color("#f97316"),
		"visual_canvas_height": 122.4,
		"death_vfx_key": "enemy_death_large",
		"death_vfx_height": 79.2,
		"base_stats": { "hp": 80, "speed": 17.5, "contact_damage": 1, "contact_interval": 0.75, "cash_reward": 8, "coin_reward": 4, "score_reward": 60, "radius": 22.8 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 10, "min_run_level": 7 },
		"abilities": ["spiral_approach", "contact_damage"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},

	"void_boss": {
		"id": "void_boss",
		"asset_key": "void_dreadnought",
		"name": "Void Dreadnought",
		"role": "Boss",
		"description": "Slower armored rocket carrier that circles inward before making contact.",
		"status": "active",
		"unlock_wave": 10,
		"archetype": "boss",
		"movement_behavior": "spiral_orbit",
		"attack_behavior": "boss_rocket",
		"visual_color": Color("#ff923e"),
		"visual_canvas_height": 255.0,
		"death_vfx_key": "enemy_death_large",
		"death_vfx_height": 132.0,
		"base_stats": { "hp": 400, "speed": 10.0, "contact_damage": 3, "contact_interval": 1.00, "cash_reward": 100, "coin_reward": 25, "score_reward": 60, "radius": 47.5 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 0, "min_run_level": 10 },
		"abilities": ["spiral_approach", "contact_damage", "guided_rockets"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"ranged_shooter": {
		"id": "ranged_shooter",
		"asset_key": "rift_shooter_v3",
		"name": "Rift Shooter",
		"role": "Ranged shooter",
		"description": "Starts in an outer firing orbit, then gradually spirals toward contact.",
		"status": "active",
		"unlock_wave": 5,
		"archetype": "ranged_shooter",
		"movement_behavior": "spiral_orbit",
		"attack_behavior": "enemy_railgun",
		"visual_color": Color("#a855f7"),
		"visual_canvas_height": 90.0,
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 62.4,
		"base_stats": { "hp": 24, "speed": 28.0, "contact_damage": 1, "contact_interval": 0.55, "cash_reward": 6, "coin_reward": 3, "score_reward": 32, "radius": 14.4 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 10, "min_run_level": 5 },
		"abilities": ["spiral_approach", "range_control", "railgun_salvo"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"void_swarm": {
		"id": "void_swarm",
		"asset_key": "void_swarm",
		"name": "Void Swarm",
		"role": "Swarm",
		"description": "Small low-health contacts that arrive in clusters.",
		"status": "active",
		"unlock_wave": 3,
		"archetype": "swarm",
		"movement_behavior": "swarm",
		"attack_behavior": "contact",
		"visual_color": Color("#22d3ee"),
		"visual_canvas_height": 110.0,
		"death_vfx_key": "enemy_death_small",
		"death_vfx_height": 82.0,
		"base_stats": { "hp": 8, "speed": 82.0, "contact_damage": 6, "cash_reward": 0, "coin_reward": 1, "score_reward": 8, "radius": 13.0 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 38, "min_run_level": 3 },
		"abilities": ["cluster_spawn", "contact_damage"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"kamikaze": {
		"id": "kamikaze",
		"asset_key": "kamikaze",
		"name": "Nova Dart",
		"role": "Kamikaze",
		"description": "A bright unstable hull that accelerates into the player and bursts on contact.",
		"status": "active",
		"unlock_wave": 11,
		"archetype": "kamikaze",
		"movement_behavior": "charge",
		"attack_behavior": "explode_contact",
		"visual_color": Color("#facc15"),
		"visual_canvas_height": 132.0,
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 104.0,
		"base_stats": { "hp": 20, "speed": 92.0, "contact_damage": 20, "cash_reward": 0, "coin_reward": 4, "score_reward": 36, "radius": 18.0 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 16, "min_run_level": 11 },
		"abilities": ["charge_player", "explosive_contact"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"splitter": {
		"id": "splitter",
		"asset_key": "splitter",
		"name": "Split Core",
		"role": "Splitter",
		"description": "A brittle core that divides into smaller swarm fragments when destroyed.",
		"status": "active",
		"unlock_wave": 6,
		"archetype": "splitter",
		"movement_behavior": "chase",
		"attack_behavior": "contact",
		"visual_color": Color("#34d399"),
		"visual_canvas_height": 148.0,
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 104.0,
		"base_stats": { "hp": 44, "speed": 36.0, "contact_damage": 14, "cash_reward": 0, "coin_reward": 6, "score_reward": 48, "radius": 27.0 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 12, "min_run_level": 6 },
		"abilities": ["split_on_death", "contact_damage"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
	"elite_hunter": {
		"id": "elite_hunter",
		"asset_key": "elite_hunter",
		"name": "Elite Hunter",
		"role": "Elite hunter",
		"description": "A dangerous hunter tuned for elite encounters and late-wave pressure.",
		"status": "active",
		"unlock_wave": 8,
		"archetype": "elite_hunter",
		"movement_behavior": "hunter",
		"attack_behavior": "elite_railgun",
		"visual_color": Color("#ff00ff"),
		"visual_canvas_height": 184.0,
		"death_vfx_key": "enemy_death_large",
		"death_vfx_height": 132.0,
		"base_stats": { "hp": 130, "speed": 54.0, "contact_damage": 28, "cash_reward": 0, "coin_reward": 16, "score_reward": 140, "radius": 34.0 },
		"scaling": { "hp_multiplier": 1.115, "speed_multiplier": 1.0, "damage_multiplier": 1.14 },
		"spawn": { "weight": 4, "min_run_level": 8 },
		"abilities": ["elite_pressure", "charged_projectile"],
		"resistances": [], "weaknesses": [], "immunities": [],
	},
}

const ELITE_MODIFIERS := {
	"fast": { "label": "FAST", "hp_multiplier": 1.08, "speed_multiplier": 1.32, "damage_multiplier": 1.0, "aura": Color("#22d3ee") },
	"armored": { "label": "ARMORED", "hp_multiplier": 1.65, "speed_multiplier": 0.86, "damage_multiplier": 1.05, "aura": Color("#f97316") },
	"explosive": { "label": "EXPLOSIVE", "hp_multiplier": 1.18, "speed_multiplier": 1.02, "damage_multiplier": 1.28, "aura": Color("#facc15") },
	"vampiric": { "label": "VAMPIRIC", "hp_multiplier": 1.28, "speed_multiplier": 1.0, "damage_multiplier": 1.12, "aura": Color("#fb7185") },
	"split_on_death": { "label": "SPLITS", "hp_multiplier": 1.22, "speed_multiplier": 1.0, "damage_multiplier": 1.0, "aura": Color("#34d399") },
	"shielded": { "label": "SHIELDED", "hp_multiplier": 1.115, "speed_multiplier": 0.95, "damage_multiplier": 1.0, "aura": Color("#00e5ff") },
}

static func get_definition(enemy_type_id: String) -> Dictionary:
	var definition: Dictionary = DEFINITIONS.get(enemy_type_id, DEFINITIONS[VOID_DRONE_ID]).duplicate(true)
	for key in ["resistances","weaknesses","immunities"]:
		if not definition.has(key): definition[key] = []
	return definition

static func get_definitions() -> Dictionary:
	var result := {}
	for id in DEFINITIONS:
		result[id] = get_definition(str(id))
	return result

static func get_stats(enemy_type_id: String, level: int, _elite_modifier := "") -> Dictionary:
	var definition := get_definition(enemy_type_id)
	var stats: Dictionary = definition.base_stats.duplicate(true)
	var offset := maxi(0, level - GROWTH_START_WAVE)
	# Saturate numeric values, not wave progression, for extremely long debug runs.
	stats.hp = float(stats.hp) * pow(float(definition.scaling.hp_multiplier), mini(offset, FAST_HP_GROWTH_WAVES)) * pow(LATE_HP_MULTIPLIER, mini(maxi(0, offset - FAST_HP_GROWTH_WAVES), 10000))
	stats.contact_damage = float(stats.contact_damage) * pow(float(definition.scaling.damage_multiplier), mini(offset, FAST_HP_GROWTH_WAVES)) * pow(LATE_DAMAGE_MULTIPLIER, mini(maxi(0, offset-FAST_HP_GROWTH_WAVES),10000))
	stats.level = level
	stats.cash_reward = float(stats.get("cash_reward", 0.0))
	return stats

static func get_wave_roster(wave: int) -> Array[Dictionary]:
	var resolved_wave := maxi(1, wave)
	var eligible: Array[Dictionary] = []
	var total_weight := 0
	for enemy_type_id in DEFINITIONS.keys():
		var definition: Dictionary = DEFINITIONS[enemy_type_id]
		var spawn: Dictionary = definition.spawn
		var weight := int(spawn.weight)
		if str(definition.status) != "active" or int(spawn.min_run_level) > resolved_wave or weight <= 0:
			continue
		eligible.append(definition)
		total_weight += weight

	eligible.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.unlock_wave) < int(b.unlock_wave))
	var roster: Array[Dictionary] = []
	for definition in eligible:
		var entry := definition.duplicate(true)
		entry.stats = get_stats(str(definition.id), resolved_wave)
		entry.spawn_chance = float(int(definition.spawn.weight)) / maxf(1.0, float(total_weight))
		entry.guaranteed_boss = false
		roster.append(entry)

	if resolved_wave % 10 == 0:
		var boss := get_definition(BOSS_ID).duplicate(true)
		boss.stats = get_stats(BOSS_ID, resolved_wave)
		boss.spawn_chance = -1.0
		boss.guaranteed_boss = true
		roster.append(boss)
	return roster

static func choose_enemy_type_id(run_level: int, seed: int, phase := "pressure") -> String:
	var spawnable: Array[Dictionary] = []
	var total_weight := 0
	for enemy_type_id in DEFINITIONS.keys():
		var definition: Dictionary = DEFINITIONS[enemy_type_id]
		var spawn: Dictionary = definition.spawn
		var weight := int(spawn.weight)
		if str(definition.status) != "active" or int(spawn.min_run_level) > run_level or weight <= 0:
			continue
		if phase == "recovery" and str(definition.archetype) in ["tank", "elite_hunter"]:
			weight = maxi(1, int(floor(float(weight) * 0.35)))
		elif phase == "spike" and str(definition.archetype) in ["kamikaze", "ranged_shooter", "fast_scout"]:
			weight = int(ceil(float(weight) * 1.6))
		spawnable.append(definition.merged({ "phase_weight": weight }))
		total_weight += weight
	if spawnable.is_empty() or total_weight <= 0:
		return VOID_DRONE_ID
	var roll := absi(seed) % total_weight
	for definition in spawnable:
		var weight := int(definition.phase_weight)
		if roll < weight:
			return str(definition.id)
		roll -= weight
	return str(spawnable[0].id)

static func get_elite_modifier(wave: int, seed: int) -> String:
	var keys := ELITE_MODIFIERS.keys()
	if keys.is_empty():
		return ""
	return str(keys[absi(seed + wave * 17) % keys.size()])

static func get_spawn_inset(enemy_type_id: String, stats: Dictionary) -> float:
	var definition := get_definition(enemy_type_id)
	var visual_canvas_height: float = float(definition.get("visual_canvas_height", float(stats.radius) * 6.0))
	return maxf(float(stats.radius) + 12.0, visual_canvas_height * 0.34)
