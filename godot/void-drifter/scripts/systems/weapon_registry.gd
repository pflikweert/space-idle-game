extends RefCounted

const PULSE_CANNON_ID := "pulse_cannon"
const RAILGUN_ID := "railgun"
const PROJECTILE_SPEED := 1600.0
const CYCLES := {
	"drone_railgun": {"magazine":1,"reload":16.0,"interval":0.0,"warmup":0.45,"damage":0.1,"pivot":Vector2(192,210),"barrel":3.0},
	"scout_railgun": {"magazine":1,"reload":20.0,"interval":0.0,"warmup":0.35,"damage":0.1,"pivot":Vector2(192,210),"barrel":4.5},
	"tank_railgun": {"magazine":2,"reload":14.0,"interval":1.0,"warmup":0.5,"damage":0.25,"pivot":Vector2(192,210),"barrel":5.0},
	"railgun": {"magazine": 6, "reload": 3.0, "interval": 0.5, "warmup": 0.0},
	"enemy_railgun": {"magazine": 3, "reload": 6.0, "interval": 0.5, "warmup": 0.3,"damage":0.25,"pivot":Vector2(192,206),"barrel":7.0},
	"boss_rocket": {"magazine": 1, "reload": 4.0, "interval": 0.0, "warmup": 0.6,"damage":6.0},
}

static func cycle(id: String) -> Dictionary:
	return CYCLES[canonical_id(id)]

static func ensure_cycle(state: Dictionary, id: String) -> void:
	if not state.has("ammo"): state.ammo = int(cycle(id).magazine)
	if not state.has("reload_timer"): state.reload_timer = 0.0

# Return time left after reloading, preserving fractional simulation steps.
static func tick_reload(state: Dictionary, id: String, delta: float) -> float:
	ensure_cycle(state, id)
	var delay := float(state.reload_timer)
	if delay <= 0.0: return delta
	state.reload_timer = maxf(0.0, delay - delta)
	if float(state.reload_timer) <= 0.000001:
		state.reload_timer = 0.0
		state.ammo = int(cycle(id).magazine)
	return maxf(0.0, delta - delay)

static func consume(state: Dictionary, id: String) -> void:
	state.ammo = maxi(0, int(state.ammo) - 1)
	if int(state.ammo) == 0: state.reload_timer = float(cycle(id).reload)

# Visual-only mount; future weapons can add presentation without changing player flight.
const VISUALS := {"railgun": {"texture": "res://assets/player_ship/gunship/railgun.png", "pivot": Vector2(192, 256), "muzzle": Vector2(192, 94), "recoil": 2.0, "flash": "cyan", "impact": "rail_impact", "aimed": true}}

static func visual(id: String) -> Dictionary:
	return VISUALS.get(canonical_id(id), VISUALS[RAILGUN_ID])

static func canonical_id(id: String) -> String:
	return RAILGUN_ID if id == PULSE_CANNON_ID else id

# Earliest intersection parameter, including a shot that starts inside the circle.
static func hit_fraction(start: Vector2, end: Vector2, center: Vector2, radius: float) -> float:
	var offset := start - center
	if offset.length_squared() <= radius * radius: return 0.0
	var segment := end - start
	var a := segment.length_squared()
	if a < 0.000001: return INF
	var b := 2.0 * offset.dot(segment)
	var c := offset.length_squared() - radius * radius
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0: return INF
	var t := (-b - sqrt(discriminant)) / (2.0 * a)
	return t if t >= 0.0 and t <= 1.0 else INF

static func build_projectile(id: int, position: Vector2, direction: Vector2, damage: float, critical := false, travel_distance := 120.0) -> Dictionary:
	return {
		"id": id, "position": position, "previous_position": position, "radius": 3.2,
		"velocity": direction.normalized() * PROJECTILE_SPEED,
		"damage": damage * (2.0 if critical else 1.0), "life": travel_distance / PROJECTILE_SPEED,
		"remaining_distance": travel_distance,
		"weapon_id": RAILGUN_ID, "critical": critical,
	}
