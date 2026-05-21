extends Control

const PLAYER_HP := 140
const ENEMY_SPAWN_INTERVAL := 1500.0
const MIN_ENEMY_SPAWN_INTERVAL := 620.0
const FIRST_ENEMY_SPAWN_DELAY := 1350.0
const PLAYER_FIRE_INTERVAL := 260.0
const BULLET_SPEED := 540.0
const ENEMY_SPEED := 42.0
const ENEMY_HP := 2
const PLAYER_MOVE_SPEED := 470.0
const PLAYER_BOUNDS_PADDING := 10.0
const PLAYER_RADIUS := 18.0
const PLAYER_SPRITE_SIZE := 76.0
const PLAYER_DAMAGED_HP_THRESHOLD := 0.3
const PLAYER_BANKING_THRESHOLD := 1.2
const PARTICLE_LIFETIME := 0.42
const DAMAGE_BULLET := 1
const DAMAGE_ENEMY_CONTACT := 12
const MAX_DELTA_SECONDS := 0.033

const DIFFICULTY_SCALING := {
	"max_enemies_start": 3,
	"max_enemies_cap": 13,
	"max_enemies_ramp_seconds": 11.0,
	"spawn_ramp_ms_per_second": 24.0,
	"enemy_speed_ramp_per_second": 0.012,
	"enemy_speed_cap_multiplier": 1.48,
}

const ENEMY_VARIANTS := [
	{ "radius": 12.0, "color": Color("#fb7185"), "speed_multiplier": 1.08, "hp": ENEMY_HP },
	{ "radius": 16.0, "color": Color("#a78bfa"), "speed_multiplier": 0.92, "hp": ENEMY_HP + 1 },
	{ "radius": 10.0, "color": Color("#facc15"), "speed_multiplier": 1.24, "hp": ENEMY_HP },
]

const PARALLAX_LAYERS := [
	{ "id": "far", "path": "res://assets/backgrounds/bg_far_stars.png", "speed": 12.0, "opacity": 0.72 },
	{ "id": "mid", "path": "res://assets/backgrounds/bg_mid_nebula.png", "speed": 24.0, "opacity": 0.34 },
	{ "id": "near", "path": "res://assets/backgrounds/bg_near_asteroids.png", "speed": 48.0, "opacity": 0.20 },
]

@onready var action_button: Button = $ActionButton
@onready var header_restart_button: Button = $HeaderRestartButton

var ship_textures := {}
var background_textures: Array[Texture2D] = []
var status := "ready"
var player := {}
var player_target := Vector2.ZERO
var player_velocity_x := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var kills := 0
var elapsed := 0.0
var background_time := 0.0
var spawn_timer := FIRST_ENEMY_SPAWN_DELAY
var fire_timer := PLAYER_FIRE_INTERVAL * 0.6
var next_id := 1
var pointer_down := false

func _ready() -> void:
	set_process(true)
	action_button.pressed.connect(_on_action_button_pressed)
	header_restart_button.pressed.connect(start_run)
	ship_textures = {
		"idle": load("res://assets/player_ship/player_ship_idle.png"),
		"bank_left": load("res://assets/player_ship/player_ship_bank_left.png"),
		"bank_right": load("res://assets/player_ship/player_ship_bank_right.png"),
		"damaged": load("res://assets/player_ship/player_ship_damaged.png"),
	}
	for layer in PARALLAX_LAYERS:
		background_textures.append(load(layer.path))
	reset_world("ready")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_clamp_player_to_viewport()
		_layout_buttons()
		queue_redraw()

func _process(delta: float) -> void:
	var step := minf(delta, MAX_DELTA_SECONDS)
	background_time += step
	if status == "running":
		_update_world(step)
	_update_buttons()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if status != "running":
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		if event.pressed:
			player_target = _clamp_point_to_playfield(event.position)
	elif event is InputEventMouseMotion and pointer_down:
		player_target = _clamp_point_to_playfield(event.position)
	elif event is InputEventScreenTouch:
		pointer_down = event.pressed
		if event.pressed:
			player_target = _clamp_point_to_playfield(event.position)
	elif event is InputEventScreenDrag:
		player_target = _clamp_point_to_playfield(event.position)

func reset_world(next_status: String) -> void:
	var size := get_viewport_rect().size
	var start := Vector2(size.x / 2.0, size.y * 0.68)
	status = next_status
	player = {
		"position": start,
		"radius": PLAYER_RADIUS,
		"hp": PLAYER_HP,
	}
	player_target = start
	player_velocity_x = 0.0
	enemies = []
	bullets = []
	particles = []
	kills = 0
	elapsed = 0.0
	background_time = 0.0
	spawn_timer = FIRST_ENEMY_SPAWN_DELAY
	fire_timer = PLAYER_FIRE_INTERVAL * 0.6
	next_id = 1
	pointer_down = false
	_update_buttons()
	queue_redraw()

