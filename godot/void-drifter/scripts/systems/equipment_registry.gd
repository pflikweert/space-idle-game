extends RefCounted

const RAILGUN_ID := "railgun"
const LEGACY_STARTER_RAILGUN_ID := "starter_railgun"
const LEGACY_AUXILIARY_RAILGUN_ID := "railgun_auxiliary"
const MICRO_MISSILE_RACK_ID := "micro_missile_rack"
const SHIELD_CORE_ID := "starter_shield_core"
const RAILGUN_INSTANCE_ID := "railgun-001"
const LEGACY_STARTER_RAILGUN_INSTANCE_ID := "starter-railgun-001"
const SHIELD_CORE_INSTANCE_ID := "shield-core-001"
const MICRO_MISSILE_RACK_INSTANCE_ID := "micro-missile-rack-001"
const Progression := preload("res://scripts/systems/module_progression.gd")

const BUILD_INSTANCE_IDS := {
	RAILGUN_ID:RAILGUN_INSTANCE_ID,
	MICRO_MISSILE_RACK_ID:MICRO_MISSILE_RACK_INSTANCE_ID,
}

const RAILGUN_BUILD_COST := {"coins":5000,"modules":2}
const MICRO_MISSILE_BUILD_COST := {"coins":2000,"modules":0}

static var EQUIPMENT: Dictionary = {
	RAILGUN_ID: {"id":RAILGUN_ID,"name":"Railgun","item_type":"weapon","weapon_family":"railgun","family":"railgun","damage_type":"kinetic","rarity":"common","art":"res://assets/hangar/starter_railgun.png","mount_art":"res://assets/player_ship/modular_gunship/weapon_socket_cover.png","mount_scale":1.0,"overlay_art":"res://assets/player_ship/modular_gunship/starter_railgun_mount.png","overlay_scale":1.0,"overlay_pivot":Vector2(0.5,0.72),"rotates_to_target":true,"slot_art":"res://assets/ui/weapon_cards/starter_railgun.png","hud_art":"res://assets/ui/weapon_cards/starter_railgun.png","base_stats":{"magazine":6,"reload":3.0,"interval":0.5},"damage_scaling":{"ship_multiplier":1.0,"level_bonus":0.0},"level_cap":40,"max_active_copies":4,"trade_offs":[],"special_ability":"railgun_payload","unlock":{"type":"starter"},"upgrade_curve":"railgun_v3","milestones":_railgun_milestones(),"build_cost":RAILGUN_BUILD_COST},
	SHIELD_CORE_ID: {"id":SHIELD_CORE_ID,"name":"Shield Core","item_type":"system","rarity":"common","art":"res://assets/hangar/shield_core.png","mount_art":"res://assets/player_ship/modular_gunship/shield_core_mount.png","mount_scale":1.0,"base_stats":{"capacity":30.0,"recharge":0.5,"recharge_delay":3.0},"trade_offs":[],"special_ability":"","unlock":{"type":"starter"},"upgrade_curve":"shield_core_v3","milestones":_shield_milestones()},
	MICRO_MISSILE_RACK_ID: {"id":MICRO_MISSILE_RACK_ID,"name":"Micro Missile Rack","item_type":"weapon","family":"explosive","weapon_family":"explosive","damage_type":"explosive","rarity":"normal","art":"res://assets/hangar/micro_missile_rack.png","mount_art":"res://assets/player_ship/modular_gunship/weapon_socket_cover.png","mount_scale":1.0,"overlay_art":"res://assets/player_ship/gunship/micro_missile_rack_mount.png","overlay_scale":1.28,"rotates_to_target":false,"hud_art":"res://assets/ui/weapon_cards/micro_missile_rack.png","projectile_art":"res://assets/vfx/micro_missile/projectile.png","muzzle_vfx":"res://assets/vfx/micro_missile/muzzle.png","impact_vfx":"res://assets/vfx/micro_missile/impact.png","base_stats":{"fire_interval":1.4,"magazine":3,"reload":8.0,"range":200.0,"projectile_speed":210.0,"explosion_ratio":0.5,"explosion_radius":42.0},"damage_scaling":{"ship_multiplier":1.3,"level_bonus":2.0},"level_cap":40,"max_active_copies":4,"trade_offs":["Impact damage plus area explosion payload."],"special_ability":"missile_payload","unlock":{"type":"armored_drone"},"upgrade_curve":"micro_missile_rack_v2","milestones":_missile_milestones(),"build_cost":MICRO_MISSILE_BUILD_COST},
}

