extends RefCounted
const Anchors = preload("res://scripts/systems/gunship_anchors.gd")
const Weapons = preload("res://scripts/systems/weapon_registry.gd")
var textures := {}
var bank := 0.0
var damage_state := 0
var pulse_cooldown := 0.0
var hit_pending := false
var shield_flash := 0.0
var hull_flash := 0.0
var break_flash := 0.0
var hit_angle := 0.0
var heavy_hit := false
var pending_hull := false
var pending_shield := false
var pending_break := false
var time := 0.0
var shield_visibility := 0.0

func load_art(game) -> void:
	for state in ["intact", "damaged", "critical", "railgun"]:
		textures[state] = game._load_png_texture("res://assets/player_ship/gunship/%s.png" % state)
	for state in ["shield_idle", "shield_break"]:
		textures[state] = game._load_png_texture("res://assets/vfx/shield/%s.png" % state.replace("shield_", "shield-"))

func reset(hp_fraction := 1.0) -> void:
	bank = 0.0
	shield_visibility = 0.0
	damage_state = 2 if hp_fraction < 0.3 else (1 if hp_fraction < 0.6 else 0)
	pulse_cooldown = 0.0
	hit_pending = false
	pending_hull = false
	pending_shield = false
	pending_break = false
	shield_flash = 0.0
	hull_flash = 0.0
	break_flash = 0.0

func allow_weapon_pulse() -> bool:
	if pulse_cooldown > 0.0 or hit_pending: return false
	pulse_cooldown = 1.0 / 12.0
	return true

func hit(loss: Dictionary, position: Vector2, impact: Vector2, incoming: Vector2, source: String) -> void:
	var outward := impact - position if impact.is_finite() else -incoming
	if outward.length_squared() < 0.01: outward = -incoming
	if outward.length_squared() < 0.01: outward = Vector2.UP
	hit_angle = outward.angle()
	heavy_hit = source == "IMPACT"
	pending_hull = pending_hull or float(loss.hull) > 0.0
	pending_shield = pending_shield or float(loss.shield) > 0.0
	pending_break = pending_break or bool(loss.broken)
	hit_pending = true

func update(game, delta: float) -> void:
	time += delta
	var nearby := false
	for enemy in game.enemies:
		if float(enemy.hp) > 0.0 and game.player.position.distance_squared_to(enemy.position) <= pow(game._stat("range"), 2):
			nearby = true
			break
	shield_visibility = move_toward(shield_visibility, 1.0 if nearby else 0.0, delta / 0.2)
	pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	shield_flash = maxf(0.0, shield_flash - delta)
	hull_flash = maxf(0.0, hull_flash - delta)
	break_flash = maxf(0.0, break_flash - delta)
	var desired := clampf(game.player_velocity_x / game.PLAYER_MOVE_SPEED, -1.0, 1.0) * deg_to_rad(6.0) if game.pointer_down else 0.0
	bank = lerpf(bank, desired, 1.0 - exp(-delta * 12.0))
	var hp := float(game.player.hp) / maxf(1.0, float(game.player.max_hp))
	if hp < 0.3: damage_state = 2
	elif damage_state == 2 and hp > 0.35: damage_state = 1
	if damage_state == 1 and hp > 0.65: damage_state = 0
	elif damage_state == 0 and hp < 0.6: damage_state = 1
	if hit_pending and pulse_cooldown == 0.0:
		shield_flash = 0.24 if pending_shield else shield_flash
		hull_flash = 0.24 if pending_hull else hull_flash
		break_flash = 0.4 if pending_break else break_flash
		pending_hull = false
		pending_shield = false
		pending_break = false
		hit_pending = false
		pulse_cooldown = 1.0 / 12.0