func start_run() -> void:
	reset_world("running")

func _update_world(delta: float) -> void:
	var delta_ms := delta * 1000.0
	elapsed += delta
	_update_player(delta)
	_update_enemy_spawning(delta_ms)
	_update_weapons(delta_ms)
	_update_enemy_movement(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_resolve_collisions()

func _update_player(delta: float) -> void:
	player_target = _clamp_point_to_playfield(player_target)
	var position: Vector2 = player.position
	var offset := player_target - position
	var distance := offset.length()
	if distance < 1.0:
		player.position = player_target
		player_velocity_x = 0.0
		return

	var step := minf(distance, PLAYER_MOVE_SPEED * delta)
	var movement := offset / distance * step
	player.position = position + movement
	player_velocity_x = movement.x

func _update_enemy_spawning(delta_ms: float) -> void:
	spawn_timer -= delta_ms
	if spawn_timer <= 0.0 and enemies.size() < _get_max_enemies(elapsed):
		_spawn_enemy()
		spawn_timer = _get_spawn_interval(elapsed)

func _spawn_enemy() -> void:
	var size := get_viewport_rect().size
	var variant = ENEMY_VARIANTS[next_id % ENEMY_VARIANTS.size()]
	var edge := next_id % 4
	var inset: float = variant.radius + 8.0
	var drift := float((next_id * 71) % 100) / 100.0
	var position := Vector2(size.x * drift, size.y * drift)

	if edge == 0:
		position.y = -inset
	elif edge == 1:
		position.x = size.x + inset
	elif edge == 2:
		position.y = size.y + inset
	else:
		position.x = -inset

	enemies.append({
		"id": next_id,
		"position": position,
		"radius": variant.radius,
		"hp": variant.hp,
		"speed": ENEMY_SPEED * variant.speed_multiplier * _get_enemy_speed_multiplier(elapsed),
		"color": variant.color,
	})
	next_id += 1

func _update_weapons(delta_ms: float) -> void:
	fire_timer -= delta_ms
	if fire_timer <= 0.0:
		_fire_at_nearest_enemy()
		fire_timer = PLAYER_FIRE_INTERVAL

func _fire_at_nearest_enemy() -> void:
	if enemies.is_empty():
		return

	var player_position: Vector2 = player.position
	var nearest := enemies[0]
	var nearest_distance := player_position.distance_squared_to(nearest.position)
	for enemy in enemies.slice(1):
		var enemy_distance := player_position.distance_squared_to(enemy.position)
		if enemy_distance < nearest_distance:
			nearest = enemy
			nearest_distance = enemy_distance

	var direction := (nearest.position - player_position).normalized()
	bullets.append({
		"id": next_id,
		"position": Vector2(player_position.x, player_position.y - player.radius),
		"radius": 4.0,
		"velocity": direction * BULLET_SPEED,
		"life": 1.65,
	})
	next_id += 1

func _update_enemy_movement(delta: float) -> void:
	var player_position: Vector2 = player.position
	for enemy in enemies:
		var direction := (player_position - enemy.position).normalized()
		enemy.position += direction * enemy.speed * delta

func _update_projectiles(delta: float) -> void:
	for bullet in bullets:
		bullet.position += bullet.velocity * delta
		bullet.life -= delta

func _update_effects(delta: float) -> void:
	for particle in particles:
		particle.position += particle.velocity * delta
		particle.life -= delta
	particles = particles.filter(func(particle): return particle.life > 0.0)

func _resolve_collisions() -> void:
	var removed_bullet_ids := {}
	var removed_enemy_ids := {}

	for bullet in bullets:
		for enemy in enemies:
			if removed_enemy_ids.has(enemy.id) or removed_bullet_ids.has(bullet.id):
				continue

			if _circles_overlap(bullet.position, bullet.radius, enemy.position, enemy.radius):
				enemy.hp -= DAMAGE_BULLET
				removed_bullet_ids[bullet.id] = true
				if enemy.hp <= 0:
					removed_enemy_ids[enemy.id] = true
					kills += 1
					_add_explosion(enemy.position, enemy.color)

	for enemy in enemies:
		if removed_enemy_ids.has(enemy.id):
			continue

		if _circles_overlap(player.position, player.radius, enemy.position, enemy.radius):
			player.hp = maxi(0, player.hp - DAMAGE_ENEMY_CONTACT)
			removed_enemy_ids[enemy.id] = true
			_add_explosion(enemy.position, Color("#67e8f9"))

	enemies = enemies.filter(func(enemy): return not removed_enemy_ids.has(enemy.id))
	_remove_expired_projectiles(removed_bullet_ids)

	if player.hp <= 0:
		status = "dead"
		bullets = []
		enemies = []

func _remove_expired_projectiles(removed_bullet_ids: Dictionary) -> void:
	var size := get_viewport_rect().size
	bullets = bullets.filter(func(bullet):
		var position: Vector2 = bullet.position
		var in_bounds := position.x > -24.0 and position.x < size.x + 24.0 and position.y > -24.0 and position.y < size.y + 24.0
		return not removed_bullet_ids.has(bullet.id) and bullet.life > 0.0 and in_bounds
	)

func _add_explosion(origin: Vector2, color: Color) -> void:
	for index in range(6):
		var angle := TAU * float(index) / 6.0 + float(next_id) * 0.17
		var speed := 52.0 + float(index) * 11.0
		particles.append({
			"id": next_id,
			"position": origin,
			"radius": 2.0 + float(index % 2),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": PARTICLE_LIFETIME,
			"color": color,
		})
		next_id += 1

func _draw() -> void:
	var size := get_viewport_rect().size
	_draw_background(size)
	_draw_hud(size)
	_draw_particles()
	_draw_bullets()
	_draw_enemies()
	_draw_player()
	if status == "ready":
		_draw_ready_overlay(size)
	elif status == "dead":
		_draw_death_overlay(size)

func _draw_background(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#030712"))
	for index in range(PARALLAX_LAYERS.size()):
		var texture := background_textures[index]
		var layer = PARALLAX_LAYERS[index]
		var tile_height := maxf(float(texture.get_height()), size.y)
		var offset := fmod(background_time * layer.speed, tile_height)
		var color := Color(1, 1, 1, layer.opacity)
		for tile_index in [-1, 0]:
			var rect := Rect2(0.0, offset + float(tile_index) * tile_height, size.x, tile_height)
			draw_texture_rect(texture, rect, false, color)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.024, 0.09, 0.38))
	draw_rect(Rect2(0.0, size.y * 0.68, size.x, 1.0), Color(0.13, 0.83, 0.93, 0.18))

