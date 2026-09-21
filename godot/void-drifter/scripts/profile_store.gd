extends RefCounted

const PROFILE_PATH := "user://void_drifter_profile.json"
const Upgrades := preload("res://scripts/systems/upgrade_registry.gd")
const Cards := preload("res://scripts/systems/railgun_cards.gd")
const Ships := preload("res://scripts/systems/ship_registry.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Loadouts := preload("res://scripts/systems/loadout_system.gd")
const Progression := preload("res://scripts/systems/module_progression.gd")
const SAVE_VERSION := 11
const GAME_SPEEDS := [1, 2, 3, 4, 5, 10]

static func valid_speed(value: int) -> int:
	return value if value in GAME_SPEEDS else 1

var profile_path := PROFILE_PATH
var last_save_ok := true

func load_profile() -> Dictionary:
	var primary = _read_json(profile_path)
	if primary is Dictionary and int(primary.get("saveVersion", 0)) == SAVE_VERSION:
		return _sanitize_profile(primary)
	if primary is Dictionary and int(primary.get("saveVersion", 0)) == SAVE_VERSION - 1:
		var migrated := _migrate_stat_architecture_profile(_migrate_shield_core_profile(primary))
		var clean_migrated := _sanitize_profile(migrated)
		save_profile(clean_migrated)
		return clean_migrated
	if primary is Dictionary and int(primary.get("saveVersion", 0)) == SAVE_VERSION - 2:
		var upgraded := _migrate_stat_architecture_profile(_migrate_shield_core_profile(_migrate_cardless_profile(primary)))
		var clean_upgraded := _sanitize_profile(upgraded)
		save_profile(clean_upgraded)
		return clean_upgraded
	if primary is Dictionary and int(primary.get("saveVersion", 0)) == SAVE_VERSION - 3:
		var legacy_upgraded := _migrate_stat_architecture_profile(_migrate_shield_core_profile(_migrate_cardless_profile(_migrate_progression_profile(primary))))
		var clean_legacy_upgraded := _sanitize_profile(legacy_upgraded)
		save_profile(clean_legacy_upgraded)
		return clean_legacy_upgraded
	# During development, schemas older than the immediately previous version are reset.
	if primary is Dictionary: return _reset_to_current_profile()
	var backup = _read_json(profile_path + ".bak")
	if backup is Dictionary and int(backup.get("saveVersion", 0)) == SAVE_VERSION:
		var recovered := _sanitize_profile(backup)
		save_profile(recovered)
		return recovered
	if backup is Dictionary and int(backup.get("saveVersion", 0)) == SAVE_VERSION - 1:
		var migrated_backup := _sanitize_profile(_migrate_stat_architecture_profile(_migrate_shield_core_profile(backup)))
		save_profile(migrated_backup)
		return migrated_backup
	if backup is Dictionary and int(backup.get("saveVersion", 0)) == SAVE_VERSION - 2:
		var upgraded_backup := _sanitize_profile(_migrate_stat_architecture_profile(_migrate_shield_core_profile(_migrate_cardless_profile(backup))))
		save_profile(upgraded_backup)
		return upgraded_backup
	if backup is Dictionary and int(backup.get("saveVersion", 0)) == SAVE_VERSION - 3:
		var legacy_upgraded_backup := _sanitize_profile(_migrate_stat_architecture_profile(_migrate_shield_core_profile(_migrate_cardless_profile(_migrate_progression_profile(backup)))))
		save_profile(legacy_upgraded_backup)
		return legacy_upgraded_backup
	return _reset_to_current_profile()

func _migrate_progression_profile(profile: Dictionary) -> Dictionary:
	var migrated: Dictionary = _normalize_railgun_ids(profile.duplicate(true))
	# Version 8 adds item-local rarity, XP and milestone state. Existing items
	# remain Common at their current level; no player value is spent or removed.
	var supplied_items: Dictionary = migrated.get("equipmentItems", {}) if migrated.get("equipmentItems", {}) is Dictionary else {}
	for raw_instance_id in supplied_items:
		var item: Dictionary = supplied_items[raw_instance_id] if supplied_items[raw_instance_id] is Dictionary else {}
		var blueprint_id := _canonical_railgun_id(str(item.get("blueprint_id", "")))
		if Equipment.definition(blueprint_id).is_empty(): continue
		item.id = _canonical_railgun_id(str(item.get("id", raw_instance_id)))
		item.blueprint_id = blueprint_id
		supplied_items[_canonical_railgun_id(str(raw_instance_id))] = Equipment.sanitize_instance(item)
	migrated.equipmentItems = supplied_items
	if not migrated.has("rarityBlueprints") or not migrated.rarityBlueprints is Dictionary:
		migrated.rarityBlueprints = {"rare_blueprint":0,"epic_blueprint":0,"legendary_blueprint":0}
	migrated.saveVersion = SAVE_VERSION
	return migrated

func _migrate_cardless_profile(profile: Dictionary) -> Dictionary:
	var migrated := profile.duplicate(true)
	var settings: Dictionary = migrated.get("settings", {}) if migrated.get("settings", {}) is Dictionary else {}
	settings.erase("autoCards")
	migrated.settings = settings
	var active_run: Dictionary = migrated.get("activeRun", {}) if migrated.get("activeRun", {}) is Dictionary else {}
	var card_state: Dictionary = active_run.get("cards", {}) if active_run.get("cards", {}) is Dictionary else {}
	var ranks: Dictionary = card_state.get("ranks", {}) if card_state.get("ranks", {}) is Dictionary else {}
	var rank_total := 0
	for rank in ranks.values(): rank_total += maxi(0, int(rank))
	# Card ranks were temporary. Preserve their earned value as banked upgrade
	# modules and Railgun XP before removing their run-only state.
	if not active_run.is_empty():
		migrated.railgunModules = maxi(0, int(migrated.get("railgunModules", 0))) + maxi(0, int(card_state.get("modules", 0))) + rank_total
		active_run.erase("cards")
		migrated.activeRun = active_run
	var items: Dictionary = migrated.get("equipmentItems", {}) if migrated.get("equipmentItems", {}) is Dictionary else {}
	var railgun: Dictionary = items.get(Equipment.RAILGUN_INSTANCE_ID, {}) if items.get(Equipment.RAILGUN_INSTANCE_ID, {}) is Dictionary else {}
	if not railgun.is_empty() and rank_total > 0:
		railgun.xp = maxi(0, int(railgun.get("xp", 0))) + rank_total * 80
		items[Equipment.RAILGUN_INSTANCE_ID] = railgun
		migrated.equipmentItems = items
	migrated.saveVersion = 9
	return migrated

func _migrate_shield_core_profile(profile: Dictionary) -> Dictionary:
	var migrated := profile.duplicate(true)
	var permanent: Dictionary = migrated.get("permanentUpgrades", {}) if migrated.get("permanentUpgrades", {}) is Dictionary else {}
	var capacity_levels := maxi(0,int(permanent.get("shield_capacity",0)))
	var recharge_levels := maxi(0,int(permanent.get("shield_recharge",0)))
	permanent.erase("shield_capacity")
	permanent.erase("shield_recharge")
	migrated.permanentUpgrades = permanent
	var items: Dictionary = migrated.get("equipmentItems", {}) if migrated.get("equipmentItems", {}) is Dictionary else {}
	var core: Dictionary = items.get(Equipment.SHIELD_CORE_INSTANCE_ID,{}) if items.get(Equipment.SHIELD_CORE_INSTANCE_ID,{}) is Dictionary else Equipment.new_instance(Equipment.SHIELD_CORE_INSTANCE_ID,Equipment.SHIELD_CORE_ID)
	core.legacy_capacity_bonus = maxf(0.0,float(core.get("legacy_capacity_bonus",0.0))) + 10.0 * capacity_levels
	core.legacy_recharge_bonus = maxf(0.0,float(core.get("legacy_recharge_bonus",0.0))) + 0.5 * recharge_levels
	items[Equipment.SHIELD_CORE_INSTANCE_ID] = core
	migrated.equipmentItems = items
	migrated.saveVersion = SAVE_VERSION
	return migrated

func _migrate_stat_architecture_profile(profile: Dictionary) -> Dictionary:
	var migrated := profile.duplicate(true)
	var permanent: Dictionary = migrated.get("permanentUpgrades", {}) if migrated.get("permanentUpgrades", {}) is Dictionary else {}
	# Fire Rate is now owned by each weapon module. It cannot be kept as a
	# global Workshop level without changing the meaning of existing saves.
	permanent.erase("fire_rate")
	migrated.permanentUpgrades = permanent
	var active_run: Dictionary = migrated.get("activeRun", {}) if migrated.get("activeRun", {}) is Dictionary else {}
	var card_state: Dictionary = active_run.get("cards", {}) if active_run.get("cards", {}) is Dictionary else {}
	if not card_state.is_empty():
		migrated.railgunModules = maxi(0, int(migrated.get("railgunModules", 0))) + maxi(0, int(card_state.get("modules", 0)))
		active_run.erase("cards")
		migrated.activeRun = active_run
	migrated.saveVersion = SAVE_VERSION
	return migrated

func _normalize_railgun_ids(value: Variant) -> Variant:
	if value is Array:
		var normalized_array: Array = []
		for entry in value: normalized_array.append(_normalize_railgun_ids(entry))
		return normalized_array
	if value is Dictionary:
		var normalized: Dictionary = {}
		for raw_key in value:
			var key := _canonical_railgun_id(str(raw_key))
			var normalized_value: Variant = _normalize_railgun_ids(value[raw_key])
			if normalized.has(key) and normalized[key] is Dictionary and normalized_value is Dictionary:
				var merged: Dictionary = normalized[key].duplicate(true)
				for field in normalized_value: merged[field] = normalized_value[field]
				normalized[key] = merged
			else: normalized[key] = normalized_value
		return normalized
	if value is String: return _canonical_railgun_id(value)
	return value

func _canonical_railgun_id(value: String) -> String:
	if value == Equipment.LEGACY_STARTER_RAILGUN_ID: return Equipment.RAILGUN_ID
	if value == Equipment.LEGACY_STARTER_RAILGUN_INSTANCE_ID: return Equipment.RAILGUN_INSTANCE_ID
	if value == Equipment.LEGACY_AUXILIARY_RAILGUN_ID: return Equipment.RAILGUN_ID
	if value.begins_with("auxiliary-railgun-"):
		var suffix := value.trim_prefix("auxiliary-railgun-")
		if suffix.is_valid_int(): return "railgun-%03d" % (int(suffix) + 1)
	return value

func _reset_to_current_profile() -> Dictionary:
	var fresh := _default_profile()
	last_save_ok = _write_json(profile_path, fresh) and _write_json(profile_path + ".bak", fresh)
	if last_save_ok and OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
	return fresh

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return null
	return parser.data

func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data)); file.flush()
	var ok := file.get_error() == OK; file.close()
	return ok

