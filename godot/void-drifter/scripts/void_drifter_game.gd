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
const UI_CYAN := Color("#00E5FF")
const UI_PLAYER_BLUE := Color("#1565C0")
const UI_MAGENTA := Color("#FF00FF")
const UI_PURPLE := Color("#6A1B9A")
const UI_ORANGE := Color("#FF6D00")
const UI_TEAL := Color("#00E676")
const UI_BG := Color("#0A0A14")
const UI_PANEL := Color("#121228")
const UI_PANEL_MID := Color("#1A1A3E")
const UI_TEXT := Color("#E0E0FF")
const UI_TEXT_DIM := Color("#6070A0")

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
	_style_buttons()
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

	var direction: Vector2 = (nearest.position - player_position).normalized()
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
		var direction: Vector2 = (player_position - enemy.position).normalized()
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
	_draw_scanlines(size)
	draw_rect(Rect2(0.0, size.y * 0.68, size.x, 1.0), _with_alpha(UI_CYAN, 0.18))

func _draw_hud(size: Vector2) -> void:
	var top_rect := Rect2(14, 14, size.x - 28, 58)
	_draw_lcars_panel(top_rect, UI_CYAN, "VOID DRIFTER")
	draw_string(get_theme_default_font(), top_rect.position + Vector2(24, 24), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UI_CYAN)
	draw_string(get_theme_default_font(), top_rect.position + Vector2(24, 48), "%06d" % _get_score(), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, UI_CYAN)
	_draw_hud_chip(Vector2(size.x - 176, top_rect.position.y + 12), "TIME", _format_time(elapsed), UI_TEAL)
	_draw_hud_chip(Vector2(size.x - 92, top_rect.position.y + 12), "EN", str(enemies.size()), UI_MAGENTA)

	var bottom_width := minf(336.0, maxf(220.0, size.x - 154.0))
	var bottom_rect := Rect2(14, size.y - 92, bottom_width, 76)
	_draw_lcars_panel(bottom_rect, UI_CYAN, "HULL")
	var hp_percent := clampf(float(player.hp) / float(PLAYER_HP), 0.0, 1.0)
	_draw_lcars_meter(Rect2(bottom_rect.position.x + 24, bottom_rect.position.y + 27, bottom_rect.size.x - 48, 15), hp_percent, UI_CYAN, "HULL", str(player.hp))
	_draw_lcars_meter(Rect2(bottom_rect.position.x + 24, bottom_rect.position.y + 52, bottom_rect.size.x - 48, 11), 0.72, UI_TEAL, "SHLD", "72%")

	var status_rect := Rect2(size.x - 120, size.y - 92, 106, 76)
	_draw_lcars_panel(status_rect, UI_MAGENTA, "CORE")
	draw_arc(status_rect.position + Vector2(53, 42), 22.0, -PI * 0.45, PI * 1.28, 28, _with_alpha(UI_MAGENTA, 0.82), 5.0)
	draw_circle(status_rect.position + Vector2(53, 42), 14.0, _with_alpha(UI_MAGENTA, 0.16))
	draw_string(get_theme_default_font(), status_rect.position + Vector2(33, 67), "AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI_MAGENTA)

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
	var rect := Rect2(22, size.y * 0.24, size.x - 44, 224)
	_draw_lcars_panel(rect, UI_CYAN, "SYSTEM READY")
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 62), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 34, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 101), "Survive the sector. Your ship fires automatically.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 15, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 131), "Click or drag to steer. Weapons auto-target the nearest enemy.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 13, UI_CYAN)
	_draw_lcars_meter(Rect2(rect.position.x + 30, rect.position.y + 158, rect.size.x - 60, 9), 0.82, UI_TEAL, "SIGNAL", "82%")

func _draw_death_overlay(size: Vector2) -> void:
	var rect := Rect2(22, size.y * 0.26, size.x - 44, 236)
	_draw_lcars_panel(rect, UI_ORANGE, "RUN ENDED")
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 62), "Signal Lost", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, UI_TEXT)
	_draw_stat_block(Rect2(rect.position.x + 30, rect.position.y + 92, 88, 52), "KILLS", str(kills), UI_MAGENTA)
	_draw_stat_block(Rect2(rect.position.x + 124, rect.position.y + 92, 94, 52), "TIME", _format_time(elapsed), UI_CYAN)
	_draw_stat_block(Rect2(rect.position.x + 224, rect.position.y + 92, rect.size.x - 254, 52), "SCORE", str(_get_score()), UI_TEAL)
	_draw_lcars_meter(Rect2(rect.position.x + 30, rect.position.y + 158, rect.size.x - 60, 10), 0.18, UI_ORANGE, "SIGNAL", "LOST")

func _draw_panel(rect: Rect2, fill: Color, stroke: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, stroke, false, 1.0)

