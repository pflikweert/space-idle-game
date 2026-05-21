extends Control

const PLAYER_HP := 140
const ENEMY_SPAWN_INTERVAL := 1500.0
const MIN_ENEMY_SPAWN_INTERVAL := 620.0
const FIRST_ENEMY_SPAWN_DELAY := 1350.0
const PLAYER_FIRE_INTERVAL := 260.0
const BULLET_SPEED := 540.0
const PLAYER_MOVE_SPEED := 470.0
const PLAYER_BOUNDS_PADDING := 10.0
const PLAYER_RADIUS := 18.0
const PLAYER_SPRITE_HEIGHT := 88.0
const PLAYER_DAMAGED_HP_THRESHOLD := 0.3
const PLAYER_BANKING_THRESHOLD := 1.2
const PARTICLE_LIFETIME := 0.42
const SPRITE_PARTICLE_LIFETIME := 0.34
const BULLET_SPRITE_HEIGHT := 34.0
const ENGINE_TRAIL_HEIGHT := 52.0
const EXPLOSION_SPRITE_HEIGHT := 74.0
const HIT_SPARK_SPRITE_HEIGHT := 30.0
const DAMAGE_BULLET := 1
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

const RED_SCOUT_DRONE_ID := "red_scout_drone"
const ENEMY_DEFINITIONS := {
	"red_scout_drone": {
		"id": "red_scout_drone",
		"name": "Red Scout Drone",
		"role": "Basic hostile drone",
		"description": "Fast red hostile scout drone that enters from screen edges and chases the player.",
		"base_stats": {
			"hp": 16,
			"speed": 52.0,
			"contact_damage": 10,
			"xp_reward": 4,
			"score_reward": 10,
			"radius": 18.0,
		},
		"scaling": {
			"hp_per_level": 3,
			"speed_per_level": 1.5,
			"damage_per_level": 1,
		},
		"spawn": {
			"weight": 100,
			"min_run_level": 1,
		},
		"abilities": ["chase_player", "contact_damage", "red_projectile_later"],
	},
}
const ENEMY_MOVEMENT_FRAMES_BY_EDGE := {
	"top": "move-down",
	"bottom": "move-up",
	"left": "move-right",
	"right": "move-left",
}

const PARALLAX_LAYERS := [
	{ "id": "far", "path": "res://assets/backgrounds/bg_far_stars.png", "speed": 12.0, "opacity": 0.72 },
	{ "id": "mid", "path": "res://assets/backgrounds/bg_mid_nebula.png", "speed": 24.0, "opacity": 0.34 },
	{ "id": "near", "path": "res://assets/backgrounds/bg_near_asteroids.png", "speed": 48.0, "opacity": 0.20 },
]

@onready var action_button: Button = $ActionButton
@onready var header_restart_button: Button = $HeaderRestartButton
@onready var enemies_button: Button = $EnemiesButton

var ship_textures := {}
var enemy_textures := {}
var vfx_textures := {}
var background_textures: Array[Texture2D] = []
var status := "ready"
var player := {}
var player_target := Vector2.ZERO
var player_velocity_x := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var kills := 0
var score := 0
var elapsed := 0.0
var background_time := 0.0
var spawn_timer := FIRST_ENEMY_SPAWN_DELAY
var fire_timer := PLAYER_FIRE_INTERVAL * 0.6
var next_id := 1
var pointer_down := false
var action_button_style_key := ""
var header_button_style_key := ""
var enemies_button_style_key := ""