static func _milestone(level: int, tier: String, title: String, description: String, effects: Dictionary) -> Dictionary:
	return {"level":level,"tier":tier,"title":title,"description":description,"effects":effects}

static func _railgun_milestones() -> Dictionary:
	return {
		"5":_milestone(5,"normal","Heavy Caliber","+60% bullet damage · +5% crit chance",{"damage_multiplier":1.60,"crit_bonus":0.05}),
		"10":_milestone(10,"normal","Split Fire","+1 bullet · −20% damage per bullet",{"additional_bullets":1,"damage_multiplier":0.80}),
		"15":_milestone(15,"normal","Shatter Railgun","2 small bullets · 50% damage each",{"shatter_fragments":2,"shatter_damage_ratio":0.50}),
		"20":_milestone(20,"epic","Void Burst","50% explosion damage · 42 range",{"void_burst_ratio":0.50,"void_burst_radius":42.0}),
		"25":_milestone(25,"normal","Phase Penetrator","30% faster reload",{"reload_multiplier":0.70}),
		"30":_milestone(30,"normal","Deep Penetrator","+2 penetration",{"penetration_bonus":2}),
		"35":_milestone(35,"normal","Rampage Matrix","+20% per penetration · max +100%",{"rampage_per_penetration":0.20,"rampage_cap":1.0}),
		"40":_milestone(40,"epic","Twin Rampage Core","+2 bullets · +30% Void Burst damage · +30% Void Burst range",{"additional_bullets":2,"void_burst_ratio_multiplier":1.30,"void_burst_radius_multiplier":1.30}),
	}

static func _missile_milestones() -> Dictionary:
	return {
		"5":_milestone(5,"normal","Power Missile","+60% impact and explosion damage",{"damage_multiplier":1.60}),
		"10":_milestone(10,"normal","Missile Volley","+3 missiles · −20% damage per missile",{"volley_bonus":3,"damage_multiplier":0.80}),
		"15":_milestone(15,"normal","Blast Amplifier","+30% radius · +30% explosion damage",{"explosion_radius_multiplier":1.30,"explosion_ratio_multiplier":1.30}),
		"20":_milestone(20,"epic","Enhanced Missile","30% chance for ×3 Super Missile",{"super_chance":0.30,"super_multiplier":3.0,"super_radius_multiplier":1.20}),
		"25":_milestone(25,"normal","Splinter Missiles","2 impact-only splinters · 25% damage",{"splinter_count":2,"splinter_damage_ratio":0.25}),
		"30":_milestone(30,"normal","Impact Burst","Small missiles have 30% chance to explode on impact",{"small_explosion_chance":0.30}),
		"35":_milestone(35,"normal","Shatter Strike Core","Missile bursts into 4 impact fragments",{"fragment_count":4,"fragment_damage_ratio":0.25}),
		"40":_milestone(40,"epic","Echo Detonation","Super Missiles trigger a second explosion · +60% explosion damage · +50% radius",{"echo_damage_ratio":0.60,"echo_radius_multiplier":1.50}),
	}

static func _shield_milestones() -> Dictionary:
	return {
		"5":_milestone(5,"normal","Capacitor Bank","+15% capacity",{"capacity_multiplier":1.15}),
		"10":_milestone(10,"normal","Rapid Restart","recharge delay −0.5s",{"recharge_delay_bonus":-0.5}),
		"15":_milestone(15,"normal","Flux Regulator","+20% recharge",{"recharge_multiplier":1.20}),
		"20":_milestone(20,"epic","Emergency Reserve","+10% capacity",{"capacity_multiplier":1.10}),
		"25":_milestone(25,"normal","Reinforced Capacitors","+15% capacity",{"capacity_multiplier":1.15}),
		"30":_milestone(30,"normal","Fast Restart II","recharge delay −0.5s",{"recharge_delay_bonus":-0.5}),
		"35":_milestone(35,"normal","Flux Regulator II","+20% recharge",{"recharge_multiplier":1.20}),
		"40":_milestone(40,"epic","Emergency Reserve II","+20% capacity",{"capacity_multiplier":1.20}),
	}

static func definition(blueprint_id: String) -> Dictionary:
	if blueprint_id == LEGACY_STARTER_RAILGUN_ID: blueprint_id = RAILGUN_ID
	if blueprint_id == LEGACY_AUXILIARY_RAILGUN_ID: blueprint_id = RAILGUN_ID
	if blueprint_id.begins_with("fixture_weapon_"):
		var family := blueprint_id.trim_prefix("fixture_weapon_")
		return {"id":blueprint_id,"name":"Fixture %s" % family,"item_type":"weapon","family":family,"weapon_family":family,"damage_type":"fixture","rarity":"normal","base_stats":{"damage":1.0},"max_active_copies":999}
	return EQUIPMENT.get(blueprint_id, {}).duplicate(true)