func _draw_hud(size: Vector2) -> void:
	var top := 18.0
	draw_string(get_theme_default_font(), Vector2(18, top + 10), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#22d3ee"))
	draw_string(get_theme_default_font(), Vector2(18, top + 34), "Core Fun Prototype", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f8fafc"))
	var hud_y := 74.0
	_draw_panel(Rect2(18, hud_y, size.x - 36, 54), Color(0.06, 0.09, 0.16, 0.82), Color(0.58, 0.64, 0.72, 0.22))
	var hp_percent := clampf(float(player.hp) / float(PLAYER_HP), 0.0, 1.0)
	draw_string(get_theme_default_font(), Vector2(34, hud_y + 22), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#94a3b8"))
	draw_rect(Rect2(34, hud_y + 30, 130, 7), Color(0.06, 0.09, 0.16, 0.94))
	draw_rect(Rect2(34, hud_y + 30, 130 * hp_percent, 7), Color("#22c55e"))
	draw_string(get_theme_default_font(), Vector2(180, hud_y + 35), str(player.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f8fafc"))
	draw_string(get_theme_default_font(), Vector2(230, hud_y + 22), "KILLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#94a3b8"))
	draw_string(get_theme_default_font(), Vector2(230, hud_y + 42), str(kills), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f8fafc"))
	draw_string(get_theme_default_font(), Vector2(298, hud_y + 22), "TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#94a3b8"))
	draw_string(get_theme_default_font(), Vector2(298, hud_y + 42), _format_time(elapsed), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f8fafc"))
	draw_string(get_theme_default_font(), Vector2(size.x - 88, hud_y + 22), "ENEMIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#94a3b8"))
	draw_string(get_theme_default_font(), Vector2(size.x - 88, hud_y + 42), str(enemies.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f8fafc"))

func _draw_particles() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a = clampf(particle.life / PARTICLE_LIFETIME, 0.0, 1.0)
		draw_circle(particle.position, particle.radius, color)

func _draw_bullets() -> void:
	for bullet in bullets:
		draw_circle(bullet.position, bullet.radius + 2.0, Color(0.4, 0.91, 0.98, 0.22))
		draw_circle(bullet.position, bullet.radius, Color("#67e8f9"))
		draw_arc(bullet.position, bullet.radius + 1.0, 0.0, TAU, 12, Color("#ecfeff"), 1.0)

func _draw_enemies() -> void:
	for enemy in enemies:
		var rect := Rect2(enemy.position - Vector2.ONE * enemy.radius, Vector2.ONE * enemy.radius * 2.0)
		draw_rect(rect, enemy.color)
		draw_rect(rect, Color(1, 1, 1, 0.35), false, 1.0)
		draw_circle(enemy.position, enemy.radius * 0.38, Color(0.06, 0.09, 0.16, 0.72))

func _draw_player() -> void:
	var texture: Texture2D = _get_player_ship_texture()
	draw_set_transform(player.position, PI, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2.ONE * -PLAYER_SPRITE_SIZE / 2.0, Vector2.ONE * PLAYER_SPRITE_SIZE), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ready_overlay(size: Vector2) -> void:
	var rect := Rect2(18, size.y * 0.26, size.x - 36, 190)
	_draw_panel(rect, Color(0.008, 0.024, 0.09, 0.90), Color(0.13, 0.83, 0.93, 0.42))
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 42, rect.position.y + 48), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#f8fafc"))
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 32, rect.position.y + 86), "Survive the sector. Your ship fires automatically.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 15, Color("#cbd5e1"))
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 32, rect.position.y + 116), "Click or drag to steer. Weapons auto-target the nearest enemy.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 13, Color("#67e8f9"))

func _draw_death_overlay(size: Vector2) -> void:
	var rect := Rect2(18, size.y * 0.28, size.x - 36, 210)
	_draw_panel(rect, Color(0.008, 0.024, 0.09, 0.92), Color(0.97, 0.44, 0.44, 0.42))
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 32, rect.position.y + 34), "RUN ENDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fca5a5"))
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 32, rect.position.y + 70), "Signal Lost", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#f8fafc"))
	var stats := "Kills %s     Survived %s     Score %s" % [kills, _format_time(elapsed), _get_score()]
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 32, rect.position.y + 112), stats, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 16, Color("#cbd5e1"))