func _ready() -> void:
	set_process(true)
	action_button.pressed.connect(_on_action_button_pressed)
	header_restart_button.pressed.connect(start_run)
	enemies_button.pressed.connect(_on_enemies_button_pressed)
	_style_buttons()
	ship_textures = {
		"idle": load("res://assets/player_ship/player_ship_idle.png"),
		"bank_left": load("res://assets/player_ship/player_ship_bank_left.png"),
		"bank_right": load("res://assets/player_ship/player_ship_bank_right.png"),
		"boost": load("res://assets/player_ship/player_ship_boost.png"),
		"damaged": load("res://assets/player_ship/player_ship_damaged.png"),
	}
	vfx_textures = {
		"player_plasma_bolt": load("res://assets/vfx/player_plasma_bolt.png"),
		"player_laser_beam": load("res://assets/vfx/player_laser_beam.png"),
		"enemy_red_bullet": load("res://assets/vfx/enemy_red_bullet.png"),
		"enemy_purple_shot": load("res://assets/vfx/enemy_purple_shot.png"),
		"engine_trail": load("res://assets/vfx/engine_trail.png"),
		"small_explosion": load("res://assets/vfx/small_explosion.png"),
		"enemy_death_explosion": load("res://assets/vfx/enemy_death_explosion.png"),
		"shield_impact": load("res://assets/vfx/shield_impact.png"),
		"levelup_burst": load("res://assets/vfx/levelup_burst.png"),
		"hit_spark": load("res://assets/vfx/hit_spark.png"),
	}
	enemy_textures = {
		"move-down": load("res://assets/enemies/red_scout_drone/move-down.png"),
		"move-up": load("res://assets/enemies/red_scout_drone/move-up.png"),
		"move-left": load("res://assets/enemies/red_scout_drone/move-left.png"),
		"move-right": load("res://assets/enemies/red_scout_drone/move-right.png"),
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
	score = 0
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
	var run_level := _get_run_level(elapsed)
	var stats := _get_enemy_stats(RED_SCOUT_DRONE_ID, run_level)
	var spawn_edges := ["top", "right", "bottom", "left"]
	var spawn_edge: String = spawn_edges[next_id % spawn_edges.size()]
	var inset: float = stats.radius + 8.0
	var drift := float((next_id * 71) % 100) / 100.0
	var position := Vector2(size.x * drift, size.y * drift)

	if spawn_edge == "top":
		position.y = -inset
	elif spawn_edge == "right":
		position.x = size.x + inset
	elif spawn_edge == "bottom":
		position.y = size.y + inset
	else:
		position.x = -inset

	enemies.append({
		"id": next_id,
		"type_id": RED_SCOUT_DRONE_ID,
		"position": position,
		"radius": stats.radius,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"speed": stats.speed * _get_enemy_speed_multiplier(elapsed),
		"contact_damage": stats.contact_damage,
		"xp_reward": stats.xp_reward,
		"score_reward": stats.score_reward,
		"spawn_edge": spawn_edge,
		"movement_frame": _get_enemy_movement_frame(spawn_edge),
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
		if particle.has("velocity"):
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
					score += enemy.score_reward
					_add_explosion(enemy.position, Color("#f97316"), true)
				else:
					_add_hit_spark(bullet.position)

	for enemy in enemies:
		if removed_enemy_ids.has(enemy.id):
			continue

		if _circles_overlap(player.position, player.radius, enemy.position, enemy.radius):
			player.hp = maxi(0, player.hp - enemy.contact_damage)
			removed_enemy_ids[enemy.id] = true
			_add_explosion(enemy.position, Color("#67e8f9"), false)

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

func _add_explosion(origin: Vector2, color: Color, large: bool) -> void:
	particles.append({
		"id": next_id,
		"position": origin,
		"life": SPRITE_PARTICLE_LIFETIME,
		"max_life": SPRITE_PARTICLE_LIFETIME,
		"texture_key": "enemy_death_explosion" if large else "small_explosion",
		"height": EXPLOSION_SPRITE_HEIGHT if large else EXPLOSION_SPRITE_HEIGHT * 0.72,
		"rotation": float(next_id % 12) * 0.12,
	})
	next_id += 1

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

func _add_hit_spark(origin: Vector2) -> void:
	particles.append({
		"id": next_id,
		"position": origin,
		"life": SPRITE_PARTICLE_LIFETIME * 0.62,
		"max_life": SPRITE_PARTICLE_LIFETIME * 0.62,
		"texture_key": "hit_spark",
		"height": HIT_SPARK_SPRITE_HEIGHT,
		"rotation": float(next_id % 10) * 0.2,
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
	var top_margin := 16.0
	var top_height := 48.0
	var right_width := 132.0
	var score_width := clampf(size.x * 0.34, 184.0, 296.0)
	if size.x < 520.0:
		score_width = minf(score_width, size.x - right_width - 48.0)
	var score_rect := Rect2(top_margin, top_margin, score_width, top_height)
	var right_rect := Rect2(size.x - right_width - top_margin, top_margin, right_width, top_height)
	var rail_start := score_rect.position.x + score_rect.size.x + 10.0
	var rail_end := right_rect.position.x - 10.0
	_draw_cockpit_rail(Rect2(rail_start, top_margin + 5.0, maxf(0.0, rail_end - rail_start), top_height - 10.0))
	_draw_score_module(score_rect)
	_draw_time_module(right_rect)

	var bottom_width := minf(282.0, maxf(210.0, size.x - 142.0))
	var bottom_rect := Rect2(16, size.y - 82, bottom_width, 62)
	var hp_percent := clampf(float(player.hp) / float(PLAYER_HP), 0.0, 1.0)
	_draw_status_module(bottom_rect, hp_percent)

	var core_size := 86.0
	var core_rect := Rect2(size.x - core_size - 16.0, size.y - core_size - 18.0, core_size, core_size)
	_draw_core_module(core_rect)

func _draw_particles() -> void:
	for particle in particles:
		if particle.has("texture_key"):
			var texture: Texture2D = vfx_textures.get(particle.texture_key)
			var max_life: float = particle.max_life
			var progress := 1.0 - clampf(particle.life / max_life, 0.0, 1.0)
			var alpha := clampf(particle.life / max_life, 0.0, 1.0)
			var height: float = particle.height * lerpf(0.72, 1.18, progress)
			_draw_centered_texture(texture, particle.position, height, particle.rotation, Color(1, 1, 1, alpha))
			continue

		var color: Color = particle.color
		color.a = clampf(particle.life / PARTICLE_LIFETIME, 0.0, 1.0)
		draw_circle(particle.position, particle.radius, color)

func _draw_bullets() -> void:
	for bullet in bullets:
		var texture: Texture2D = vfx_textures.get("player_plasma_bolt")
		if texture:
			var velocity: Vector2 = bullet.velocity
			var rotation: float = velocity.angle() + PI / 2.0
			_draw_centered_texture(texture, bullet.position, BULLET_SPRITE_HEIGHT, rotation, Color(1, 1, 1, 0.94))
		else:
			draw_circle(bullet.position, bullet.radius + 2.0, Color(0.4, 0.91, 0.98, 0.22))
			draw_circle(bullet.position, bullet.radius, Color("#67e8f9"))
			draw_arc(bullet.position, bullet.radius + 1.0, 0.0, TAU, 12, Color("#ecfeff"), 1.0)

func _draw_enemies() -> void:
	for enemy in enemies:
		var texture: Texture2D = enemy_textures.get(enemy.movement_frame, enemy_textures["move-down"])
		var visual_size: float = enemy.radius * 3.8
		var rect := Rect2(
			enemy.position - Vector2.ONE * visual_size / 2.0,
			Vector2.ONE * visual_size
		)
		draw_texture_rect(texture, rect, false)

func _draw_player() -> void:
	var texture: Texture2D = _get_player_ship_texture()
	var trail_texture: Texture2D = vfx_textures.get("engine_trail")
	var trail_alpha := 0.58 if status == "running" else 0.34
	_draw_centered_texture(trail_texture, player.position + Vector2(0, PLAYER_SPRITE_HEIGHT * 0.34), ENGINE_TRAIL_HEIGHT, 0.0, Color(1, 1, 1, trail_alpha))
	_draw_centered_texture(texture, player.position, PLAYER_SPRITE_HEIGHT, 0.0, Color.WHITE)

func _draw_ready_overlay(size: Vector2) -> void:
	var rect := Rect2(22, size.y * 0.24, size.x - 44, 224)
	_draw_lcars_panel(rect, UI_CYAN, "SYSTEM READY")
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 62), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 34, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 101), "Survive the sector. Your ship fires automatically.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 15, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 131), "Click or drag to steer. Weapons auto-target the nearest enemy.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 13, UI_CYAN)
	_draw_lcars_meter(Rect2(rect.position.x + 30, rect.position.y + 158, rect.size.x - 60, 9), 0.82, UI_TEAL, "SIGNAL", "82%")

func _draw_death_overlay(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.006, 0.018, 0.34))
	var rect := _get_death_card_rect(size)
	_draw_glass_panel(rect, UI_ORANGE, "", 0.34)
	_draw_lcars_block(Rect2(rect.position.x + 24, rect.position.y, 120, 7), UI_ORANGE, 0.72)
	_draw_lcars_block(Rect2(rect.position.x + 150, rect.position.y, 11, 7), UI_ORANGE, 0.32)
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 38), "RUN ENDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UI_ORANGE)
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 78), "SIGNAL LOST", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 30, UI_TEXT)
	draw_line(rect.position + Vector2(28, 96), rect.position + Vector2(rect.size.x - 28, 96), _with_alpha(UI_ORANGE, 0.28), 1.0)

	var stat_gap := 8.0
	var stat_width := (rect.size.x - 56.0 - stat_gap * 2.0) / 3.0
	var stat_y := rect.position.y + 118.0
	_draw_stat_pill(Rect2(rect.position.x + 28.0, stat_y, stat_width, 54.0), "KILLS", str(kills), UI_MAGENTA)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + stat_width + stat_gap, stat_y, stat_width, 54.0), "TIME", _format_time(elapsed), UI_CYAN)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + (stat_width + stat_gap) * 2.0, stat_y, stat_width, 54.0), "SCORE", str(_get_score()), UI_TEAL)
	_draw_signal_loss_bar(Rect2(rect.position.x + 30.0, rect.position.y + 198.0, rect.size.x - 60.0, 8.0))

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

