extends RefCounted

const PROFILE_PATH := "user://void_drifter_profile.json"
const Upgrades := preload("res://scripts/systems/upgrade_registry.gd")
const Cards := preload("res://scripts/systems/railgun_cards.gd")
const SAVE_VERSION := 5
const GAME_SPEEDS := [1, 2, 3, 4, 5, 10]

static func valid_speed(value: int) -> int:
	return value if value in GAME_SPEEDS else 1

var profile_path := PROFILE_PATH
var last_save_ok := true
const DEFAULT_PROFILE := {
	"saveVersion": SAVE_VERSION,
	"totalCoins": 0,
	"workshopSpent": 0.0,
	"railgunLevel": 1,
	"railgunPreservedUnlocks": [],
	"railgunModules": 0,
	"railgunCoinsSpent": 0,
	"railgunModulesSpent": 0,
	"totalKills": 0,
	"highestWave": 1,
	"bestScore": 0,
	"longestRunSeconds": 0,
	"runsPlayed": 0,
	"discoveredEnemies": [],
	"enemyKills": {},
	"permanentUpgrades": {},
	"autoDodgeUnlocked": false,
	"autoDodgeEnabled": true,
	"activeRun": {},
	"settledRunId": "",
	"unlockedWeapons": ["railgun"],
	"settings": {
		"screenShake": true,
		"autoCards": false,
		"gameSpeed": 1,
	},
	"lastRun": {},
	"updatedAtUnix": 0,
}

func load_profile() -> Dictionary:
	var parsed = _read_json(profile_path)
	if not parsed is Dictionary:
		parsed = _read_json(profile_path + ".bak")
	if not parsed is Dictionary:
		return _default_profile()
	var result := _sanitize_profile(parsed)
	if _looks_like_legacy_profile(parsed):
		result = _migrate_legacy_fields(result, parsed)
	if int(parsed.get("saveVersion", 0)) < 3:
		var old_upgrades: Dictionary = parsed.get("permanentUpgrades", {})
		var n := clampi(int(old_upgrades.get("xp_gain", 0)), 0, 5)
		result.totalCoins = float(result.totalCoins) + 25 * n + 35 * n * (n - 1) / 2
		# Keep the original migration source even after later rolling backups.
		if not FileAccess.file_exists(profile_path + ".v2.bak"):
			_write_json(profile_path + ".v2.bak", parsed)
	if not parsed.has("workshopSpent"):
		result.workshopSpent = _infer_workshop_spend(result, parsed)
	if int(parsed.get("saveVersion", 0)) < SAVE_VERSION or not parsed.has("workshopSpent"):
		save_profile(result)
	return result

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data

func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok

func save_profile(profile: Dictionary) -> bool:
	var sanitized := _sanitize_profile(profile)
	var temp := profile_path + ".tmp"
	last_save_ok = false
	if not _write_json(temp, sanitized):
		return false
	# Never replace the last good backup with an unreadable primary.
	if _read_json(profile_path) is Dictionary:
		if DirAccess.copy_absolute(profile_path, profile_path + ".bak") != OK:
			return false
	if DirAccess.rename_absolute(temp, profile_path) != OK:
		return false
	last_save_ok = true
	# Godot's web runtime uses IDBFS; explicitly request persistence after writes.
	if OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()
	return true

