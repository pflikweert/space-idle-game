extends RefCounted

const SPAWN_SECONDS := 26.0
const COOLDOWN_SECONDS := 9.0
const WAVE_SECONDS := SPAWN_SECONDS + COOLDOWN_SECONDS
const MAX_NORMAL := 40
const MAX_BOSSES := 4

static func get_run_level(seconds: float) -> int:
	return 1 + int(floor(seconds / WAVE_SECONDS))

static func phase(seconds: float) -> String:
	return "spawning" if fmod(seconds, WAVE_SECONDS) < SPAWN_SECONDS else "cooldown"

static func phase_remaining(seconds: float) -> float:
	var cycle_seconds := fmod(maxf(0.0, seconds), WAVE_SECONDS)
	return (SPAWN_SECONDS - cycle_seconds) if cycle_seconds < SPAWN_SECONDS else (WAVE_SECONDS - cycle_seconds)

static func wave_timing(seconds: float) -> Dictionary:
	var wave := get_run_level(seconds)
	return {
		"wave": wave,
		"phase": phase(seconds),
		"phase_remaining": phase_remaining(seconds),
		"spawn_interval": spawn_interval(wave),
		"normal_cap": MAX_NORMAL,
		"boss_cap": MAX_BOSSES,
		"boss_scheduled": wave % 10 == 0,
	}

static func spawn_interval(wave: int) -> float:
	return maxf(0.45, 1.10 - float(wave - 1) * 0.02)