func _draw_cockpit_rail(rect: Rect2) -> void:
	if rect.size.x <= 0.0:
		return
	var center_y := rect.position.y + rect.size.y / 2.0
	draw_line(Vector2(rect.position.x, center_y), Vector2(rect.position.x + rect.size.x, center_y), _with_alpha(UI_CYAN, 0.18), 1.0)
	draw_line(Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y), Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y), _with_alpha(UI_CYAN, 0.09), 1.0)
	draw_line(Vector2(rect.position.x + rect.size.x * 0.36, rect.position.y + rect.size.y), Vector2(rect.position.x + rect.size.x * 0.64, rect.position.y + rect.size.y), _with_alpha(UI_MAGENTA, 0.08), 1.0)
	var mark_x := rect.position.x + rect.size.x / 2.0
	draw_rect(Rect2(mark_x - 18.0, rect.position.y + 2.0, 36.0, 3.0), _with_alpha(UI_CYAN, 0.20))
	draw_rect(Rect2(mark_x - 4.0, rect.position.y + 2.0, 8.0, 3.0), _with_alpha(UI_MAGENTA, 0.32))

func _draw_score_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.26)
	_draw_lcars_block(Rect2(rect.position.x + 18, rect.position.y, rect.size.x * 0.58, 6), UI_CYAN, 0.64)
	_draw_lcars_block(Rect2(rect.position.x + rect.size.x * 0.62, rect.position.y, 8, 6), UI_CYAN, 0.30)
	draw_string(get_theme_default_font(), rect.position + Vector2(24, 17), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_CYAN)
	draw_string(get_theme_default_font(), rect.position + Vector2(24, 40), "%06d" % _get_score(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40, 22, UI_CYAN)

func _draw_time_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.16)
	_draw_compact_chip(Rect2(rect.position.x + 10, rect.position.y + 9, 72, 30), "TIME", _format_time(elapsed), UI_TEAL)
	_draw_compact_chip(Rect2(rect.position.x + 88, rect.position.y + 9, 34, 30), "EN", str(enemies.size()), UI_MAGENTA)