func _draw_panel(rect: Rect2, fill: Color, stroke: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, stroke, false, 1.0)

func _layout_buttons() -> void:
	var size := get_viewport_rect().size
	action_button.size = Vector2(170, 50)
	action_button.position = Vector2((size.x - action_button.size.x) / 2.0, size.y * 0.26 + 132)
	header_restart_button.size = Vector2(82, 36)
	header_restart_button.position = Vector2(size.x - 100, 18)

func _update_buttons() -> void:
	_layout_buttons()
	header_restart_button.visible = status != "ready"
	action_button.visible = status == "ready" or status == "dead"
	action_button.text = "Start Run" if status == "ready" else "Restart Run"

func _on_action_button_pressed() -> void:
	start_run()

func _clamp_player_to_viewport() -> void:
	if player.is_empty():
		return
	player.position = _clamp_point_to_playfield(player.position)
	player_target = _clamp_point_to_playfield(player_target)

func _clamp_point_to_playfield(point: Vector2) -> Vector2:
	var size := get_viewport_rect().size
	var inset := PLAYER_RADIUS + PLAYER_BOUNDS_PADDING
	return Vector2(
		clampf(point.x, inset, maxf(inset, size.x - inset)),
		clampf(point.y, inset, maxf(inset, size.y - inset))
	)

func _circles_overlap(a_position: Vector2, a_radius: float, b_position: Vector2, b_radius: float) -> bool:
	var hit_distance := a_radius + b_radius
	return a_position.distance_squared_to(b_position) <= hit_distance * hit_distance

func _get_player_ship_texture() -> Texture2D:
	if float(player.hp) / float(PLAYER_HP) <= PLAYER_DAMAGED_HP_THRESHOLD:
		return ship_textures.damaged
	if player_velocity_x < -PLAYER_BANKING_THRESHOLD:
		return ship_textures.bank_left
	if player_velocity_x > PLAYER_BANKING_THRESHOLD:
		return ship_textures.bank_right
	return ship_textures.idle

func _get_spawn_interval(seconds: float) -> float:
	return maxf(
		MIN_ENEMY_SPAWN_INTERVAL,
		ENEMY_SPAWN_INTERVAL - seconds * DIFFICULTY_SCALING.spawn_ramp_ms_per_second
	)

func _get_enemy_speed_multiplier(seconds: float) -> float:
	return minf(
		DIFFICULTY_SCALING.enemy_speed_cap_multiplier,
		1.0 + seconds * DIFFICULTY_SCALING.enemy_speed_ramp_per_second
	)

func _get_max_enemies(seconds: float) -> int:
	return mini(
		DIFFICULTY_SCALING.max_enemies_cap,
		DIFFICULTY_SCALING.max_enemies_start + int(floor(seconds / DIFFICULTY_SCALING.max_enemies_ramp_seconds))
	)

func _format_time(seconds: float) -> String:
	var whole_seconds := int(floor(seconds))
	var minutes := int(floor(float(whole_seconds) / 60.0))
	var remaining_seconds := whole_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]

func _get_score() -> int:
	return kills * 100 + int(floor(elapsed)) * 5