func _draw_lcars_panel(rect: Rect2, accent: Color, label := "") -> void:
	draw_rect(rect.grow(5.0), _with_alpha(accent, 0.07))
	draw_rect(rect, _with_alpha(UI_PANEL, 0.78))
	draw_rect(rect, _with_alpha(accent, 0.36), false, 1.4)
	draw_rect(rect.grow(-3.0), _with_alpha(accent, 0.20), false, 1.0)
	var header_width := minf(rect.size.x * 0.44, 152.0)
	_draw_lcars_block(Rect2(rect.position.x, rect.position.y, header_width, 10), accent, 0.62)
	_draw_lcars_block(Rect2(rect.position.x + header_width + 6, rect.position.y, 8, 10), accent, 0.36)
	draw_arc(rect.position + Vector2(18, 18), 17.0, PI, PI * 1.5, 10, _with_alpha(accent, 0.72), 1.5)
	draw_arc(rect.position + Vector2(rect.size.x - 18, 18), 17.0, PI * 1.5, TAU, 10, _with_alpha(accent, 0.72), 1.5)
	if label != "":
		draw_string(get_theme_default_font(), rect.position + Vector2(18, 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent)

func _draw_lcars_block(rect: Rect2, color: Color, alpha := 1.0) -> void:
	draw_rect(rect, _with_alpha(color, alpha))

func _draw_lcars_meter(rect: Rect2, percent: float, fill_color: Color, label: String, value: String) -> void:
	var clamped := clampf(percent, 0.0, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, fill_color)
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 42, -5), value, HORIZONTAL_ALIGNMENT_RIGHT, 42, 9, UI_TEXT)
	_draw_capsule(rect.grow(1.0), _with_alpha(fill_color, 0.24))
	var fill_width := maxf(rect.size.y, rect.size.x * clamped)
	_draw_capsule(Rect2(rect.position, Vector2(fill_width, rect.size.y)), _with_alpha(fill_color, 0.88))
	draw_rect(rect, _with_alpha(fill_color, 0.70), false, 1.0)

func _draw_hud_chip(position: Vector2, label: String, value: String, accent: Color) -> void:
	var rect := Rect2(position, Vector2(72, 36))
	_draw_capsule(rect, _with_alpha(UI_PANEL_MID, 0.72))
	draw_rect(rect, _with_alpha(accent, 0.42), false, 1.0)
	draw_string(get_theme_default_font(), position + Vector2(11, 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UI_TEXT_DIM)
	draw_string(get_theme_default_font(), position + Vector2(11, 30), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, accent)

func _draw_stat_block(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_panel(rect, _with_alpha(UI_PANEL_MID, 0.72), _with_alpha(accent, 0.34))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UI_TEXT_DIM)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 43), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 18, accent)

func _draw_capsule(rect: Rect2, color: Color) -> void:
	var radius := rect.size.y / 2.0
	draw_rect(Rect2(rect.position + Vector2(radius, 0), Vector2(maxf(0.0, rect.size.x - radius * 2.0), rect.size.y)), color)
	draw_circle(rect.position + Vector2(radius, radius), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x - radius, radius), radius, color)

func _draw_scanlines(size: Vector2) -> void:
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018), 1.0)

func _with_alpha(color: Color, alpha: float) -> Color:
	var next := color
	next.a = alpha
	return next

func _layout_buttons() -> void:
	var size := get_viewport_rect().size
	action_button.size = Vector2(170, 50)
	if status == "dead":
		action_button.position = Vector2((size.x - action_button.size.x) / 2.0, size.y * 0.26 + 180)
	else:
		action_button.position = Vector2((size.x - action_button.size.x) / 2.0, size.y * 0.24 + 176)
	header_restart_button.size = Vector2(82, 36)
	header_restart_button.position = Vector2(size.x - 100, 18)

func _update_buttons() -> void:
	_layout_buttons()
	header_restart_button.visible = status != "ready"
	action_button.visible = status == "ready" or status == "dead"
	action_button.text = "Start Run" if status == "ready" else "Restart Run"

func _on_action_button_pressed() -> void:
	start_run()

func _style_buttons() -> void:
	_apply_button_style(action_button, UI_CYAN)
	_apply_button_style(header_restart_button, UI_MAGENTA)

func _apply_button_style(button: Button, accent: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(_with_alpha(UI_PANEL_MID, 0.86), accent, 0.78))
	button.add_theme_stylebox_override("hover", _make_button_style(_with_alpha(accent, 0.20), accent, 1.0))
	button.add_theme_stylebox_override("pressed", _make_button_style(_with_alpha(accent, 0.34), accent, 1.0))
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)

func _make_button_style(fill: Color, border: Color, border_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = _with_alpha(border, border_alpha)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 8
	style.shadow_color = _with_alpha(border, 0.20)
	style.shadow_size = 8
	return style

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
