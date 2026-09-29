extends RefCounted
class_name EncounterDirector

const SPAWN_SECONDS := 26.0
const COOLDOWN_SECONDS := 9.0
const WAVE_SECONDS := SPAWN_SECONDS + COOLDOWN_SECONDS
const MAX_NORMAL := 40
const MAX_BOSSES := 4
const SECTORS := ["dead_relay", "ion_wake", "fracture_field", "hunters_wake"]
const SECTOR_NAMES := {"dead_relay":"DEAD RELAY", "ion_wake":"ION WAKE", "fracture_field":"FRACTURE FIELD", "hunters_wake":"HUNTER'S WAKE"}
const SECTOR_MUTATORS := {"dead_relay":"baseline formations", "ion_wake":"synchronized ranged salvos", "fracture_field":"splitter and swarm pressure", "hunters_wake":"elite escorts and flanks"}
const BOSS_VARIANTS := ["missile_dreadnought", "rail_fortress", "rift_carrier"]

const FIRST_SECTOR_BEATS := {
	1: {"id":"drone_wings", "role":"chaser", "formation":"wing", "allowed":["void_drone"], "weapon_enabled":false},
	2: {"id":"drone_wings_mirrored", "role":"chaser", "formation":"wing_mirrored", "allowed":["void_drone"], "weapon_enabled":false},
	3: {"id":"scout_flanks", "role":"flanker", "formation":"flank_pair", "allowed":["void_drone","red_scout"], "weapon_enabled":true},
	4: {"id":"crossing_fracture", "role":"crowd", "formation":"cross", "allowed":["void_drone","void_swarm"], "weapon_enabled":true},
	5: {"id":"artillery_intro", "role":"ranged", "formation":"escort_column", "allowed":["void_drone","ranged_shooter"], "weapon_enabled":true},
	6: {"id":"split_core_priority", "role":"splitter", "formation":"priority_center", "allowed":["void_drone","splitter"], "weapon_enabled":true},
	7: {"id":"tank_frontline", "role":"frontline", "formation":"frontline", "allowed":["void_drone","void_tank"], "weapon_enabled":true},
	8: {"id":"elite_hunter_intro", "role":"elite", "formation":"hunter_escort", "allowed":["void_drone","elite_hunter"], "weapon_enabled":true},
	9: {"id":"ordered_rehearsal", "role":"rehearsal", "formation":"ordered_rehearsal", "allowed":["red_scout","void_tank","ranged_shooter"], "weapon_enabled":true},
}

static func get_run_level(seconds: float) -> int:
	return 1 + int(floor(seconds / WAVE_SECONDS))

static func phase(seconds: float) -> String:
	return "spawning" if fmod(seconds, WAVE_SECONDS) < SPAWN_SECONDS else "cooldown"

static func phase_remaining(seconds: float) -> float:
	var cycle_seconds := fmod(maxf(0.0, seconds), WAVE_SECONDS)
	return (SPAWN_SECONDS - cycle_seconds) if cycle_seconds < SPAWN_SECONDS else (WAVE_SECONDS - cycle_seconds)

static func sector_for_wave(wave: int) -> Dictionary:
	var resolved := maxi(1, wave)
	var index := ((resolved - 1) / 10) % SECTORS.size()
	var id := str(SECTORS[index])
	return {"id":id, "name":str(SECTOR_NAMES[id]), "mutator":str(SECTOR_MUTATORS[id]), "threat_tier":1 + maxi(0, (resolved - 1) / 40)}

static func boss_variant_for_wave(wave: int) -> String:
	if wave <= 0 or wave % 10 != 0: return ""
	return str(BOSS_VARIANTS[((wave / 10) - 1) % BOSS_VARIANTS.size()])

static func spawn_interval(wave: int) -> float:
	return maxf(0.45, 1.10 - float(wave - 1) * 0.02)

static func _seeded_pick(seed_value: int, index: int, size: int) -> int:
	if size <= 0: return 0
	return absi(hash("%d:%d" % [seed_value, index])) % size

static func _instruction(time: float, enemy_id: String, beat: Dictionary, slot: int, edge := "top") -> Dictionary:
	return {"at":time, "enemy_id":enemy_id, "formation":str(beat.get("formation", "line")), "primary_role":str(beat.get("role", "chaser")), "formation_slot":slot, "edge":edge, "weapon_enabled":bool(beat.get("weapon_enabled", true)), "presentation":str(beat.get("id", "encounter"))}

static func _edge_for_slot(slot: int) -> String:
	return ["top", "left", "right", "bottom"][slot % 4]

static func _build_opening_wave() -> Dictionary:
	var beat: Dictionary = FIRST_SECTOR_BEATS[1]
	var groups := [
		{"at":3.0, "count":2},
		{"at":11.0, "count":3},
		{"at":19.0, "count":3},
	]
	var instructions: Array = []
	var slot := 0
	for group in groups:
		for _member in range(int(group.count)):
			instructions.append(_instruction(float(group.at), "void_drone", beat, slot, _edge_for_slot(slot)))
			slot += 1
	return {"id":str(beat.id), "role":str(beat.role), "formation":str(beat.formation), "instructions":instructions, "normal_spawns":true}