static func starter_instances() -> Dictionary:
	return {
		RAILGUN_INSTANCE_ID:new_instance(RAILGUN_INSTANCE_ID, RAILGUN_ID),
		SHIELD_CORE_INSTANCE_ID:new_instance(SHIELD_CORE_INSTANCE_ID, SHIELD_CORE_ID),
	}

static func new_instance(instance_id: String, blueprint_id: String, spent := {}) -> Dictionary:
	return Progression.sanitize_item({"id":instance_id,"blueprint_id":blueprint_id,"level":1,"rarity":"common","xp":0,"milestones":[],"coins_spent":int(spent.get("coins",0)),"modules_spent":int(spent.get("modules",0))}, definition(blueprint_id))

static func sanitize_instance(item: Dictionary) -> Dictionary:
	var blueprint_id := str(item.get("blueprint_id", ""))
	return Progression.sanitize_item(item, definition(blueprint_id))

static func build_instance_id(blueprint_id: String, existing_items := {}) -> String:
	var first_id := str(BUILD_INSTANCE_IDS.get(blueprint_id,""))
	if first_id.is_empty(): return ""
	if existing_items.is_empty() or not existing_items.has(first_id): return first_id
	var base := first_id.substr(0,first_id.length()-3) if first_id.ends_with("001") else "%s-" % blueprint_id
	var used := {}
	for item_id in existing_items:
		var item: Dictionary = existing_items.get(item_id,{})
		if str(item.get("blueprint_id","")) != blueprint_id: continue
		var key := str(item_id)
		if not key.begins_with(base): continue
		var suffix := key.trim_prefix(base)
		if suffix.is_valid_int(): used[int(suffix)] = true
	var index := 1
	while used.has(index): index += 1
	return "%s%03d" % [base,index]

static func micro_missile_stats(level: int) -> Dictionary:
	var current: Dictionary = definition(MICRO_MISSILE_RACK_ID).get("base_stats",{}).duplicate(true)
	var clamped := clampi(level,1,40)
	current.merge({"damage_multiplier":1.0,"volley_bonus":0,"explosion_radius_multiplier":1.0,"explosion_ratio_multiplier":1.0,"super_chance":0.0,"super_multiplier":1.0,"super_radius_multiplier":1.0,"interval_multiplier":1.0,"range_bonus":0.0,"projectile_speed_multiplier":1.0,"splinter_count":0,"splinter_damage_ratio":0.0,"small_explosion_chance":0.0,"fragment_count":0,"fragment_damage_ratio":0.0,"echo_damage_ratio":0.0,"echo_radius_multiplier":1.0},true)
	for effect in milestone_effects(MICRO_MISSILE_RACK_ID,clamped):
		for key in effect:
			match key:
				"damage_multiplier", "explosion_radius_multiplier", "explosion_ratio_multiplier", "interval_multiplier", "projectile_speed_multiplier", "echo_radius_multiplier": current[key] = float(current.get(key,1.0)) * float(effect[key])
				"volley_bonus", "range_bonus", "splinter_count", "fragment_count": current[key] = int(current.get(key,0)) + int(effect[key])
				"super_chance", "super_multiplier", "super_radius_multiplier", "splinter_damage_ratio", "small_explosion_chance", "fragment_damage_ratio", "echo_damage_ratio": current[key] = float(effect[key])
	current.fire_interval = float(current.fire_interval) * float(current.interval_multiplier)
	current.range = float(current.range) + float(current.range_bonus)
	current.projectile_speed = float(current.projectile_speed) * float(current.projectile_speed_multiplier)
	return current

