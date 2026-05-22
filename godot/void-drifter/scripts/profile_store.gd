extends RefCounted

const PROFILE_PATH := "user://void_drifter_profile.json"
const DEFAULT_PERMANENT_UPGRADES := {
	"damage": 0,
	"fire_rate": 0,
	"max_hp": 0,
	"xp_gain": 0,
	"coin_bonus": 0,
}
const DEFAULT_PROFILE := {
	"totalCoins": 0,
	"totalKills": 0,
	"highestWave": 1,
	"bestScore": 0,
	"longestRunSeconds": 0,
	"runsPlayed": 0,
	"discoveredEnemies": [],
	"enemyKills": {},
	"permanentUpgrades": DEFAULT_PERMANENT_UPGRADES,
	"lastRun": {},
	"updatedAtUnix": 0,
}

func load_profile() -> Dictionary:
	var profile := _default_profile()
	if not FileAccess.file_exists(PROFILE_PATH):
		save_profile(profile)
		return profile

	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return profile

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		profile = _sanitize_profile(parsed)
		if _looks_like_legacy_profile(parsed):
			profile = _migrate_legacy_fields(profile, parsed)
	return profile

func save_profile(profile: Dictionary) -> void:
	var sanitized := _sanitize_profile(profile)
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write VOID DRIFTER profile.")
		return

	file.store_string(JSON.stringify(sanitized, "\t"))

func record_run(profile: Dictionary, run_summary: Dictionary) -> Dictionary:
	var next := _sanitize_profile(profile)
	var run_score := int(run_summary.get("score", 0))
	var run_kills := int(run_summary.get("kills", 0))
	var run_wave := int(run_summary.get("wave", 1))
	var run_time := int(run_summary.get("time_seconds", 0))
	var run_coins := int(run_summary.get("coins_earned", 0))
	var run_enemy_kills: Dictionary = run_summary.get("enemy_kills", {})
	var run_discovered: Array = run_summary.get("discovered_enemies", [])
	var new_records := {
		"bestScore": run_score > int(next.bestScore),
		"highestWave": run_wave > int(next.highestWave),
		"longestRunSeconds": run_time > int(next.longestRunSeconds),
	}

	next.totalCoins = int(next.totalCoins) + run_coins
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
		"newRecords": new_records,
	}
	next.updatedAtUnix = int(Time.get_unix_time_from_system())

	save_profile(next)
	return next

func _default_profile() -> Dictionary:
	return DEFAULT_PROFILE.duplicate(true)

func _sanitize_profile(profile: Dictionary) -> Dictionary:
	var sanitized := _default_profile()
	for key in ["totalCoins", "totalKills", "highestWave", "bestScore", "longestRunSeconds", "runsPlayed", "updatedAtUnix"]:
		if profile.has(key):
			sanitized[key] = int(profile[key])

	if profile.has("discoveredEnemies") and profile.discoveredEnemies is Array:
		sanitized.discoveredEnemies = _unique_string_array(profile.discoveredEnemies)
	if profile.has("enemyKills") and profile.enemyKills is Dictionary:
		for enemy_id in profile.enemyKills.keys():
			sanitized.enemyKills[str(enemy_id)] = int(profile.enemyKills[enemy_id])
	if profile.has("permanentUpgrades") and profile.permanentUpgrades is Dictionary:
		for upgrade_id in DEFAULT_PERMANENT_UPGRADES.keys():
			sanitized.permanentUpgrades[upgrade_id] = clampi(int(profile.permanentUpgrades.get(upgrade_id, 0)), 0, 5)
	if profile.has("lastRun") and profile.lastRun is Dictionary:
		sanitized.lastRun = profile.lastRun.duplicate(true)

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
