extends RefCounted
var textures := {}
var presentation: Dictionary = {}
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
var throttle := 0.0

func load_art(game, ship: Dictionary) -> void:
	presentation = ship.get("presentation",{}).duplicate(true)
	var art: Dictionary = ship.get("art",{})
	var combat_states: Dictionary = art.get("combat_states",{})
	for state in ["intact", "damaged", "critical"]:
		textures[state] = game._load_png_texture(str(combat_states.get(state,"")))
	textures.shield_idle = game._load_png_texture(str(art.get("shield_idle","")))
	textures.shield_break = game._load_png_texture(str(art.get("shield_break","")))

func combat_height() -> float:
	return float(presentation.get("combat_height",120.0))

func mount_height(kind: String) -> float:
	return float(presentation.get("weapon_mount_height",34.0)) if kind == "weapon" else float(presentation.get("system_mount_height",30.0))

func mount_height_for(hardpoint: Dictionary, scale := 1.0) -> float:
	var mount_size: Vector2 = hardpoint.get("mount_size",Vector2(0.18,0.18))
	return combat_height() * mount_size.y * scale

func local_anchor_offset(anchor: Vector2) -> Vector2:
	var canvas: Vector2 = presentation.get("source_canvas",Vector2(384,512))
	return (anchor - Vector2(0.5,0.5)) * canvas * (combat_height() / maxf(1.0,canvas.y))

func weapon_muzzle_offset() -> float:
	return float(presentation.get("weapon_muzzle_offset",12.0))

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
	throttle = 0.0

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
	throttle = move_toward(throttle,clampf(float(game.player_motion_speed) / maxf(1.0,game._player_move_speed()),0.0,1.0),delta * 7.0)
	var desired := clampf(game.player_velocity_x / game._player_move_speed(),-1.0,1.0) * deg_to_rad(6.0) if game.pointer_down else 0.0
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
	var forward := Vector2.UP.rotated(bank)
	var moving: bool = throttle > 0.05
	var state: String = ["intact", "damaged", "critical"][damage_state]
	game._draw_centered_texture(textures[state], center, combat_height(), bank, Color.WHITE)
	var engines: Array = presentation.get("engine_anchors",[])
	for index in range(engines.size()):
		var nozzle: Vector2 = center + local_anchor_offset(Vector2(engines[index])).rotated(bank)
		var flutter := 0.8 + 0.2 * sin(time * 23.0 + index * 1.7)
		if damage_state == 2: flutter *= 0.45 + 0.55 * absf(sin(time * 17.0 + index))
		var length := lerpf(7.0,22.0,throttle) * flutter
		var flame_end := nozzle - forward * length
		var side := forward.orthogonal() * (1.8 + throttle * 2.2)
		game.draw_colored_polygon(PackedVector2Array([nozzle + side,nozzle - side,flame_end]),Color(0.05,0.55,1.0,0.18 + throttle * 0.20))
		game.draw_line(nozzle, flame_end, Color(0.08,0.66,1.0,0.64 + throttle * 0.24), 2.5 + throttle * 1.4, true)
		game.draw_line(nozzle, nozzle - forward * length * 0.72, Color(0.72,1.0,1.0,0.92), 0.9 + throttle * 0.4, true)
		game.draw_circle(nozzle,1.5 + throttle * 1.0,Color(0.36,0.92,1.0,0.55 + throttle * 0.25))
	if moving:
		var side := -signf(game.player_velocity_x)
		var point := center + Vector2(side * 24.0, 7.0).rotated(bank)
		game.draw_line(point, point + Vector2(side * (2.0 + 3.0 * absf(sin(time * 22))), 0).rotated(bank), Color(0.35,0.9,1,0.7), 1.1, true)
	var charged := float(game.player.shield) / maxf(1.0, float(game.player.max_shield))
	var shield_height := combat_height() * float(presentation.get("shield_height_multiplier",1.4))
	if charged > 0.0 and shield_visibility > 0.0:
		var idle_alpha := (0.025 + charged * 0.085) * shield_visibility
		game._draw_centered_texture(textures.shield_idle, center, shield_height, 0.0, Color(0.72,0.96,1.0,idle_alpha))
	if shield_flash > 0.0:
		var impact_progress := 1.0 - shield_flash / 0.24
		var impact_alpha := sin(impact_progress * PI)
		var impact_center := center + Vector2.from_angle(hit_angle) * shield_height * 0.32
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
		game._draw_centered_texture(textures.shield_break, center, lerpf(shield_height * 1.05,shield_height * 1.45,break_progress), 0.0, Color(0.72,0.96,1.0,break_alpha))
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
