extends RefCounted

const STARTER_SHIP_ID := "starter_ship"
const MAX_ACTIVE_WEAPONS := 5
const MAX_ACTIVE_WEAPON_FAMILIES := 5
const SHIP_LEVEL_CAP := 40

const SHIPS := {
	STARTER_SHIP_ID: {
		"id": STARTER_SHIP_ID, "name": "Drifter Gunship", "rarity": "normal",
		"art": {
			"hangar":"res://assets/hangar/modular_gunship_round_systems.png",
			"combat_states": {
				"intact":"res://assets/player_ship/modular_gunship/intact_round_systems.png",
				"damaged":"res://assets/player_ship/modular_gunship/damaged_round_systems.png",
				"critical":"res://assets/player_ship/modular_gunship/critical_round_systems.png",
			},
			"shield_idle":"res://assets/vfx/shield/modular-shield-idle.png",
			"shield_break":"res://assets/vfx/shield/shield-break.png",
		},
		"presentation": {
			"source_canvas":Vector2(1024,1536), "combat_height":132.0,
			"engine_anchors":[Vector2(0.36,0.87),Vector2(0.64,0.87)],
			"weapon_mount_height":36.0, "system_mount_height":30.0,
			"weapon_muzzle_offset":13.0, "shield_height_multiplier":1.52,
			# Contact boundary sits on the solid outer hex ring, not its soft glow.
			"deflector_radius":88.0,
		},
		"base_stats": {"max_hp":140.0, "regen":0.5, "armor":0.0, "attack_damage":12.0, "range":160.0, "move_speed":470.0, "collision_radius":8.64},
		"max_active_weapons": 4, "max_active_weapon_families": 4,
		"future_caps": {"utility":0, "system":2}, "passive": {}, "unlock": {"type":"starter"},
		"slots": [
			# Socket geometry is normalized to the source canvas and shared by Hangar and combat.
			{"id":"W1", "type":"weapon", "position":Vector2(0.28,0.35), "mount_size":Vector2(0.18,0.18), "accepts":["weapon"]},
			{"id":"W2", "type":"weapon", "position":Vector2(0.72,0.35), "mount_size":Vector2(0.18,0.18), "accepts":["weapon"]},
			{"id":"W3", "type":"weapon", "position":Vector2(0.28,0.66), "mount_size":Vector2(0.18,0.18), "accepts":["weapon"]},
			{"id":"W4", "type":"weapon", "position":Vector2(0.72,0.66), "mount_size":Vector2(0.18,0.18), "accepts":["weapon"]},
			{"id":"S1", "type":"system", "position":Vector2(0.50,0.445), "mount_size":Vector2(0.30,0.20), "accepts":["system"]},
			{"id":"S2", "type":"system", "position":Vector2(0.50,0.66), "mount_size":Vector2(0.30,0.20), "accepts":["system"]},
		],
	}
}

static func definition(ship_id: String) -> Dictionary:
	return SHIPS.get(ship_id, {}).duplicate(true)

static func fixture_definition(fixture_id: String) -> Dictionary:
	var fixtures := {
		"assault_fixture":{"id":"assault_fixture","max_active_weapons":5,"max_active_weapon_families":5,"slots":_weapon_slots(8)},
		"support_fixture":{"id":"support_fixture","max_active_weapons":2,"max_active_weapon_families":5,"slots":_mixed_slots(2,4)},
		"specialist_fixture":{"id":"specialist_fixture","max_active_weapons":5,"max_active_weapon_families":2,"slots":_weapon_slots(5)},
	}
	return fixtures.get(fixture_id,{}).duplicate(true)

static func _weapon_slots(count: int) -> Array:
	var result := []
	for index in count: result.append({"id":"W%d" % (index + 1),"type":"weapon","position":Vector2.ZERO,"accepts":["weapon"]})
	return result

static func _mixed_slots(weapons: int, systems: int) -> Array:
	var result := _weapon_slots(weapons)
	for index in systems: result.append({"id":"S%d" % (index + 1),"type":"system","position":Vector2.ZERO,"accepts":["system","utility"]})
	return result

static func slot(ship_id: String, slot_id: String) -> Dictionary:
	for entry in definition(ship_id).get("slots", []):
		if str(entry.id) == slot_id: return entry
	return {}

static func base_stat(ship_id: String, stat_id: String) -> float:
	var lookup := "attack_damage" if stat_id == "damage" else stat_id
	return float(definition(ship_id).get("base_stats", {}).get(lookup, 0.0))

static func upgrade_cost(level: int) -> int:
	var current := clampi(level,0,SHIP_LEVEL_CAP)
	return 750 + 300 * current + 60 * current * current

static func upgraded_stat(ship_id: String, stat_id: String, level: int) -> float:
	var base := base_stat(ship_id,stat_id)
	var current := clampi(level,0,SHIP_LEVEL_CAP)
	match stat_id:
		"max_hp": return base + 8.0 * current
		"regen": return base + 0.04 * current
		"armor": return base + 0.003 * current
		"damage": return base + 0.5 * current
		"range": return base + 2.0 * current
	return base