func _draw_status_module(rect: Rect2, hp_percent: float) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.18)
	draw_string(get_theme_default_font(), rect.position + Vector2(22, 18), "STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_CYAN)
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 25, rect.size.x - 44, 10), hp_percent, UI_TEAL, "HULL", str(player.hp))
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 45, rect.size.x - 44, 9), 0.72, UI_PLAYER_BLUE, "SHLD", "72%")

func _draw_core_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_MAGENTA, "", 0.25)
	var center := rect.position + rect.size / 2.0 + Vector2(0, 3)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 22), "CORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UI_MAGENTA)
	draw_circle(center, 24.0, _with_alpha(UI_MAGENTA, 0.07))
	draw_circle(center, 13.0, _with_alpha(UI_PURPLE, 0.34))
	draw_arc(center, 25.0, -PI * 0.42, PI * 0.86, 32, _with_alpha(UI_MAGENTA, 0.84), 5.0)
	draw_arc(center, 32.0, PI * 0.08, PI * 0.62, 18, _with_alpha(UI_CYAN, 0.18), 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(24, rect.size.y - 12), "AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UI_MAGENTA)

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

func _draw_glass_panel(rect: Rect2, accent: Color, label := "", intensity := 0.22) -> void:
	draw_rect(rect.grow(8.0), _with_alpha(accent, intensity * 0.16))
	draw_rect(rect, Color(0.025, 0.032, 0.075, 0.62))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.42)), Color(0.06, 0.08, 0.16, 0.28))
	draw_rect(rect, _with_alpha(accent, intensity), false, 1.0)
	_draw_corner_accents(rect, accent, minf(18.0, rect.size.y * 0.28))
	if label != "":
		draw_string(get_theme_default_font(), rect.position + Vector2(18, 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, accent)

func _draw_corner_accents(rect: Rect2, accent: Color, length: float) -> void:
	var color := _with_alpha(accent, 0.62)
	draw_line(rect.position, rect.position + Vector2(length, 0), color, 1.5)
	draw_line(rect.position, rect.position + Vector2(0, length), color, 1.5)
	draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x - length, 0), color, 1.5)
	draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x, length), color, 1.5)
	draw_line(rect.position + Vector2(0, rect.size.y), rect.position + Vector2(length, rect.size.y), _with_alpha(accent, 0.34), 1.0)
	draw_line(rect.position + Vector2(rect.size.x, rect.size.y), rect.position + Vector2(rect.size.x - length, rect.size.y), _with_alpha(accent, 0.34), 1.0)