func save_profile(profile: Dictionary) -> bool:
	var sanitized := _sanitize_profile(profile); var temp := profile_path + ".tmp"; last_save_ok = false
	if not _write_json(temp, sanitized): return false
	var current = _read_json(profile_path)
	if current is Dictionary and int(current.get("saveVersion",0)) == SAVE_VERSION:
		if DirAccess.copy_absolute(profile_path, profile_path + ".bak") != OK: return false
	if DirAccess.rename_absolute(temp, profile_path) != OK: return false
	last_save_ok = true
	if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
	return true

static func encode(value: Variant) -> Variant:
	if value is Vector2: return {"__vector2":[value.x,value.y]}
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = encode(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value: result.append(encode(entry))
		return result
	return value

static func decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.has("__vector2"): return Vector2(float(value.__vector2[0]),float(value.__vector2[1]))
		var result := {}
		for key in value: result[key] = decode(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value: result.append(decode(entry))
		return result
	return value

func _default_profile() -> Dictionary:
	return {
		"saveVersion":SAVE_VERSION,"totalCoins":0.0,"workshopSpent":0.0,"railgunModules":0,
		"totalKills":0,"highestWave":1,"bestScore":0,"longestRunSeconds":0,"runsPlayed":0,
		"discoveredEnemies":[],"enemyKills":{},"permanentUpgrades":Upgrades.defaults(),
		"autoDodgeUnlocked":false,"autoDodgeEnabled":true,"activeRun":{},"settledRunId":"",
		"unlockedShips":[Ships.STARTER_SHIP_ID],"activeShipId":Ships.STARTER_SHIP_ID,
		"ships":{Ships.STARTER_SHIP_ID:Loadouts.starter_ship_state()},
		"unlockedEquipmentBlueprints":[Equipment.RAILGUN_ID,Equipment.SHIELD_CORE_ID],
		"rarityBlueprints":{"rare_blueprint":0,"epic_blueprint":0,"legendary_blueprint":0},
		"equipmentItems":Equipment.starter_instances(),
		"equipmentInventory":[Equipment.RAILGUN_INSTANCE_ID,Equipment.SHIELD_CORE_INSTANCE_ID],
		"settings":{"screenShake":true,"gameSpeed":1},"lastRun":{},"updatedAtUnix":0,
	}

func _sanitize_profile(profile: Dictionary) -> Dictionary:
	var clean := _default_profile()
	for key in ["totalKills","highestWave","bestScore","longestRunSeconds","runsPlayed","updatedAtUnix","railgunModules"]:
		clean[key] = maxi(0,int(profile.get(key,clean[key])))
	clean.highestWave = maxi(1,clean.highestWave)
	clean.totalCoins = maxf(0.0,float(profile.get("totalCoins",0.0)))
	clean.workshopSpent = maxf(0.0,float(profile.get("workshopSpent",0.0)))
	clean.autoDodgeUnlocked = bool(profile.get("autoDodgeUnlocked",false)); clean.autoDodgeEnabled = bool(profile.get("autoDodgeEnabled",true))
	clean.settledRunId = str(profile.get("settledRunId",""))
	var unlocked_blueprints = profile.get("unlockedEquipmentBlueprints",[])
	if unlocked_blueprints is Array:
		var normalized_blueprints: Array = []
		for blueprint_id in unlocked_blueprints: normalized_blueprints.append(_canonical_railgun_id(str(blueprint_id)))
		clean.unlockedEquipmentBlueprints = _unique_string_array(normalized_blueprints).filter(func(id): return not Equipment.definition(str(id)).is_empty())
	var rarity_blueprints = profile.get("rarityBlueprints",{})
	if rarity_blueprints is Dictionary:
		for rarity in Progression.BLUEPRINT_IDS:
			var blueprint_id := str(Progression.BLUEPRINT_IDS[rarity])
			clean.rarityBlueprints[blueprint_id] = maxi(0,int(rarity_blueprints.get(blueprint_id,0)))
	var discovered = profile.get("discoveredEnemies",[])
	if discovered is Array: clean.discoveredEnemies = _unique_string_array(discovered)
	var enemy_kills = profile.get("enemyKills",{})
	if enemy_kills is Dictionary:
		clean.enemyKills = {}
		for id in enemy_kills: clean.enemyKills[str(id)] = maxi(0,int(enemy_kills[id]))
	var permanent = profile.get("permanentUpgrades",{})
	if permanent is Dictionary:
		for id in Upgrades.defaults(): clean.permanentUpgrades[id] = clampi(int(permanent.get(id,0)),0,int(Upgrades.definition(str(id)).cap))
	var settings = profile.get("settings",{})
	if settings is Dictionary:
		clean.settings.screenShake = bool(settings.get("screenShake",true)); clean.settings.gameSpeed = valid_speed(int(settings.get("gameSpeed",1)))
	var last_run = profile.get("lastRun",{})
	if last_run is Dictionary: clean.lastRun = last_run.duplicate(true)
	var active_run = profile.get("activeRun",{})
	if active_run is Dictionary: clean.activeRun = _normalize_railgun_ids(active_run.duplicate(true))
	var supplied_items: Dictionary = profile.get("equipmentItems",{}) if profile.get("equipmentItems",{}) is Dictionary else {}
	clean.equipmentItems = {}
	for raw_instance_id in supplied_items:
		var instance_id := _canonical_railgun_id(str(raw_instance_id))
		var item: Dictionary = supplied_items[raw_instance_id] if supplied_items[raw_instance_id] is Dictionary else {}
		var blueprint_id := _canonical_railgun_id(str(item.get("blueprint_id","")))
		if Equipment.definition(blueprint_id).is_empty(): continue
		item.id = instance_id
		item.blueprint_id = blueprint_id
		item.coins_spent = maxi(0,int(item.get("coins_spent",0)))
		item.modules_spent = maxi(0,int(item.get("modules_spent",0)))
		clean.equipmentItems[instance_id] = Equipment.sanitize_instance(item)
	for instance_id in Equipment.starter_instances():
		if not clean.equipmentItems.has(instance_id): clean.equipmentItems[instance_id] = Equipment.starter_instances()[instance_id]
	clean.equipmentInventory = clean.equipmentItems.keys()
	var supplied_state: Dictionary = profile.get("ships",{}).get(Ships.STARTER_SHIP_ID,{}) if profile.get("ships",{}) is Dictionary else {}
	var ship_state := Loadouts.starter_ship_state()
	ship_state.upgrade_level = clampi(int(supplied_state.get("upgrade_level",0)),0,Ships.SHIP_LEVEL_CAP); ship_state.mastery_level = maxi(0,int(supplied_state.get("mastery_level",0))); ship_state.mastery_xp = maxi(0,int(supplied_state.get("mastery_xp",0)))
	var candidate: Dictionary = supplied_state.get("loadout",ship_state.loadout) if supplied_state.get("loadout",{}) is Dictionary else ship_state.loadout
	for slot_id in candidate: candidate[slot_id] = _canonical_railgun_id(str(candidate[slot_id]))
	ship_state.loadout = Loadouts.validate(Ships.STARTER_SHIP_ID,candidate,clean.equipmentItems).loadout
	var supplied_enabled: Dictionary = supplied_state.get("slot_enabled",{}) if supplied_state.get("slot_enabled",{}) is Dictionary else {}
	ship_state.slot_enabled = {}
	for hardpoint in Ships.definition(Ships.STARTER_SHIP_ID).get("slots",[]):
		var slot_id := str(hardpoint.get("id",""))
		ship_state.slot_enabled[slot_id] = bool(supplied_enabled.get(slot_id,true))
	clean.ships = {Ships.STARTER_SHIP_ID:ship_state}
	return clean

func record_run(profile: Dictionary, run_summary: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile); var run_id := str(run_summary.get("run_id",""))
	if run_id == "" or str(next.settledRunId) == run_id: return next
	next.settledRunId = run_id; next.activeRun = {}
	var run_score := int(run_summary.get("score",0)); var run_kills := int(run_summary.get("kills",0)); var run_wave := int(run_summary.get("wave",1)); var run_time := int(run_summary.get("time_seconds",0)); var run_coins := float(run_summary.get("coins_earned",0.0))
	var records := {"bestScore":run_score>int(next.bestScore),"highestWave":run_wave>int(next.highestWave),"longestRunSeconds":run_time>int(next.longestRunSeconds)}
	next.totalCoins += run_coins; next.railgunModules += maxi(0,int(run_summary.get("modules_earned",0))); next.totalKills += run_kills; next.highestWave = maxi(next.highestWave,run_wave); next.bestScore = maxi(next.bestScore,run_score); next.longestRunSeconds = maxi(next.longestRunSeconds,run_time); next.runsPlayed += 1
	next.discoveredEnemies = _unique_string_array(next.discoveredEnemies + run_summary.get("discovered_enemies",[]))
	for id in run_summary.get("enemy_kills",{}): next.enemyKills[str(id)] = int(next.enemyKills.get(str(id),0))+int(run_summary.enemy_kills[id])
	var new_blueprints: Array = []
	for blueprint_id in run_summary.get("new_blueprints",[]):
		var id := str(blueprint_id)
		if id == "" or next.unlockedEquipmentBlueprints.has(id) or Equipment.definition(id).is_empty(): continue
		new_blueprints.append(id)
		next.unlockedEquipmentBlueprints.append(id)
	if int(next.enemyKills.get("armored_drone",0)) > 0 and not next.unlockedEquipmentBlueprints.has(Equipment.MICRO_MISSILE_RACK_ID):
		new_blueprints.append(Equipment.MICRO_MISSILE_RACK_ID)
		next.unlockedEquipmentBlueprints.append(Equipment.MICRO_MISSILE_RACK_ID)
	next.lastRun = {"score":run_score,"kills":run_kills,"wave":run_wave,"timeSeconds":run_time,"coinsEarned":run_coins,"modulesEarned":maxi(0,int(run_summary.get("modules_earned",0))),"newRecords":records,"newBlueprints":new_blueprints}; next.updatedAtUnix = int(Time.get_unix_time_from_system())
	save_profile(next); return next

func _unique_string_array(values: Array) -> Array:
	var seen := {}; var result := []
	for value in values:
		var key := str(value)
		if key == "" or seen.has(key): continue
		seen[key] = true; result.append(key)
	return result

func workshop_refund(profile: Dictionary) -> float: return maxf(0.0,float(profile.get("workshopSpent",0.0)))

func reset_workshop(profile: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile)
	if not next.activeRun.is_empty(): return next
	next.totalCoins += workshop_refund(next); next.permanentUpgrades = Upgrades.defaults(); next.workshopSpent = 0.0; next.autoDodgeUnlocked = false; next.autoDodgeEnabled = true
	save_profile(next); return next