static func railgun_stats(level: int) -> Dictionary:
	var current: Dictionary = definition(RAILGUN_ID).get("base_stats",{}).duplicate(true)
	var clamped := clampi(level,1,160)
	current.fire_interval = maxf(280.0, 500.0 * pow(0.985, float(clamped - 1)))
	current.merge({"damage_multiplier":1.0,"additional_bullets":0,"shatter_fragments":0,"shatter_damage_ratio":0.0,"void_burst_ratio":0.0,"void_burst_radius":0.0,"void_burst_ratio_multiplier":1.0,"void_burst_radius_multiplier":1.0,"interval_multiplier":1.0,"reload_multiplier":1.0,"penetration_bonus":0,"rampage_per_penetration":0.0,"rampage_cap":0.0,"crit_bonus":0.0},true)
	for effect in milestone_effects(RAILGUN_ID,clamped):
		for key in effect:
			match key:
				"damage_multiplier", "interval_multiplier", "reload_multiplier", "void_burst_ratio_multiplier", "void_burst_radius_multiplier": current[key] = float(current.get(key,1.0)) * float(effect[key])
				"additional_bullets", "shatter_fragments", "penetration_bonus": current[key] = int(current.get(key,0)) + int(effect[key])
				"shatter_damage_ratio", "void_burst_ratio", "void_burst_radius", "rampage_per_penetration", "rampage_cap", "crit_bonus": current[key] = float(effect[key])
	current.fire_interval = maxf(280.0, float(current.fire_interval) * float(current.interval_multiplier))
	current.reload = maxf(0.1, float(current.get("reload",3.0)) * float(current.reload_multiplier))
	current.void_burst_ratio = float(current.void_burst_ratio) * float(current.void_burst_ratio_multiplier)
	current.void_burst_radius = float(current.void_burst_radius) * float(current.void_burst_radius_multiplier)
	return current

static func milestone_effects(blueprint_id: String, level: int) -> Array:
	var result: Array = []
	var milestones: Dictionary = definition(blueprint_id).get("milestones",{})
	for key in milestones:
		if int(key) <= level:
			result.append(Dictionary(milestones[key]).get("effects",{}))
	return result

static func damage_from_ship(blueprint_id: String, level: int, ship_damage: float) -> float:
	var blueprint := definition(blueprint_id)
	var scaling: Dictionary = blueprint.get("damage_scaling",{})
	if scaling.is_empty():
		return float(blueprint.get("base_stats",{}).get("damage",0.0))
	var multiplier := float(scaling.get("ship_multiplier",1.0))
	var level_bonus := float(scaling.get("level_bonus",0.0))
	return ship_damage * multiplier + level_bonus * float(maxi(0,level - 1))

static func stats_for(blueprint_id: String, level: int) -> Dictionary:
	if blueprint_id == MICRO_MISSILE_RACK_ID: return micro_missile_stats(level)
	if blueprint_id == SHIELD_CORE_ID: return shield_core_stats(level)
	return definition(blueprint_id).get("base_stats",{}).duplicate(true)

static func shield_core_stats(level: int, legacy_bonus := {}) -> Dictionary:
	var current: Dictionary = definition(SHIELD_CORE_ID).get("base_stats",{}).duplicate(true)
	var clamped := clampi(level,1,Progression.level_cap("common"))
	current.capacity += 2.5 * float(clamped - 1) + maxf(0.0,float(legacy_bonus.get("capacity",0.0)))
	current.recharge += 0.06 * float(clamped - 1) + maxf(0.0,float(legacy_bonus.get("recharge",0.0)))
	for effect in milestone_effects(SHIELD_CORE_ID,clamped):
		if effect.has("capacity_multiplier"): current.capacity *= float(effect.capacity_multiplier)
		if effect.has("recharge_multiplier"): current.recharge *= float(effect.recharge_multiplier)
		if effect.has("recharge_delay_bonus"): current.recharge_delay += float(effect.recharge_delay_bonus)
	current.recharge_delay = maxf(1.0,float(current.recharge_delay))
	return current

static func micro_missile_upgrade_cost(level: int) -> Dictionary:
	var offset := maxi(0,level - 1)
	return {"coins":600 + 300 * offset + 35 * offset * offset,"modules":level + 1}

static func upgrade_cost(blueprint_id: String, level: int) -> Dictionary:
	if blueprint_id == RAILGUN_ID: return railgun_upgrade_cost(level)
	if blueprint_id == SHIELD_CORE_ID: return shield_core_upgrade_cost(level)
	if blueprint_id == MICRO_MISSILE_RACK_ID: return micro_missile_upgrade_cost(level)
	return {"coins":0,"modules":0}

static func railgun_upgrade_cost(level: int) -> Dictionary:
	if level < 1: return {"coins":0,"modules":0}
	var offset := maxi(0,level - 1)
	return {"coins":800 + 300 * offset + 35 * offset * offset,"modules":level + 1}

static func shield_core_upgrade_cost(level: int) -> Dictionary:
	var offset := maxi(0,level - 1)
	return {"coins":500 + 300 * offset + 40 * offset * offset,"modules":level + 1}