func _draw_compact_chip(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_capsule(rect, _with_alpha(UI_PANEL_MID, 0.46))
	_draw_capsule_outline(rect, _with_alpha(accent, 0.30), 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 11), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UI_TEXT_DIM)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 25), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 18, 13, accent)

func _draw_compact_meter(rect: Rect2, percent: float, fill_color: Color, label: String, value: String) -> void:
	var clamped := clampf(percent, 0.0, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, fill_color)
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 48, -3), value, HORIZONTAL_ALIGNMENT_RIGHT, 48, 7, UI_TEXT)
	_draw_capsule(rect, _with_alpha(UI_BG, 0.60))
	_draw_capsule(Rect2(rect.position, Vector2(maxf(rect.size.y, rect.size.x * clamped), rect.size.y)), _with_alpha(fill_color, 0.78))
	_draw_capsule_outline(rect, _with_alpha(fill_color, 0.34), 1.0)

func _draw_stat_pill(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_glass_panel(rect, accent, "", 0.20)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 19), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_TEXT_DIM)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 43), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 17, accent)

func _draw_signal_loss_bar(rect: Rect2) -> void:
	draw_string(get_theme_default_font(), rect.position + Vector2(0, -8), "SIGNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_ORANGE)
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 38, -8), "LOST", HORIZONTAL_ALIGNMENT_RIGHT, 38, 8, UI_TEXT_DIM)
	_draw_capsule(rect, _with_alpha(UI_ORANGE, 0.12))
	_draw_capsule(Rect2(rect.position, Vector2(rect.size.x * 0.22, rect.size.y)), _with_alpha(UI_ORANGE, 0.82))
	_draw_capsule_outline(rect, _with_alpha(UI_ORANGE, 0.48), 1.0)