func draw(game) -> void:
	if textures.is_empty() or game.player.is_empty(): return
	if game.status == "dead" and float(game.player.hp) <= 0.0: return
	var center: Vector2 = game.player.position
	var scale := Anchors.HEIGHT / 512.0
	var forward := Vector2.UP.rotated(bank)
	var moving: bool = game.pointer_down and (absf(game.player_velocity_x) > 1.0 or game.player_target.distance_to(center) > 1.0)
	for index in range(2):
		var nozzle: Vector2 = center + ((Anchors.ENGINES[index] - Vector2(192,256)) * scale).rotated(bank)
		var flutter := 0.8 + 0.2 * sin(time * 23.0 + index * 1.7)
		if damage_state == 2: flutter *= 0.45 + 0.55 * absf(sin(time * 17.0 + index))
		var length := (9.0 if moving else 5.0) * flutter
		game.draw_line(nozzle, nozzle - forward * length, Color(0.1,0.7,1,0.65), 1.8, true)
		game.draw_line(nozzle, nozzle - forward * length * 0.65, Color(0.65,1,1,0.95), 0.7, true)
	var state: String = ["intact", "damaged", "critical"][damage_state]
	game._draw_centered_texture(textures[state], center, Anchors.HEIGHT, bank, Color.WHITE)
	if moving:
		var side := -signf(game.player_velocity_x)
		var point := center + Vector2(side * 24.0, 7.0).rotated(bank)
		game.draw_line(point, point + Vector2(side * (2.0 + 3.0 * absf(sin(time * 22))), 0).rotated(bank), Color(0.35,0.9,1,0.7), 1.1, true)
	var spec: Dictionary = Weapons.visual("railgun")
	var turret_scale := float(game.player.radius) / (Vector2(spec.pivot) - Vector2(spec.muzzle)).length()
	var aim: Vector2 = game.rail_direction
	game._draw_centered_texture(textures.railgun, center - aim * game.rail_recoil * float(spec.recoil), 512.0 * turret_scale, aim.angle() + PI / 2.0, Color.WHITE)
	if game.rail_recoil > 0.0:
		game.draw_line(center, center + aim * game.player.radius, Color(0.5,0.95,1,game.rail_recoil * 0.65), 0.8, true)
	var charged := float(game.player.shield) / maxf(1.0, float(game.player.max_shield))
	if charged > 0.0 and shield_visibility > 0.0:
		var idle_alpha := (0.025 + charged * 0.085) * shield_visibility
		game._draw_centered_texture(textures.shield_idle, center, 118.0, 0.0, Color(0.72,0.96,1.0,idle_alpha))
	if shield_flash > 0.0:
		var impact_progress := 1.0 - shield_flash / 0.24
		var impact_alpha := sin(impact_progress * PI)
		var impact_center := center + Vector2.from_angle(hit_angle) * 45.0
		var blast_radius := lerpf(2.0, 8.0, impact_progress)
		# Keep shield contact feedback distinct from the continuous shield contour: this is
		# a compact, blue energy burst rather than the old half-shield wave asset.
		game.draw_circle(impact_center, blast_radius, Color(0.12,0.72,1.0,impact_alpha * 0.08))
		game.draw_arc(impact_center, blast_radius, 0.0, TAU, 16, Color(0.38,0.9,1.0,impact_alpha * 0.36), 0.6, true)
		game.draw_circle(impact_center, lerpf(1.5, 0.5, impact_progress), Color(0.82,1.0,1.0,impact_alpha * 0.47))
		for index in range(3):
			var angle := hit_angle + index * TAU / 3.0
			var ray_start := impact_center + Vector2.from_angle(angle) * blast_radius * 0.45
			var ray_end := impact_center + Vector2.from_angle(angle) * (blast_radius + 2.5)
			game.draw_line(ray_start, ray_end, Color(0.22,0.78,1.0,impact_alpha * 0.31), 0.5, true)
	if break_flash > 0.0:
		var break_progress := 1.0 - break_flash / 0.4
		var break_alpha := (1.0 - break_progress) * 0.86
		game._draw_centered_texture(textures.shield_break, center, lerpf(126.0, 178.0, break_progress), 0.0, Color(0.72,0.96,1.0,break_alpha))
	if hull_flash > 0.0:
		var point := center + Vector2.from_angle(hit_angle) * 19.0
		var alpha := hull_flash / 0.24
		game.draw_circle(point, (4.0 if heavy_hit else 2.5) * alpha, Color(1,0.8,0.55,alpha))
		for index in range(5):
			var direction := Vector2.from_angle(hit_angle - 0.8 + index * 0.4)
			game.draw_line(point + direction * (1.0-alpha)*8, point + direction * ((1.0-alpha)*8+4), Color(1,0.4,0.1,alpha), 0.8, true)
	if damage_state == 2:
		var strength := maxf(0.0, sin(time * 19.0))
		var point := center + Vector2(10,-6).rotated(bank)
		game.draw_line(point, point + Vector2(3,-4) * strength, Color(1,0.5,0.12,strength * 0.8), 0.8, true)
