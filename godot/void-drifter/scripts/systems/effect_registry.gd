extends RefCounted

const MAX_EFFECTS := 170
const DEFINITIONS := {
	"enemy_trace": {"frames": 0, "duration": 0.09, "scale": 1.0, "layer": "front", "priority": 2},
	"enemy_muzzle": {"frames": 0, "duration": 0.16, "scale": 1.0, "layer": "front", "priority": 2},
	"explosion": {"frames": 8, "duration": 0.35, "scale": 1.0, "layer": "front", "priority": 2},
	"boss_explosion": {"frames": 8, "duration": 0.6, "scale": 1.6, "layer": "front", "priority": 3},
	"rail_impact": {"frames": 4, "duration": 0.16, "scale": 1.0, "layer": "front", "priority": 2},
	"railgun_void_burst": {"frames": 8, "duration": 0.30, "scale": 0.86, "layer": "front", "priority": 3},
	"railgun_shatter_split": {"frames": 8, "duration": 0.20, "scale": 0.50, "layer": "front", "priority": 2},
	"missile_impact": {"frames": 0, "duration": 0.20, "scale": 1.0, "layer": "front", "priority": 2},
	"missile_explosion": {"frames": 8, "duration": 0.34, "scale": 1.0, "layer": "front", "priority": 2},
	"small_missile_explosion": {"frames": 8, "duration": 0.25, "scale": 0.58, "layer": "front", "priority": 2},
	"shatter_burst": {"frames": 8, "duration": 0.32, "scale": 0.92, "layer": "front", "priority": 3},
	"echo_detonation": {"frames": 8, "duration": 0.42, "scale": 1.0, "layer": "front", "priority": 3},
	"enemy_missile_impact": {"frames": 0, "duration": 0.20, "scale": 1.0, "layer": "front", "priority": 2},
	"rail_trace": {"frames": 4, "duration": 0.045, "scale": 1.0, "layer": "front", "priority": 1},
	"debris": {"frames": 0, "duration": 0.65, "scale": 1.0, "layer": "back", "priority": 0},
}

static func frame_index(progress: float, count := 8) -> int:
	return clampi(int(progress * count), 0, count - 1)

static func make(kind: String, position: Vector2, height := 1.0, delay := 0.0) -> Dictionary:
	var spec: Dictionary = DEFINITIONS[kind]
	return {"kind": kind, "position": position, "height": height * spec.scale,
		"life": spec.duration, "max_life": spec.duration, "delay": delay,
		"layer": spec.layer, "priority": spec.priority}
