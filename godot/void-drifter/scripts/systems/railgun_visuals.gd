extends RefCounted

# Presentation-only: collision continues to use the full swept movement segment.
const PULSE_LENGTH := 20.0
const FRAGMENT_LENGTH := 8.0
const FRAME_COUNT := 4
var textures: Dictionary = {}

static func is_fragment(projectile: Dictionary) -> bool:
	return bool(projectile.get("is_fragment",float(projectile.get("radius",3.2)) < 2.0))

static func trace_start(start: Vector2, end: Vector2, fragment: bool) -> Vector2:
	return end.move_toward(start,minf(start.distance_to(end),FRAGMENT_LENGTH if fragment else PULSE_LENGTH))

func texture(kind: String, progress: float) -> Texture2D:
	var frame := clampi(int(progress*FRAME_COUNT),0,FRAME_COUNT-1)
	var key := "%s-%d" % [kind,frame]
	if not textures.has(key): textures[key] = load("res://assets/vfx/railgun_pulses/%s.svg" % key)
	return textures[key]