func _draw_stat_block(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_panel(rect, _with_alpha(UI_PANEL_MID, 0.72), _with_alpha(accent, 0.34))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UI_TEXT_DIM)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 43), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 18, accent)

func _draw_capsule(rect: Rect2, color: Color) -> void:
	var radius := rect.size.y / 2.0
	draw_rect(Rect2(rect.position + Vector2(radius, 0), Vector2(maxf(0.0, rect.size.x - radius * 2.0), rect.size.y)), color)
	draw_circle(rect.position + Vector2(radius, radius), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x - radius, radius), radius, color)

func _draw_capsule_outline(rect: Rect2, color: Color, width: float) -> void:
	var radius := rect.size.y / 2.0
	var left_center := rect.position + Vector2(radius, radius)
	var right_center := rect.position + Vector2(rect.size.x - radius, radius)
	draw_line(rect.position + Vector2(radius, 0), rect.position + Vector2(rect.size.x - radius, 0), color, width)
	draw_line(rect.position + Vector2(radius, rect.size.y), rect.position + Vector2(rect.size.x - radius, rect.size.y), color, width)
	draw_arc(left_center, radius, PI * 0.5, PI * 1.5, 12, color, width)
	draw_arc(right_center, radius, -PI * 0.5, PI * 0.5, 12, color, width)

func _draw_scanlines(size: Vector2) -> void:
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018), 1.0)

func _draw_centered_texture(texture: Texture2D, center: Vector2, height: float, rotation := 0.0, modulate := Color.WHITE) -> void:
	if texture == null:
		return

	var width := height * float(texture.get_width()) / maxf(1.0, float(texture.get_height()))
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-width / 2.0, -height / 2.0), Vector2(width, height)), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _with_alpha(color: Color, alpha: float) -> Color:
	var next := color
	next.a = alpha
	return next

func _layout_buttons() -> void:
	if not is_instance_valid(action_button) or not is_instance_valid(header_restart_button) or not is_instance_valid(enemies_button):
		return

	var size := get_viewport_rect().size
	if status == "dead":
		var death_rect := _get_death_card_rect(size)
		action_button.size = Vector2(minf(176.0, death_rect.size.x - 72.0), 46.0)
		action_button.position = death_rect.position + Vector2((death_rect.size.x - action_button.size.x) / 2.0, 226.0)
		enemies_button.size = Vector2(0, 0)
	else:
		action_button.size = Vector2(170, 50)
		action_button.position = Vector2((size.x - action_button.size.x) / 2.0, size.y * 0.24 + 176)
		enemies_button.size = Vector2(138, 38)
		enemies_button.position = Vector2((size.x - enemies_button.size.x) / 2.0, action_button.position.y + 58.0)
	header_restart_button.size = Vector2(78, 28)
	header_restart_button.position = Vector2(size.x - header_restart_button.size.x - 16.0, 70.0)

