extends RefCounted

const SHOOT := "shoot"
const HIT := "hit"
const ENEMY_DEATH := "enemy_death"
const PICKUP := "pickup"
const LEVEL_UP := "level_up"
const ELITE_SPAWN := "elite_spawn"
const WAVE_CLEAR := "wave_clear"
const PLAYER_DAMAGE := "player_damage"
const DEATH := "death"

var recent_events: Array[Dictionary] = []

func emit(event_name: String, payload := {}) -> void:
	recent_events.append({
		"name": event_name,
		"payload": payload,
		"time_msec": Time.get_ticks_msec(),
	})
	if recent_events.size() > 48:
		recent_events.pop_front()

func drain() -> Array[Dictionary]:
	var drained := recent_events.duplicate(true)
	recent_events.clear()
	return drained
