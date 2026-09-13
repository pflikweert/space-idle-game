extends RefCounted

const BASE_MAGNET_RADIUS := 94.0
const VACUUM_RADIUS := 24.0
const MAX_PICKUPS := 120

const TYPES := {
	"xp": { "label": "XP", "radius": 5.0, "color": Color("#00e5ff"), "glow": Color("#67e8f9") },
	"coin": { "label": "C", "radius": 5.5, "color": Color("#facc15"), "glow": Color("#ff6d00") },
	"health": { "label": "+", "radius": 7.0, "color": Color("#00e676"), "glow": Color("#34d399") },
	"buff": { "label": "*", "radius": 7.0, "color": Color("#ff00ff"), "glow": Color("#ff7cff") },
}

static func create_pickup(id: int, pickup_type: String, position: Vector2, amount: int) -> Dictionary:
	var definition: Dictionary = TYPES.get(pickup_type, TYPES.xp)
	return {
		"id": id,
		"type": pickup_type,
		"position": position,
		"velocity": Vector2.ZERO,
		"amount": amount,
		"radius": float(definition.radius),
		"age": 0.0,
		"life": 24.0,
		"collected": false,
	}

static func get_magnet_radius(run_upgrades: Dictionary) -> float:
	return BASE_MAGNET_RADIUS + float(run_upgrades.get("magnet_range_bonus", 0.0))

static func get_type_definition(pickup_type: String) -> Dictionary:
	return TYPES.get(pickup_type, TYPES.xp)