func _update_buttons() -> void:
	_layout_buttons()
	header_restart_button.visible = status == "running"
	action_button.visible = status == "ready" or status == "dead"
	enemies_button.visible = status == "ready"
	action_button.text = "Start Run" if status == "ready" else "Restart Run"
	enemies_button.text = "Enemies"
	var next_action_key := "dead" if status == "dead" else "ready"
	if action_button_style_key != next_action_key:
		_apply_button_style(action_button, UI_ORANGE if status == "dead" else UI_CYAN, false)
		action_button_style_key = next_action_key
	if header_button_style_key != "running-tab":
		_apply_button_style(header_restart_button, UI_MAGENTA, true)
		header_button_style_key = "running-tab"
	if enemies_button_style_key != "ready-link":
		_apply_button_style(enemies_button, UI_TEAL, true)
		enemies_button_style_key = "ready-link"

func _on_action_button_pressed() -> void:
	start_run()

func _on_enemies_button_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.location.href = '/void-drifter/enemies';", true)
	else:
		OS.shell_open("http://localhost:8081/void-drifter/enemies")

func _style_buttons() -> void:
	_apply_button_style(action_button, UI_CYAN, false)
	action_button_style_key = "ready"
	_apply_button_style(header_restart_button, UI_MAGENTA, true)
	header_button_style_key = "running-tab"
	_apply_button_style(enemies_button, UI_TEAL, true)
	enemies_button_style_key = "ready-link"

func _apply_button_style(button: Button, accent: Color, compact: bool) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(_with_alpha(UI_PANEL_MID, 0.70), accent, 0.58, compact))
	button.add_theme_stylebox_override("hover", _make_button_style(_with_alpha(accent, 0.18), accent, 0.92, compact))
	button.add_theme_stylebox_override("pressed", _make_button_style(_with_alpha(accent, 0.30), accent, 1.0, compact))
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 12 if compact else 15)

func _make_button_style(fill: Color, border: Color, border_alpha: float, compact: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = _with_alpha(border, border_alpha)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 16 if compact else 18
	style.corner_radius_top_right = 7 if compact else 8
	style.corner_radius_bottom_right = 16 if compact else 18
	style.corner_radius_bottom_left = 7 if compact else 8
	style.shadow_color = _with_alpha(border, 0.18)
	style.shadow_size = 5 if compact else 10
	return style

func _get_death_card_rect(size: Vector2) -> Rect2:
	var card_width := minf(420.0, size.x - 40.0)
	var card_height := 292.0
	return Rect2((size.x - card_width) / 2.0, maxf(92.0, size.y * 0.22), card_width, card_height)

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

func _get_run_level(seconds: float) -> int:
	return 1 + int(floor(seconds / 30.0))

func _get_enemy_definition(enemy_type_id: String) -> Dictionary:
	return ENEMY_DEFINITIONS[enemy_type_id]

func _get_enemy_stats(enemy_type_id: String, level: int) -> Dictionary:
	var definition := _get_enemy_definition(enemy_type_id)
	var base_stats: Dictionary = definition.base_stats
	var scaling: Dictionary = definition.scaling
	var level_offset := maxi(0, level - 1)
	return {
		"level": level,
		"hp": base_stats.hp + scaling.hp_per_level * level_offset,
		"speed": base_stats.speed + scaling.speed_per_level * level_offset,
		"contact_damage": base_stats.contact_damage + scaling.damage_per_level * level_offset,
		"xp_reward": base_stats.xp_reward,
		"score_reward": base_stats.score_reward,
		"radius": base_stats.radius,
	}

func _get_enemy_movement_frame(spawn_edge: String) -> String:
	return ENEMY_MOVEMENT_FRAMES_BY_EDGE.get(spawn_edge, "move-down")

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
	return score + int(floor(elapsed)) * 5