static func _build_first_sector(wave: int) -> Dictionary:
	if wave == 1:
		return _build_opening_wave()
	if wave == 10:
		return {"id":"missile_dreadnought", "role":"boss", "formation":"boss_entry", "instructions":[{"at":0.0,"enemy_id":"void_boss","formation":"boss_entry","primary_role":"boss","formation_slot":0,"edge":"top","weapon_enabled":true,"boss_variant":boss_variant_for_wave(wave),"presentation":"boss_entry"}], "normal_spawns":false}
	var beat: Dictionary = FIRST_SECTOR_BEATS.get(wave, FIRST_SECTOR_BEATS[1])
	var instructions: Array = []
	var interval := spawn_interval(wave)
	var count := 0
	var cursor := 0.9
	while cursor < SPAWN_SECONDS - 0.15:
		var enemy_id := str(beat.allowed[0])
		if wave == 3 and count % 4 == 1: enemy_id = "red_scout"
		elif wave == 5 and count == 2: enemy_id = "ranged_shooter"
		elif wave == 6 and count == 3: enemy_id = "splitter"
		elif wave == 7 and count == 2: enemy_id = "void_tank"
		elif wave == 8 and count == 3: enemy_id = "elite_hunter"
		elif wave == 9: enemy_id = ["red_scout", "void_tank", "ranged_shooter"][count % 3]
		instructions.append(_instruction(cursor, enemy_id, beat, count, _edge_for_slot(count + (1 if wave == 3 else 0))))
		cursor += interval
		count += 1
	return {"id":str(beat.id), "role":str(beat.role), "formation":str(beat.formation), "instructions":instructions, "normal_spawns":true}

static func _role_for(enemy_id: String) -> String:
	if enemy_id in ["void_swarm", "splitter"]: return "crowd"
	if enemy_id == "elite_hunter": return "elite"
	if enemy_id == "ranged_shooter": return "ranged"
	if enemy_id in ["red_scout", "kamikaze"]: return "flanker"
	return "chaser"

static func _build_endless(wave: int, seed_value: int) -> Dictionary:
	var sector := sector_for_wave(wave)
	var sector_id := str(sector.id)
	var decks := {"dead_relay":["void_drone", "red_scout", "ranged_shooter", "void_tank"], "ion_wake":["void_drone", "red_scout", "ranged_shooter", "kamikaze"], "fracture_field":["void_swarm", "splitter", "void_drone", "ranged_shooter"], "hunters_wake":["elite_hunter", "red_scout", "kamikaze", "void_drone", "ranged_shooter"]}
	var allowed: Array = decks[sector_id]
	var instructions: Array = []
	var interval := spawn_interval(wave)
	var previous_role := ""
	var cursor := 0.9
	var count := 0
	while cursor < SPAWN_SECONDS - 0.15:
		var candidates: Array = allowed.duplicate()
		if sector_id == "fracture_field" and count % 3 != 0: candidates = ["void_swarm", "splitter", "void_drone"]
		if sector_id == "hunters_wake" and count % 5 == 2: candidates = ["elite_hunter", "kamikaze", "red_scout"]
		var pick := str(candidates[_seeded_pick(seed_value, wave * 100 + count, candidates.size())])
		var role := _role_for(pick)
		if role == previous_role and candidates.size() > 1:
			for candidate in candidates:
				var candidate_role := _role_for(str(candidate))
				if candidate_role != previous_role:
					pick = str(candidate); role = candidate_role; break
		instructions.append({"at":cursor,"enemy_id":pick,"formation":"sector_%s" % sector_id,"primary_role":role,"formation_slot":count,"edge":_edge_for_slot(count + _seeded_pick(seed_value, wave, 4)),"weapon_enabled":true,"presentation":sector_id})
		previous_role = role
		cursor += interval
		count += 1
	return {"id":"%s_%02d" % [sector_id, ((wave - 1) % 10) + 1], "role":previous_role, "formation":"sector_%s" % sector_id, "instructions":instructions, "normal_spawns":true}

static func build_encounter(wave: int, seed_value: int, _previous_id := "") -> Dictionary:
	var encounter: Dictionary
	if wave % 10 == 0:
		var variant := boss_variant_for_wave(wave)
		encounter = {"id":variant, "role":"boss", "formation":"boss_entry", "instructions":[{"at":0.0,"enemy_id":"void_boss","formation":"boss_entry","primary_role":"boss","formation_slot":0,"edge":"top","weapon_enabled":true,"boss_variant":variant,"presentation":"boss_entry"}], "normal_spawns":false, "sector":sector_for_wave(wave), "wave":wave, "boss_variant":variant, "cursor":0}
	else:
		encounter = _build_first_sector(wave) if wave <= 10 else _build_endless(wave, seed_value)
	encounter.sector = sector_for_wave(wave)
	encounter.wave = wave
	encounter.boss_variant = boss_variant_for_wave(wave)
	encounter.cursor = 0
	return encounter

static func spawn_instructions_due(encounter: Dictionary, elapsed_in_wave: float) -> Array:
	var result: Array = []
	var instructions: Array = encounter.get("instructions", [])
	var cursor := int(encounter.get("cursor", 0))
	while cursor < instructions.size() and float(instructions[cursor].get("at", 0.0)) <= elapsed_in_wave + 0.00001:
		result.append(instructions[cursor])
		cursor += 1
	encounter.cursor = cursor
	return result

static func wave_timing(seconds: float) -> Dictionary:
	var wave := get_run_level(seconds)
	var encounter := build_encounter(wave, 0)
	var sector := sector_for_wave(wave)
	return {"wave":wave, "phase":phase(seconds), "phase_remaining":phase_remaining(seconds), "spawn_interval":spawn_interval(wave), "normal_cap":MAX_NORMAL, "boss_cap":MAX_BOSSES, "boss_scheduled":wave % 10 == 0, "sector":sector.id, "sector_name":sector.name, "threat_tier":sector.threat_tier, "encounter_id":encounter.id, "boss_variant":boss_variant_for_wave(wave)}