# Only plain data crosses the JSON boundary. Int RNG states are strings to avoid JSON precision loss.
static func encode(value: Variant) -> Variant:
	if value is Vector2:
		return {"__vector2": [value.x, value.y]}
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = encode(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value:
			result.append(encode(entry))
		return result
	return value

static func decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.has("__vector2"):
			return Vector2(float(value.__vector2[0]), float(value.__vector2[1]))
		var result := {}
		for key in value:
			result[key] = decode(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value:
			result.append(decode(entry))
		return result
	return value

func record_run(profile: Dictionary, run_summary: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile)
	var run_id := str(run_summary.get("run_id", ""))
	if run_id == "" or str(next.settledRunId) == run_id:
		return next
	next.settledRunId = run_id
	next.activeRun = {}
	var run_score := int(run_summary.get("score", 0))
	var run_kills := int(run_summary.get("kills", 0))
	var run_wave := int(run_summary.get("wave", 1))
	var run_time := int(run_summary.get("time_seconds", 0))
	var run_coins := float(run_summary.get("coins_earned", 0.0))
	var run_enemy_kills: Dictionary = run_summary.get("enemy_kills", {})
	var run_discovered: Array = run_summary.get("discovered_enemies", [])
	var new_records := {
		"bestScore": run_score > int(next.bestScore),
		"highestWave": run_wave > int(next.highestWave),
		"longestRunSeconds": run_time > int(next.longestRunSeconds),
	}

	next.totalCoins = float(next.totalCoins) + run_coins
	next.railgunModules += maxi(0, int(run_summary.get("modules_earned", 0)))
	next.totalKills = int(next.totalKills) + run_kills
	next.highestWave = maxi(int(next.highestWave), run_wave)
	next.bestScore = maxi(int(next.bestScore), run_score)
	next.longestRunSeconds = maxi(int(next.longestRunSeconds), run_time)
	next.runsPlayed = int(next.runsPlayed) + 1
	next.discoveredEnemies = _merge_string_array(next.discoveredEnemies, run_discovered)
	next.enemyKills = _merge_enemy_kills(next.enemyKills, run_enemy_kills)
	next.lastRun = {
		"score": run_score,
		"kills": run_kills,
		"wave": run_wave,
		"timeSeconds": run_time,
		"coinsEarned": run_coins,
		"modulesEarned": maxi(0, int(run_summary.get("modules_earned", 0))),
		"newRecords": new_records,
	}
	next.updatedAtUnix = int(Time.get_unix_time_from_system())

	save_profile(next)
	return next

func _default_profile() -> Dictionary:
	var result := DEFAULT_PROFILE.duplicate(true)
	result.permanentUpgrades = Upgrades.defaults()
	return result

func _sanitize_profile(profile: Dictionary) -> Dictionary:
	var sanitized := _default_profile()
	sanitized.saveVersion = SAVE_VERSION
	for key in ["totalKills", "highestWave", "bestScore", "longestRunSeconds", "runsPlayed", "updatedAtUnix"]:
		if profile.has(key):
			sanitized[key] = int(profile[key])

	if profile.has("discoveredEnemies") and profile.discoveredEnemies is Array:
		sanitized.discoveredEnemies = _unique_string_array(profile.discoveredEnemies)
	if profile.has("enemyKills") and profile.enemyKills is Dictionary:
		for enemy_id in profile.enemyKills.keys():
			sanitized.enemyKills[str(enemy_id)] = int(profile.enemyKills[enemy_id])
	if profile.has("permanentUpgrades") and profile.permanentUpgrades is Dictionary:
		for upgrade_id in Upgrades.defaults():
			sanitized.permanentUpgrades[upgrade_id] = clampi(int(profile.permanentUpgrades.get(upgrade_id, 0)), 0, int(Upgrades.definition(str(upgrade_id)).cap))
	if profile.has("unlockedWeapons") and profile.unlockedWeapons is Array:
		sanitized.unlockedWeapons = _unique_string_array(profile.unlockedWeapons)
		sanitized.unlockedWeapons.erase("pulse_cannon")
		if not sanitized.unlockedWeapons.has("railgun"):
			sanitized.unlockedWeapons.insert(0, "railgun")
	if profile.has("settings") and profile.settings is Dictionary:
		sanitized.settings.autoCards = bool(profile.settings.get("autoCards", false))
		sanitized.settings.screenShake = bool(profile.settings.get("screenShake", true))
		sanitized.settings.gameSpeed = valid_speed(int(profile.settings.get("gameSpeed", 1)))
	if profile.has("lastRun") and profile.lastRun is Dictionary:
		sanitized.lastRun = profile.lastRun.duplicate(true)

	sanitized.railgunLevel = clampi(int(profile.get("railgunLevel", 1)), 1, Cards.MAX_LEVEL)
	var legacy_unlocks := {"caliber":2,"shredder":4,"critical":6,"shatter":8,"rampage":10}
	var preserved: Array = profile.get("railgunPreservedUnlocks",[]) if profile.get("railgunPreservedUnlocks",[]) is Array else []
	for id in legacy_unlocks:
		if preserved.has(id) or (int(profile.get("saveVersion",0)) < 5 and sanitized.railgunLevel >= legacy_unlocks[id]):
			sanitized.railgunPreservedUnlocks.append(id)
	for key in ["railgunModules", "railgunCoinsSpent", "railgunModulesSpent"]:
		sanitized[key] = maxi(0, int(profile.get(key, 0)))
	sanitized.totalCoins = maxf(0.0, float(profile.get("totalCoins", 0.0)))
	sanitized.workshopSpent = maxf(0.0, float(profile.get("workshopSpent", 0.0)))
	sanitized.autoDodgeUnlocked = bool(profile.get("autoDodgeUnlocked", false))
	sanitized.autoDodgeEnabled = bool(profile.get("autoDodgeEnabled", true))
	sanitized.settledRunId = str(profile.get("settledRunId", ""))
	if profile.get("activeRun", {}) is Dictionary:
		sanitized.activeRun = profile.get("activeRun", {}).duplicate(true)
	return sanitized

func _looks_like_legacy_profile(profile: Dictionary) -> bool:
	return profile.has("lifetime_score") or profile.has("lifetime_kills") or profile.has("total_runs")

func _migrate_legacy_fields(profile: Dictionary, legacy: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile)
	if int(next.bestScore) == 0:
		next.bestScore = int(legacy.get("best_score", 0))
	if int(next.longestRunSeconds) == 0:
		next.longestRunSeconds = int(legacy.get("best_time_seconds", 0))
	if int(next.highestWave) <= 1:
		next.highestWave = maxi(1, int(legacy.get("best_wave", 1)))
	if int(next.totalKills) == 0:
		next.totalKills = int(legacy.get("lifetime_kills", 0))
	if int(next.runsPlayed) == 0:
		next.runsPlayed = int(legacy.get("total_runs", 0))
	if next.lastRun.is_empty():
		next.lastRun = {
			"score": int(legacy.get("last_run_score", 0)),
			"kills": int(legacy.get("last_run_kills", 0)),
			"wave": int(legacy.get("last_run_wave", 1)),
			"timeSeconds": int(legacy.get("last_run_time_seconds", 0)),
			"coinsEarned": 0,
			"newRecords": {},
		}
	return next

func _unique_string_array(values: Array) -> Array:
	var seen := {}
	var result := []
	for value in values:
		var key := str(value)
		if key == "" or seen.has(key):
			continue
		seen[key] = true
		result.append(key)
	return result

func _merge_string_array(existing: Array, incoming: Array) -> Array:
	var merged := _unique_string_array(existing)
	var seen := {}
	for value in merged:
		seen[str(value)] = true
	for value in incoming:
		var key := str(value)
		if key == "" or seen.has(key):
			continue
		seen[key] = true
		merged.append(key)
	return merged

func _merge_enemy_kills(existing: Dictionary, incoming: Dictionary) -> Dictionary:
	var merged := {}
	for enemy_id in existing.keys():
		merged[str(enemy_id)] = int(existing[enemy_id])
	for enemy_id in incoming.keys():
		var key := str(enemy_id)
		merged[key] = int(merged.get(key, 0)) + int(incoming[enemy_id])
	return merged

func workshop_refund(profile: Dictionary) -> float:
	return maxf(0.0, float(profile.get("workshopSpent", 0.0)))

func _infer_workshop_spend(profile: Dictionary, original: Dictionary) -> float:
	var spent := 1000.0 if bool(profile.get("autoDodgeUnlocked", false)) else 0.0
	var legacy = original if int(original.get("saveVersion", 0)) < 3 else _read_json(profile_path + ".v2.bak")
	var old_levels: Dictionary = legacy.get("permanentUpgrades", {}) if legacy is Dictionary else {}
	for id in Upgrades.defaults():
		var levels := int(profile.permanentUpgrades.get(id, 0))
		var old_count := mini(levels, clampi(int(old_levels.get(id, 0)), 0, 5))
		for level in range(levels):
			# The retained pre-v3 backup identifies levels bought at the old linear price.
			spent += 25 + 35 * level if level < old_count else Upgrades.cost(level, true)
	return spent

func reset_workshop(profile: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile)
	if not next.activeRun.is_empty():
		return next
	next.totalCoins = float(next.totalCoins) + workshop_refund(next)
	next.permanentUpgrades = Upgrades.defaults()
	next.workshopSpent = 0.0
	next.autoDodgeUnlocked = false
	next.autoDodgeEnabled = true
	save_profile(next)
	return next
