extends Control

# Gameplay tuning
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
const DAMAGE_BULLET := 1
const ENEMY_PROJECTILE_SPEED := 190.0
const ENEMY_PROJECTILE_DAMAGE := 7
const ENEMY_PROJECTILE_RADIUS := 6.0
const ENEMY_FIRE_COOLDOWN := 2.7
const SURGE_KILL_INTERVAL := 12
const SURGE_BASE_COUNT := 5
const SURGE_MAX_COUNT := 9
const SURGE_SPAWN_INTERVAL := 220.0
const SURGE_CLEAR_BONUS_BASE := 250
const SURGE_CLEAR_BONUS_STEP := 75
const MAX_DELTA_SECONDS := 0.033

# Visual tuning
const PARTICLE_LIFETIME := 0.42
const SPRITE_PARTICLE_LIFETIME := 0.34
const BULLET_SPRITE_HEIGHT := 34.0
const BULLET_TRAIL_LENGTH := 24.0
const ENGINE_TRAIL_HEIGHT := 52.0
const EXPLOSION_SPRITE_HEIGHT := 74.0
const LARGE_EXPLOSION_SPRITE_HEIGHT := 98.0
const HIT_SPARK_SPRITE_HEIGHT := 30.0
const SHIELD_IMPACT_SPRITE_HEIGHT := 96.0
const ENEMY_DAMAGE_FLASH_SECONDS := 0.16
const PLAYER_DAMAGE_FLASH_SECONDS := 0.22
const ENEMY_VISUAL_BASE_ALPHA := 0.34
const ENEMY_ATTACK_RANGE := 280.0
const ENEMY_ATTACK_SPRITE_HEIGHT := 82.0
const ENEMY_HIT_SPRITE_HEIGHT := 74.0
const ENEMY_DEATH_SPRITE_HEIGHT := 102.0
const ENEMY_PROJECTILE_PREVIEW_HEIGHT := 22.0

# HUD presentation
const SECTOR_LABEL := "23"
const WAVE_TARGET := 15
const WEAPON_SLOT_SIZE := 42.0
const WEAPON_SLOT_GAP := 8.0
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
const RED_FIGHTER_ID := "red_fighter"
const RED_CRUISER_ID := "red_cruiser"
const ENEMY_FRAME_STATES := ["idle", "thrust", "attack", "hit"]
const ENEMY_FRAME_DIRECTIONS := ["down", "up", "left", "right"]
const ENEMY_DEFINITIONS := {
	"red_scout_drone": {
		"id": "red_scout_drone",
		"name": "Red Scout Drone",
		"role": "Fast fodder / swarm scout",
		"description": "Fast red hostile scout drone that enters from screen edges and chases the player.",
		"status": "active",
		"death_vfx_key": "enemy_death_small",
		"death_vfx_height": 82.0,
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
	"red_fighter": {
		"id": "red_fighter",
		"name": "Red Fighter",
		"role": "Medium aggressive flanker",
		"description": "Sharper red attack craft that joins after the first scout pressure spike.",
		"status": "active",
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 104.0,
		"base_stats": {
			"hp": 34,
			"speed": 42.0,
			"contact_damage": 14,
			"xp_reward": 8,
			"score_reward": 22,
			"radius": 25.0,
		},
		"scaling": {
			"hp_per_level": 5,
			"speed_per_level": 1.0,
			"damage_per_level": 1.4,
		},
		"spawn": {
			"weight": 35,
			"min_run_level": 2,
		},
		"abilities": ["chase_player", "contact_damage", "flank_player_later"],
	},
	"red_cruiser": {
		"id": "red_cruiser",
		"name": "Red Cruiser",
		"role": "Heavy tank / slow pressure ship",
		"description": "Broad armored pressure ship that adds slower, heavier pressure later in a run.",
		"status": "active",
		"death_vfx_key": "enemy_death_large",
		"death_vfx_height": 132.0,
		"base_stats": {
			"hp": 90,
			"speed": 25.0,
			"contact_damage": 24,
			"xp_reward": 18,
			"score_reward": 60,
			"radius": 38.0,
		},
		"scaling": {
			"hp_per_level": 11,
			"speed_per_level": 0.4,
			"damage_per_level": 2.2,
		},
		"spawn": {
			"weight": 12,
			"min_run_level": 4,
		},
		"abilities": ["chase_player", "contact_damage", "spread_fire_later"],
	},
}
const ENEMY_MOVEMENT_FRAMES_BY_EDGE := {
	"top": "down",
	"bottom": "up",
	"left": "right",
	"right": "left",
}
const SURGE_PATTERNS := ["edge_pincer", "vertical_rain", "spiral_drift", "layer_breach"]

const BACKGROUND_SECTORS := [
	{ "id": "nebula-blue", "path": "res://assets/backgrounds/sectors/sector_nebula_blue.png", "opacity": 0.72 },
	{ "id": "fractal-asteroids", "path": "res://assets/backgrounds/sectors/sector_fractal_asteroids.png", "opacity": 0.66 },
	{ "id": "purple-rift", "path": "res://assets/backgrounds/sectors/sector_purple_rift.png", "opacity": 0.68 },
]
const PARALLAX_LAYERS := [
	{ "id": "legacy-stars", "path": "res://assets/backgrounds/bg_far_stars.png", "speed": 8.0, "opacity": 0.44 },
	{ "id": "deep-void", "path": "res://assets/backgrounds/parallax/layer_deep_void.png", "speed": 11.0, "opacity": 0.30 },
	{ "id": "cosmic-clouds", "path": "res://assets/backgrounds/parallax/layer_cosmic_clouds.png", "speed": 17.0, "opacity": 0.24 },
	{ "id": "starfield-dense", "path": "res://assets/backgrounds/parallax/layer_starfield_dense.png", "speed": 26.0, "opacity": 0.22 },
	{ "id": "legacy-nebula", "path": "res://assets/backgrounds/bg_mid_nebula.png", "speed": 34.0, "opacity": 0.22 },
	{ "id": "legacy-asteroids", "path": "res://assets/backgrounds/bg_near_asteroids.png", "speed": 52.0, "opacity": 0.14 },
]
const MIDFIELD_LAYERS := [
	{ "id": "cyan-haze", "path": "res://assets/backgrounds/midfield/midfield_cyan_haze.png", "speed": 21.0, "opacity": 0.13 },
	{ "id": "violet-haze", "path": "res://assets/backgrounds/midfield/midfield_violet_haze.png", "speed": 29.0, "opacity": 0.12 },
	{ "id": "dark-texture", "path": "res://assets/backgrounds/midfield/midfield_dark_texture.png", "speed": 37.0, "opacity": 0.11 },
]
const FOREGROUND_LAYERS := [
	{ "id": "cockpit-shadow", "path": "res://assets/backgrounds/foreground/foreground_cockpit_shadow.png", "speed": 44.0, "opacity": 0.10 },
	{ "id": "neon-frame", "path": "res://assets/backgrounds/foreground/foreground_neon_frame.png", "speed": 58.0, "opacity": 0.08 },
	{ "id": "cosmic-veil", "path": "res://assets/backgrounds/foreground/foreground_cosmic_veil.png", "speed": 68.0, "opacity": 0.09 },
]

@onready var action_button: Button = $ActionButton
@onready var header_restart_button: Button = $HeaderRestartButton
@onready var enemies_button: Button = $EnemiesButton

var ship_textures := {}
var enemy_textures := {}
var vfx_textures := {}
var sector_textures: Array[Texture2D] = []
var background_textures: Array[Texture2D] = []
var midfield_textures: Array[Texture2D] = []
var foreground_textures: Array[Texture2D] = []
var status := "ready"
var player := {}
var player_target := Vector2.ZERO
var player_velocity_x := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var kills := 0
var score := 0
var elapsed := 0.0
var background_time := 0.0
var spawn_timer := FIRST_ENEMY_SPAWN_DELAY
var fire_timer := PLAYER_FIRE_INTERVAL * 0.6
var next_id := 1
var pointer_down := false
var player_damage_flash := 0.0
var surge_active := false
var surge_level := 0
var next_surge_kills := SURGE_KILL_INTERVAL
var surge_remaining_spawns := 0
var surge_alive_ids := {}
var surge_spawn_timer := 0.0
var surge_message := ""
var surge_message_timer := 0.0
var surge_current_pattern := "edge_pincer"
var surge_spawn_index := 0
var surge_bonus_score := SURGE_CLEAR_BONUS_BASE
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
		"icon": load("res://assets/player_ship/player_ship_icon.png"),
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
		"enemy_death_small": _load_png_texture("res://assets/enemies/shared_vfx/death-small.png"),
		"enemy_death_medium": _load_png_texture("res://assets/enemies/shared_vfx/death-medium.png"),
		"enemy_death_large": _load_png_texture("res://assets/enemies/shared_vfx/death-large.png"),
	}
	enemy_textures = {
		RED_SCOUT_DRONE_ID: _load_enemy_texture_set(RED_SCOUT_DRONE_ID),
		RED_FIGHTER_ID: _load_enemy_texture_set(RED_FIGHTER_ID),
		RED_CRUISER_ID: _load_enemy_texture_set(RED_CRUISER_ID),
	}
	for sector in BACKGROUND_SECTORS:
		sector_textures.append(load(sector.path))
	for layer in PARALLAX_LAYERS:
		background_textures.append(load(layer.path))
	for layer in MIDFIELD_LAYERS:
		midfield_textures.append(load(layer.path))
	for layer in FOREGROUND_LAYERS:
		foreground_textures.append(load(layer.path))
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
	enemy_projectiles = []
	particles = []
	kills = 0
	score = 0
	elapsed = 0.0
	background_time = 0.0
	spawn_timer = FIRST_ENEMY_SPAWN_DELAY
	fire_timer = PLAYER_FIRE_INTERVAL * 0.6
	next_id = 1
	pointer_down = false
	player_damage_flash = 0.0
	surge_active = false
	surge_level = 0
	next_surge_kills = SURGE_KILL_INTERVAL
	surge_remaining_spawns = 0
	surge_alive_ids = {}
	surge_spawn_timer = 0.0
	surge_message = ""
	surge_message_timer = 0.0
	surge_current_pattern = "edge_pincer"
	surge_spawn_index = 0
	surge_bonus_score = SURGE_CLEAR_BONUS_BASE
	_update_buttons()
	queue_redraw()

func start_run() -> void:
	reset_world("running")

func _update_world(delta: float) -> void:
	var delta_ms := delta * 1000.0
	elapsed += delta
	_update_player(delta)
	_update_enemy_spawning(delta_ms)
	_update_surge_waves(delta_ms, delta)
	_update_weapons(delta_ms)
	_update_enemy_movement(delta)
	_update_enemy_weapons(delta)
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
	if surge_active:
		return

	spawn_timer -= delta_ms
	if spawn_timer <= 0.0 and enemies.size() < _get_max_enemies(elapsed):
		_spawn_enemy()
		spawn_timer = _get_spawn_interval(elapsed)

func _spawn_enemy() -> void:
	var run_level := _get_run_level(elapsed)
	var enemy_type_id := _choose_enemy_type_id(run_level, next_id * 97)
	_spawn_enemy_at(_get_regular_spawn_position(enemy_type_id), 0, enemy_type_id)

func _spawn_enemy_at(spawn_data: Dictionary, surge_id := 0, enemy_type_id := "") -> void:
	var size := get_viewport_rect().size
	var run_level := _get_run_level(elapsed)
	var resolved_enemy_type_id := enemy_type_id
	if resolved_enemy_type_id == "":
		resolved_enemy_type_id = _choose_enemy_type_id(run_level, next_id * 97)
	var stats := _get_enemy_stats(resolved_enemy_type_id, run_level)
	var spawn_edge: String = str(spawn_data.get("edge", "top"))
	var position: Vector2 = spawn_data.get("position", Vector2(size.x / 2.0, -stats.radius - 8.0))
	var enemy_id := next_id
	next_id += 1

	enemies.append({
		"id": enemy_id,
		"type_id": resolved_enemy_type_id,
		"position": position,
		"radius": stats.radius,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"speed": stats.speed * _get_enemy_speed_multiplier(elapsed),
		"contact_damage": stats.contact_damage,
		"xp_reward": stats.xp_reward,
		"score_reward": stats.score_reward,
		"spawn_edge": spawn_edge,
		"direction": _get_enemy_movement_frame(spawn_edge),
		"visual_state": "idle",
		"hit_flash": 0.0,
		"fire_cooldown": 1.15 + float(next_id % 4) * 0.34,
		"surge_id": surge_id,
	})
	if surge_id > 0:
		surge_alive_ids[enemy_id] = true
		_add_surge_breach_effect(position, spawn_edge)

func _get_regular_spawn_position(enemy_type_id: String) -> Dictionary:
	var size := get_viewport_rect().size
	var run_level := _get_run_level(elapsed)
	var stats := _get_enemy_stats(enemy_type_id, run_level)
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

	return { "edge": spawn_edge, "position": position }

func _update_surge_waves(delta_ms: float, delta: float) -> void:
	surge_message_timer = maxf(0.0, surge_message_timer - delta)
	if not surge_active:
		return

	surge_spawn_timer -= delta_ms
	while surge_remaining_spawns > 0 and surge_spawn_timer <= 0.0:
		var spawned_index := _get_current_surge_enemy_count() - surge_remaining_spawns
		var spawn_data := _get_surge_spawn_position(spawned_index, _get_current_surge_enemy_count(), surge_current_pattern)
		_spawn_enemy_at(spawn_data, surge_level)
		surge_remaining_spawns -= 1
		surge_spawn_index += 1
		surge_spawn_timer += SURGE_SPAWN_INTERVAL

	_check_surge_clear()

func _maybe_start_surge() -> void:
	if surge_active or kills < next_surge_kills:
		return

	surge_level += 1
	next_surge_kills += SURGE_KILL_INTERVAL
	surge_active = true
	surge_remaining_spawns = _get_current_surge_enemy_count()
	surge_alive_ids = {}
	surge_spawn_timer = 0.0
	surge_spawn_index = 0
	surge_current_pattern = SURGE_PATTERNS[(surge_level - 1) % SURGE_PATTERNS.size()]
	surge_bonus_score = SURGE_CLEAR_BONUS_BASE + (surge_level - 1) * SURGE_CLEAR_BONUS_STEP
	surge_message = "RED SURGE " + _format_roman(surge_level)
	surge_message_timer = 1.65

func _get_current_surge_enemy_count() -> int:
	return mini(SURGE_MAX_COUNT, SURGE_BASE_COUNT + surge_level)

func _get_surge_spawn_position(index: int, total: int, pattern: String) -> Dictionary:
	var size := get_viewport_rect().size
	var stats := _get_enemy_stats(RED_SCOUT_DRONE_ID, _get_run_level(elapsed))
	var inset: float = stats.radius + 18.0
	var progress := float(index + 1) / float(maxi(1, total + 1))

	match pattern:
		"edge_pincer":
			var edge := "left" if index % 2 == 0 else "right"
			var y := size.y * progress
			return { "edge": edge, "position": Vector2(-inset if edge == "left" else size.x + inset, y) }
		"vertical_rain":
			return { "edge": "top", "position": Vector2(size.x * progress, -inset - float(index % 3) * 12.0) }
		"spiral_drift":
			var edges := ["top", "right", "bottom", "left"]
			var edge: String = edges[index % edges.size()]
			var wobble := 0.18 + fmod(float(index) * 0.29, 0.64)
			if edge == "top":
				return { "edge": edge, "position": Vector2(size.x * wobble, -inset) }
			if edge == "right":
				return { "edge": edge, "position": Vector2(size.x + inset, size.y * wobble) }
			if edge == "bottom":
				return { "edge": edge, "position": Vector2(size.x * (1.0 - wobble), size.y + inset) }
			return { "edge": edge, "position": Vector2(-inset, size.y * (1.0 - wobble)) }
		"layer_breach":
			var breach_edges := ["bottom", "left", "right", "top"]
			var edge: String = breach_edges[(index + surge_level) % breach_edges.size()]
			var offset := fmod(float(index * 37 + surge_level * 19), 100.0) / 100.0
			if edge == "bottom":
				return { "edge": edge, "position": Vector2(size.x * offset, size.y + inset + 22.0) }
			if edge == "left":
				return { "edge": edge, "position": Vector2(-inset - 22.0, size.y * offset) }
			if edge == "right":
				return { "edge": edge, "position": Vector2(size.x + inset + 22.0, size.y * offset) }
			return { "edge": edge, "position": Vector2(size.x * offset, -inset - 22.0) }

	return _get_regular_spawn_position(RED_SCOUT_DRONE_ID)

func _mark_surge_enemy_removed(enemy: Dictionary) -> void:
	if int(enemy.get("surge_id", 0)) <= 0:
		return
	surge_alive_ids.erase(enemy.id)

func _check_surge_clear() -> void:
	if not surge_active or player.hp <= 0 or surge_remaining_spawns > 0 or not surge_alive_ids.is_empty():
		return

	score += surge_bonus_score
	surge_message = "SURGE CLEARED +" + str(surge_bonus_score)
	surge_message_timer = 1.75
	surge_active = false
	spawn_timer = minf(spawn_timer, _get_spawn_interval(elapsed) * 0.55)

func _add_surge_breach_effect(origin: Vector2, edge: String) -> void:
	var direction := Vector2.DOWN
	match edge:
		"bottom":
			direction = Vector2.UP
		"left":
			direction = Vector2.RIGHT
		"right":
			direction = Vector2.LEFT
	var center := origin + direction * 20.0
	for index in range(5):
		var angle := TAU * float(index) / 5.0 + float(next_id) * 0.11
		particles.append({
			"id": next_id,
			"position": center,
			"radius": 2.0 + float(index % 2),
			"velocity": Vector2(cos(angle), sin(angle)) * (38.0 + float(index) * 8.0),
			"life": PARTICLE_LIFETIME * 0.7,
			"color": UI_ORANGE if index % 2 == 0 else UI_MAGENTA,
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
		var velocity: Vector2 = direction * enemy.speed
		enemy.position += velocity * delta
		enemy.direction = _get_direction_from_velocity(velocity)
		enemy.visual_state = "hit" if float(enemy.get("hit_flash", 0.0)) > 0.0 else "thrust"

func _update_enemy_weapons(delta: float) -> void:
	if player.is_empty():
		return

	for enemy in enemies:
		enemy.fire_cooldown = maxf(0.0, float(enemy.get("fire_cooldown", 0.0)) - delta)
		var attack_charge := _get_enemy_attack_charge(enemy)
		if attack_charge < 0.92 or enemy.fire_cooldown > 0.0:
			continue

		_fire_enemy_projectile(enemy)
		enemy.fire_cooldown = ENEMY_FIRE_COOLDOWN + float(enemy.id % 3) * 0.28

func _fire_enemy_projectile(enemy: Dictionary) -> void:
	var direction: Vector2 = _get_enemy_forward_direction(enemy)
	if direction.length_squared() <= 0.01:
		return

	var origin: Vector2 = enemy.position + direction * (float(enemy.radius) + ENEMY_PROJECTILE_RADIUS + 2.0)
	enemy_projectiles.append({
		"id": next_id,
		"position": origin,
		"radius": ENEMY_PROJECTILE_RADIUS,
		"velocity": direction.normalized() * ENEMY_PROJECTILE_SPEED,
		"damage": ENEMY_PROJECTILE_DAMAGE,
		"life": 2.2,
	})
	next_id += 1

func _update_projectiles(delta: float) -> void:
	for bullet in bullets:
		bullet.position += bullet.velocity * delta
		bullet.life -= delta

	for projectile in enemy_projectiles:
		projectile.position += projectile.velocity * delta
		projectile.life -= delta

func _update_effects(delta: float) -> void:
	player_damage_flash = maxf(0.0, player_damage_flash - delta)
	for enemy in enemies:
		enemy.hit_flash = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)

	for particle in particles:
		if particle.has("velocity"):
			particle.position += particle.velocity * delta
		particle.life -= delta
	particles = particles.filter(func(particle): return particle.life > 0.0)

func _resolve_collisions() -> void:
	var removed_bullet_ids := {}
	var removed_enemy_projectile_ids := {}
	var removed_enemy_ids := {}

	for bullet in bullets:
		for enemy in enemies:
			if removed_enemy_ids.has(enemy.id) or removed_bullet_ids.has(bullet.id):
				continue

			if _circles_overlap(bullet.position, bullet.radius, enemy.position, enemy.radius):
				enemy.hp -= DAMAGE_BULLET
				enemy.hit_flash = ENEMY_DAMAGE_FLASH_SECONDS
				removed_bullet_ids[bullet.id] = true
				_add_hit_spark(bullet.position)
				if enemy.hp <= 0:
					removed_enemy_ids[enemy.id] = true
					_mark_surge_enemy_removed(enemy)
					kills += 1
					score += enemy.score_reward
					_add_enemy_death_explosion(enemy, Color("#f97316"))
					_maybe_start_surge()

	for enemy in enemies:
		if removed_enemy_ids.has(enemy.id):
			continue

		if _circles_overlap(player.position, player.radius, enemy.position, enemy.radius):
			player.hp = maxi(0, player.hp - enemy.contact_damage)
			player_damage_flash = PLAYER_DAMAGE_FLASH_SECONDS
			removed_enemy_ids[enemy.id] = true
			_mark_surge_enemy_removed(enemy)
			_add_sprite_effect(player.position, "shield_impact", SHIELD_IMPACT_SPRITE_HEIGHT, SPRITE_PARTICLE_LIFETIME * 1.05, 0.0)
			_add_explosion(enemy.position, Color("#67e8f9"), false)

	for projectile in enemy_projectiles:
		if removed_enemy_projectile_ids.has(projectile.id):
			continue

		if _circles_overlap(player.position, player.radius, projectile.position, projectile.radius):
			player.hp = maxi(0, player.hp - int(projectile.damage))
			player_damage_flash = PLAYER_DAMAGE_FLASH_SECONDS
			removed_enemy_projectile_ids[projectile.id] = true
			_add_sprite_effect(player.position, "shield_impact", SHIELD_IMPACT_SPRITE_HEIGHT * 0.82, SPRITE_PARTICLE_LIFETIME * 0.8, 0.0)
			_add_hit_spark(projectile.position)

	enemies = enemies.filter(func(enemy): return not removed_enemy_ids.has(enemy.id))
	_remove_expired_projectiles(removed_bullet_ids)
	_remove_expired_enemy_projectiles(removed_enemy_projectile_ids)
	_check_surge_clear()

	if player.hp <= 0:
		status = "dead"
		bullets = []
		enemy_projectiles = []
		enemies = []

func _remove_expired_projectiles(removed_bullet_ids: Dictionary) -> void:
	var size := get_viewport_rect().size
	bullets = bullets.filter(func(bullet):
		var position: Vector2 = bullet.position
		var in_bounds := position.x > -24.0 and position.x < size.x + 24.0 and position.y > -24.0 and position.y < size.y + 24.0
		return not removed_bullet_ids.has(bullet.id) and bullet.life > 0.0 and in_bounds
	)

func _remove_expired_enemy_projectiles(removed_projectile_ids: Dictionary) -> void:
	var size := get_viewport_rect().size
	enemy_projectiles = enemy_projectiles.filter(func(projectile):
		var position: Vector2 = projectile.position
		var in_bounds := position.x > -32.0 and position.x < size.x + 32.0 and position.y > -32.0 and position.y < size.y + 32.0
		return not removed_projectile_ids.has(projectile.id) and projectile.life > 0.0 and in_bounds
	)

func _add_enemy_death_explosion(enemy: Dictionary, color: Color) -> void:
	var definition := _get_enemy_definition(str(enemy.get("type_id", RED_SCOUT_DRONE_ID)))
	var vfx_key: String = str(definition.get("death_vfx_key", "enemy_death_small"))
	var vfx_height: float = float(definition.get("death_vfx_height", ENEMY_DEATH_SPRITE_HEIGHT))
	var origin: Vector2 = enemy.position
	_add_sprite_effect(
		origin,
		vfx_key,
		vfx_height,
		SPRITE_PARTICLE_LIFETIME * 1.35,
		float(next_id % 12) * 0.12
	)

	var debris_count := 10
	if float(enemy.radius) >= 36.0:
		debris_count = 14
	elif float(enemy.radius) >= 24.0:
		debris_count = 12

	for index in range(debris_count):
		var angle := TAU * float(index) / float(debris_count) + float(next_id) * 0.17
		var speed := 72.0 + float(index) * 10.0
		particles.append({
			"id": next_id,
			"position": origin,
			"radius": 2.0 + float(index % 2),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": PARTICLE_LIFETIME,
			"color": color,
		})
		next_id += 1

func _add_explosion(origin: Vector2, color: Color, large: bool) -> void:
	_add_sprite_effect(
		origin,
		"enemy_death_small" if large else "small_explosion",
		ENEMY_DEATH_SPRITE_HEIGHT if large else EXPLOSION_SPRITE_HEIGHT * 0.72,
		SPRITE_PARTICLE_LIFETIME * (1.35 if large else 0.86),
		float(next_id % 12) * 0.12
	)

	var debris_count := 10 if large else 6
	for index in range(debris_count):
		var angle := TAU * float(index) / float(debris_count) + float(next_id) * 0.17
		var speed := (72.0 if large else 52.0) + float(index) * (10.0 if large else 11.0)
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
	_add_sprite_effect(origin, "hit_spark", HIT_SPARK_SPRITE_HEIGHT, SPRITE_PARTICLE_LIFETIME * 0.62, float(next_id % 10) * 0.2)

func _add_sprite_effect(origin: Vector2, texture_key: String, height: float, lifetime: float, rotation: float) -> void:
	particles.append({
		"id": next_id,
		"position": origin,
		"life": lifetime,
		"max_life": lifetime,
		"texture_key": texture_key,
		"height": height,
		"rotation": rotation,
	})
	next_id += 1

func _draw() -> void:
	var size := get_viewport_rect().size
	_draw_background(size)
	_draw_particles()
	_draw_bullets()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_player()
	_draw_foreground_environment(size)
	_draw_hud(size)
	_draw_surge_message(size)
	if status == "ready":
		_draw_ready_overlay(size)
	elif status == "dead":
		_draw_death_overlay(size)

func _draw_background(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#030712"))
	_draw_sector_background(size)
	_draw_scrolling_layers(background_textures, PARALLAX_LAYERS, size)
	_draw_scrolling_layers(midfield_textures, MIDFIELD_LAYERS, size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.012, 0.04, 0.50))
	_draw_gameplay_center_mask(size)
	_draw_scanlines(size)
	draw_rect(Rect2(0.0, size.y * 0.68, size.x, 1.0), _with_alpha(UI_CYAN, 0.18))

func _draw_foreground_environment(size: Vector2) -> void:
	_draw_scrolling_layers(foreground_textures, FOREGROUND_LAYERS, size)

func _draw_gameplay_center_mask(size: Vector2) -> void:
	var side_width := maxf(18.0, size.x * 0.08)
	draw_rect(Rect2(side_width, 74.0, maxf(0.0, size.x - side_width * 2.0), maxf(0.0, size.y - 168.0)), Color(0.0, 0.008, 0.028, 0.20))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 92.0)), Color(0.0, 0.0, 0.012, 0.20))
	draw_rect(Rect2(0.0, size.y - 110.0, size.x, 110.0), Color(0.0, 0.0, 0.012, 0.22))

func _draw_sector_background(size: Vector2) -> void:
	if sector_textures.is_empty():
		return

	var sector_index := _get_active_sector_index()
	var sector = BACKGROUND_SECTORS[sector_index]
	_draw_texture_cover(
		sector_textures[sector_index],
		Rect2(Vector2.ZERO, size),
		Color(1, 1, 1, sector.opacity)
	)

func _draw_scrolling_layers(textures: Array[Texture2D], layer_defs: Array, size: Vector2) -> void:
	var layer_count := mini(textures.size(), layer_defs.size())
	for index in range(layer_count):
		var texture := textures[index]
		if texture == null:
			continue

		var layer = layer_defs[index]
		var source_width := maxf(1.0, float(texture.get_width()))
		var source_height := maxf(1.0, float(texture.get_height()))
		var tile_height := maxf(size.y, size.x * source_height / source_width)
		var offset := fmod(background_time * layer.speed, tile_height)
		var color := Color(1, 1, 1, layer.opacity)
		for tile_index in [-1, 0]:
			var rect := Rect2(0.0, offset + float(tile_index) * tile_height, size.x, tile_height)
			draw_texture_rect(texture, rect, false, color)

func _draw_texture_cover(texture: Texture2D, rect: Rect2, modulate := Color.WHITE) -> void:
	if texture == null:
		return

	var source_size := Vector2(
		maxf(1.0, float(texture.get_width())),
		maxf(1.0, float(texture.get_height()))
	)
	var scale := maxf(rect.size.x / source_size.x, rect.size.y / source_size.y)
	var draw_size := source_size * scale
	var draw_rect := Rect2(rect.position + (rect.size - draw_size) / 2.0, draw_size)
	draw_texture_rect(texture, draw_rect, false, modulate)

func _draw_hud(size: Vector2) -> void:
	var top_margin := 12.0
	var top_height := 58.0
	var sector_width := 116.0
	var score_width := 126.0
	if size.x < 520.0:
		sector_width = 96.0
		score_width = 104.0
	var sector_rect := Rect2(top_margin, top_margin, sector_width, top_height)
	var score_rect := Rect2(size.x - score_width - top_margin, top_margin, score_width, top_height)
	var wave_rect := Rect2(sector_rect.end.x + 8.0, top_margin, maxf(118.0, score_rect.position.x - sector_rect.end.x - 16.0), top_height)
	_draw_sector_module(sector_rect)
	_draw_wave_module(wave_rect)
	_draw_score_module(score_rect)

	var bottom_width := minf(310.0, maxf(224.0, size.x - 164.0))
	var bottom_rect := Rect2(16, size.y - 82, bottom_width, 62)
	var hp_percent := clampf(float(player.hp) / float(PLAYER_HP), 0.0, 1.0)
	_draw_status_module(bottom_rect, hp_percent)

	_draw_weapon_strip(size)

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
		var velocity: Vector2 = bullet.velocity
		var direction: Vector2 = velocity.normalized()
		var trail_start: Vector2 = bullet.position - direction * BULLET_TRAIL_LENGTH
		draw_line(trail_start, bullet.position, Color(0.20, 0.82, 1.0, 0.34), 4.0)
		draw_line(trail_start, bullet.position, Color(0.85, 0.98, 1.0, 0.72), 1.4)
		draw_circle(bullet.position, bullet.radius + 6.0, Color(0.0, 0.78, 1.0, 0.14))
		var texture: Texture2D = vfx_textures.get("player_plasma_bolt")
		if texture:
			var rotation: float = velocity.angle() + PI / 2.0
			_draw_centered_texture(texture, bullet.position, BULLET_SPRITE_HEIGHT, rotation, Color(1, 1, 1, 0.98))
		else:
			draw_circle(bullet.position, bullet.radius + 2.0, Color(0.4, 0.91, 0.98, 0.22))
			draw_circle(bullet.position, bullet.radius, Color("#67e8f9"))
			draw_arc(bullet.position, bullet.radius + 1.0, 0.0, TAU, 12, Color("#ecfeff"), 1.0)

func _draw_enemy_projectiles() -> void:
	for projectile in enemy_projectiles:
		var velocity: Vector2 = projectile.velocity
		var direction: Vector2 = velocity.normalized()
		var trail_start: Vector2 = projectile.position - direction * 18.0
		draw_line(trail_start, projectile.position, Color(1.0, 0.16, 0.05, 0.28), 4.0)
		draw_line(trail_start, projectile.position, Color(1.0, 0.76, 0.42, 0.54), 1.2)
		draw_circle(projectile.position, projectile.radius + 5.0, Color(1.0, 0.14, 0.04, 0.14))
		var texture: Texture2D = vfx_textures.get("enemy_red_bullet")
		if texture:
			var rotation: float = velocity.angle() + PI / 2.0
			_draw_centered_texture(texture, projectile.position, ENEMY_PROJECTILE_PREVIEW_HEIGHT * 1.08, rotation, Color(1.0, 1.0, 1.0, 0.92))
		else:
			draw_circle(projectile.position, projectile.radius, UI_ORANGE)

func _draw_enemies() -> void:
	for enemy in enemies:
		var enemy_type_id: String = str(enemy.get("type_id", RED_SCOUT_DRONE_ID))
		var texture_set: Dictionary = enemy_textures.get(enemy_type_id, enemy_textures.get(RED_SCOUT_DRONE_ID, {}))
		var enemy_direction: String = str(enemy.get("direction", "down"))
		var enemy_state := "hit" if float(enemy.get("hit_flash", 0.0)) > 0.0 else str(enemy.get("visual_state", "thrust"))
		var texture_key := enemy_state + "-" + enemy_direction
		var texture: Texture2D = texture_set.get(texture_key, texture_set.get("idle-down"))
		if texture == null:
			continue
		var visual_size: float = enemy.radius * 3.9
		var flash: float = clampf(float(enemy.get("hit_flash", 0.0)) / ENEMY_DAMAGE_FLASH_SECONDS, 0.0, 1.0)
		var attack_charge: float = _get_enemy_attack_charge(enemy)
		var pulse: float = 0.5 + sin(background_time * 7.2 + float(enemy.id) * 0.61) * 0.5
		_draw_enemy_void_aura(enemy, flash, attack_charge, pulse)
		var rect := Rect2(
			enemy.position - Vector2.ONE * visual_size / 2.0,
			Vector2.ONE * visual_size
		)
		var base_alpha: float = 0.86 + pulse * 0.04 + flash * 0.10 + attack_charge * 0.06
		draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, clampf(base_alpha, 0.80, 1.0)))
		_draw_enemy_attack_telegraph(enemy, attack_charge)
		if attack_charge > 0.16:
			var attack_texture: Texture2D = texture_set.get("attack-" + enemy_direction)
			_draw_centered_texture(attack_texture, enemy.position, ENEMY_ATTACK_SPRITE_HEIGHT, 0.0, Color(1.0, 0.34, 0.18, attack_charge * 0.54))
		if flash > 0.0:
			var hit_texture: Texture2D = texture_set.get("hit-" + enemy_direction)
			_draw_centered_texture(hit_texture, enemy.position, ENEMY_HIT_SPRITE_HEIGHT, 0.0, Color(1.0, 0.86, 0.70, 0.56 * flash))
			draw_circle(enemy.position, enemy.radius * 1.35, Color(1, 0.70, 0.52, 0.18 * flash))
		_draw_enemy_core(enemy, flash, attack_charge, pulse)
		_draw_enemy_hp_feedback(enemy)

func _draw_enemy_void_aura(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var radius: float = enemy.radius
	draw_circle(enemy.position, radius * 2.18, Color(1.0, 0.03, 0.12, 0.07 + pulse * 0.04 + attack_charge * 0.10 + flash * 0.14))
	draw_circle(enemy.position, radius * 1.42, Color(0.24, 0.0, 0.025, 0.18 + pulse * 0.06))
	draw_arc(enemy.position, radius * 1.72, -PI * 0.34, PI * 1.16, 30, Color(1.0, 0.12, 0.26, 0.30 + pulse * 0.16 + flash * 0.26), 1.1 + flash * 1.2)
	draw_arc(enemy.position, radius * 2.04, PI * 0.12, PI * 0.72, 16, Color(1.0, 0.40, 0.10, 0.14 + attack_charge * 0.36), 1.0 + attack_charge * 1.4)

func _draw_enemy_core(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var core_radius: float = float(enemy.radius) * (0.22 + pulse * 0.08 + attack_charge * 0.16)
	var core_alpha: float = 0.58 + pulse * 0.22 + flash * 0.30 + attack_charge * 0.24
	draw_circle(enemy.position, float(enemy.radius) * 0.54, Color(1.0, 0.07, 0.04, 0.14 + pulse * 0.08 + attack_charge * 0.18))
	draw_circle(enemy.position, core_radius, Color(1.0, 0.24, 0.10, clampf(core_alpha, 0.0, 1.0)))
	draw_circle(enemy.position, maxf(2.0, core_radius * 0.38), Color(1.0, 0.86, 0.62, 0.72 + flash * 0.26))

func _draw_enemy_attack_telegraph(enemy: Dictionary, attack_charge: float) -> void:
	if attack_charge <= 0.18:
		return

	var direction: Vector2 = _get_enemy_forward_direction(enemy)
	var origin: Vector2 = enemy.position + direction * float(enemy.radius) * 0.72
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var beam_length: float = lerpf(28.0, 86.0, attack_charge)
	var spread := 0.18
	for lane in [-1, 0, 1]:
		var lane_offset: Vector2 = side * float(lane) * float(enemy.radius) * 0.20
		var lane_direction: Vector2 = (direction + side * float(lane) * spread).normalized()
		var start: Vector2 = origin + lane_offset
		var end: Vector2 = start + lane_direction * beam_length
		draw_line(start, end, Color(1.0, 0.07, 0.02, 0.18 + attack_charge * 0.36), 3.0)
		draw_line(start, end, Color(1.0, 0.72, 0.46, 0.26 + attack_charge * 0.52), 1.0)
	var projectile_texture: Texture2D = vfx_textures.get("enemy_red_bullet")
	_draw_centered_texture(projectile_texture, origin + direction * (beam_length + 8.0), ENEMY_PROJECTILE_PREVIEW_HEIGHT, direction.angle() + PI / 2.0, Color(1.0, 0.50, 0.22, attack_charge * 0.62))

func _draw_enemy_hp_feedback(enemy: Dictionary) -> void:
	var hp_percent: float = clampf(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)), 0.0, 1.0)
	if hp_percent >= 0.98 and float(enemy.get("hit_flash", 0.0)) <= 0.0:
		return

	var bar_width: float = float(enemy.radius) * 2.2
	var rect := Rect2(enemy.position + Vector2(-bar_width / 2.0, -float(enemy.radius) * 2.15), Vector2(bar_width, 4.0))
	draw_rect(rect.grow(1.0), Color(0.0, 0.0, 0.0, 0.42))
	draw_rect(rect, Color(0.28, 0.03, 0.08, 0.72))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * hp_percent, rect.size.y)), UI_ORANGE if hp_percent < 0.35 else UI_MAGENTA)

func _draw_player() -> void:
	var texture: Texture2D = _get_player_ship_texture()
	var trail_texture: Texture2D = vfx_textures.get("engine_trail")
	var trail_alpha := 0.58 if status == "running" else 0.34
	_draw_centered_texture(trail_texture, player.position + Vector2(0, PLAYER_SPRITE_HEIGHT * 0.34), ENGINE_TRAIL_HEIGHT, 0.0, Color(1, 1, 1, trail_alpha))
	if player_damage_flash > 0.0:
		var flash := player_damage_flash / PLAYER_DAMAGE_FLASH_SECONDS
		draw_circle(player.position, PLAYER_RADIUS * 2.3, Color(0.20, 0.88, 1.0, 0.11 * flash))
		draw_arc(player.position, PLAYER_RADIUS * 2.25, -PI * 0.10, PI * 1.36, 38, Color(0.55, 0.95, 1.0, 0.74 * flash), 2.0)
	_draw_centered_texture(texture, player.position, PLAYER_SPRITE_HEIGHT, 0.0, Color.WHITE)

func _draw_ready_overlay(size: Vector2) -> void:
	var rect := Rect2(22, size.y * 0.18, size.x - 44, 344)
	_draw_lcars_panel(rect, UI_CYAN, "SYSTEM READY")
	var icon_texture: Texture2D = ship_textures.get("icon")
	_draw_centered_texture(icon_texture, rect.position + Vector2(46, 78), 48.0, 0.0, Color.WHITE)
	draw_string(get_theme_default_font(), rect.position + Vector2(82, 60), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 110, 34, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(84, 84), "ボイド ドリフター", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 112, 14, UI_CYAN)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 124), "AUTO SHOOTER - SPACE ROGUELITE", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 12, UI_MAGENTA)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 152), "Survive the sector. Your ship fires automatically.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 15, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 181), "Click or drag to steer. Weapons auto-target the nearest enemy.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 13, UI_CYAN)
	_draw_lcars_meter(Rect2(rect.position.x + 30, rect.position.y + 212, rect.size.x - 60, 9), 0.82, UI_TEAL, "SECTOR SIGNAL", "82%")

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

func _draw_sector_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_TEAL, "", 0.24)
	_draw_lcars_block(Rect2(rect.position.x + 12, rect.position.y, rect.size.x * 0.54, 6), UI_TEAL, 0.68)
	draw_string(get_theme_default_font(), rect.position + Vector2(17, 20), "SECTOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_TEAL)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 49), SECTOR_LABEL, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 24, UI_TEXT)

func _draw_wave_module(rect: Rect2) -> void:
	var wave := mini(WAVE_TARGET, _get_run_level(elapsed))
	var wave_text := "WAVE %02d/%02d" % [wave, WAVE_TARGET]
	var accent := UI_CYAN
	var meter_color := UI_TEAL
	var meter_percent := float(wave) / float(WAVE_TARGET)
	if surge_active:
		accent = UI_ORANGE
		meter_color = UI_MAGENTA
		wave_text = "RED SURGE " + _format_roman(surge_level)
		meter_percent = _get_surge_progress()

	_draw_glass_panel(rect, accent, "", 0.24 if surge_active else 0.18)
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 19), wave_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.55, 10, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 74, 19), _format_time(elapsed), HORIZONTAL_ALIGNMENT_RIGHT, 60, 13, accent)
	_draw_lcars_meter(Rect2(rect.position.x + 16, rect.position.y + 36, rect.size.x - 32, 7), meter_percent, meter_color, "", "")
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 55), "ENEMIES " + str(enemies.size()), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 8, UI_MAGENTA if not surge_active else UI_ORANGE)

func _draw_score_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_MAGENTA, "", 0.24)
	_draw_lcars_block(Rect2(rect.position.x + 18, rect.position.y, rect.size.x * 0.58, 6), UI_MAGENTA, 0.64)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 19), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_MAGENTA)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 38), _format_compact_score(_get_score()), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 17, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 55), "KILLS " + str(kills), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 8, UI_TEAL)

func _draw_surge_message(size: Vector2) -> void:
	if status != "running" or surge_message_timer <= 0.0 or surge_message == "":
		return

	var alpha := clampf(surge_message_timer / 0.35, 0.0, 1.0)
	var rect_width := minf(360.0, size.x - 48.0)
	var rect := Rect2((size.x - rect_width) / 2.0, size.y * 0.18, rect_width, 74.0)
	var accent := UI_ORANGE if surge_message.begins_with("RED") else UI_TEAL
	_draw_glass_panel(rect, accent, "", 0.36)
	_draw_lcars_block(Rect2(rect.position.x + 22.0, rect.position.y, rect.size.x * 0.48, 6.0), accent, 0.82 * alpha)
	draw_string(get_theme_default_font(), rect.position + Vector2(24, 35), surge_message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 48, 22, _with_alpha(UI_TEXT, alpha))
	if surge_active:
		draw_string(get_theme_default_font(), rect.position + Vector2(24, 58), "INCOMING RED HOSTILES", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 48, 9, _with_alpha(UI_ORANGE, alpha))

func _draw_time_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.16)
	_draw_compact_chip(Rect2(rect.position.x + 10, rect.position.y + 9, 72, 30), "TIME", _format_time(elapsed), UI_TEAL)
	_draw_compact_chip(Rect2(rect.position.x + 88, rect.position.y + 9, 34, 30), "EN", str(enemies.size()), UI_MAGENTA)

func _draw_status_module(rect: Rect2, hp_percent: float) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.18)
	draw_string(get_theme_default_font(), rect.position + Vector2(22, 18), "HULL STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_CYAN)
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 26, rect.size.x - 44, 12), hp_percent, UI_TEAL if hp_percent > 0.3 else UI_ORANGE, "HP", str(player.hp) + " / " + str(PLAYER_HP))
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 48, rect.size.x - 44, 8), 1.0, UI_PLAYER_BLUE, "AUTO", "PLASMA")

func _draw_weapon_strip(size: Vector2) -> void:
	var slot_count := 5
	var strip_width := float(slot_count) * WEAPON_SLOT_SIZE + float(slot_count - 1) * WEAPON_SLOT_GAP
	var start := Vector2(maxf(16.0, size.x - strip_width - 18.0), size.y - WEAPON_SLOT_SIZE - 24.0)
	for index in range(slot_count):
		var rect := Rect2(start + Vector2(float(index) * (WEAPON_SLOT_SIZE + WEAPON_SLOT_GAP), 0), Vector2(WEAPON_SLOT_SIZE, WEAPON_SLOT_SIZE))
		if index == 0:
			_draw_weapon_slot(rect, "PLS", UI_TEAL, true)
		else:
			_draw_weapon_slot(rect, "LOCK", UI_TEXT_DIM, false)

func _draw_weapon_slot(rect: Rect2, label: String, accent: Color, active: bool) -> void:
	_draw_glass_panel(rect, accent, "", 0.28 if active else 0.10)
	if active:
		var texture: Texture2D = vfx_textures.get("player_plasma_bolt")
		_draw_centered_texture(texture, rect.position + rect.size / 2.0 + Vector2(0, -2), 24.0, -0.35, Color.WHITE)
		draw_string(get_theme_default_font(), rect.position + Vector2(7, rect.size.y - 5), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14, 7, UI_TEAL)
	else:
		var center := rect.position + rect.size / 2.0
		draw_line(center + Vector2(-8, 0), center + Vector2(8, 0), _with_alpha(accent, 0.38), 1.0)
		draw_line(center + Vector2(0, -8), center + Vector2(0, 8), _with_alpha(accent, 0.38), 1.0)
		draw_string(get_theme_default_font(), rect.position + Vector2(5, rect.size.y - 5), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, 7, _with_alpha(accent, 0.72))

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

func _load_enemy_texture_set(enemy_type_id: String) -> Dictionary:
	var frames := {}
	for state in ENEMY_FRAME_STATES:
		for direction in ENEMY_FRAME_DIRECTIONS:
			var frame_key: String = str(state) + "-" + str(direction)
			frames[frame_key] = _load_png_texture("res://assets/enemies/" + enemy_type_id + "/" + frame_key + ".png")
	return frames

func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture

	var image := Image.new()
	if image.load(path) != OK:
		return null

	return ImageTexture.create_from_image(image)

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
		var death_button_gap := 10.0
		var button_width := minf(158.0, (death_rect.size.x - 72.0 - death_button_gap) / 2.0)
		action_button.size = Vector2(button_width, 46.0)
		enemies_button.size = Vector2(button_width, 46.0)
		var start_x := death_rect.position.x + (death_rect.size.x - button_width * 2.0 - death_button_gap) / 2.0
		action_button.position = Vector2(start_x, death_rect.position.y + 226.0)
		enemies_button.position = Vector2(start_x + button_width + death_button_gap, death_rect.position.y + 226.0)
	else:
		var ready_button_y := size.y * 0.18 + 244.0
		if size.x >= 520.0:
			var ready_button_gap := 12.0
			action_button.size = Vector2(170, 50)
			enemies_button.size = Vector2(154, 50)
			var row_width := action_button.size.x + enemies_button.size.x + ready_button_gap
			action_button.position = Vector2((size.x - row_width) / 2.0, ready_button_y)
			enemies_button.position = Vector2(action_button.position.x + action_button.size.x + ready_button_gap, ready_button_y)
		else:
			action_button.size = Vector2(170, 50)
			action_button.position = Vector2((size.x - action_button.size.x) / 2.0, ready_button_y)
			enemies_button.size = Vector2(154, 38)
			enemies_button.position = Vector2((size.x - enemies_button.size.x) / 2.0, action_button.position.y + 58.0)
	header_restart_button.size = Vector2(78, 28)
	header_restart_button.position = Vector2(size.x - header_restart_button.size.x - 16.0, 70.0)

func _update_buttons() -> void:
	_layout_buttons()
	header_restart_button.visible = status == "running"
	action_button.visible = status == "ready" or status == "dead"
	enemies_button.visible = status == "ready" or status == "dead"
	action_button.text = "Start Run" if status == "ready" else "Restart Run"
	enemies_button.text = "Enemy Codex"
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

func _choose_enemy_type_id(run_level: int, seed: int) -> String:
	var spawnable: Array[Dictionary] = []
	var total_weight := 0
	for enemy_type_id in ENEMY_DEFINITIONS.keys():
		var definition: Dictionary = ENEMY_DEFINITIONS[enemy_type_id]
		var spawn: Dictionary = definition.spawn
		var weight := int(spawn.weight)
		if str(definition.status) != "active" or int(spawn.min_run_level) > run_level or weight <= 0:
			continue
		spawnable.append(definition)
		total_weight += weight

	if spawnable.is_empty() or total_weight <= 0:
		return RED_SCOUT_DRONE_ID

	var roll := absi(seed) % total_weight
	for definition in spawnable:
		var weight := int(definition.spawn.weight)
		if roll < weight:
			return str(definition.id)
		roll -= weight

	return str(spawnable[0].id)

func _get_enemy_movement_frame(spawn_edge: String) -> String:
	return ENEMY_MOVEMENT_FRAMES_BY_EDGE.get(spawn_edge, "down")

func _get_direction_from_velocity(velocity: Vector2) -> String:
	if absf(velocity.x) > absf(velocity.y):
		return "left" if velocity.x < 0.0 else "right"

	return "up" if velocity.y < 0.0 else "down"

func _get_active_sector_index() -> int:
	if BACKGROUND_SECTORS.is_empty():
		return 0
	var sector_time: float = elapsed if status == "running" else background_time
	return int(floor(sector_time / 52.0)) % BACKGROUND_SECTORS.size()

func _get_enemy_forward_direction(enemy: Dictionary) -> Vector2:
	if not player.is_empty():
		var to_player: Vector2 = player.position - enemy.position
		if to_player.length_squared() > 0.01:
			return to_player.normalized()

	var spawn_edge: String = str(enemy.get("spawn_edge", "top"))
	match spawn_edge:
		"top":
			return Vector2.DOWN
		"bottom":
			return Vector2.UP
		"left":
			return Vector2.RIGHT
		"right":
			return Vector2.LEFT
	return Vector2.DOWN

func _get_enemy_attack_charge(enemy: Dictionary) -> float:
	if status != "running" or player.is_empty():
		return 0.0

	var distance: float = enemy.position.distance_to(player.position)
	var proximity: float = clampf(1.0 - distance / ENEMY_ATTACK_RANGE, 0.0, 1.0)
	if proximity <= 0.0:
		return 0.0

	var cycle: float = 0.5 + sin(background_time * 5.6 + float(enemy.id) * 0.83) * 0.5
	var charge: float = smoothstep(0.48, 1.0, cycle)
	return proximity * charge

func _get_surge_progress() -> float:
	if not surge_active:
		return 0.0

	var total := maxf(1.0, float(_get_current_surge_enemy_count()))
	var remaining := float(surge_remaining_spawns + surge_alive_ids.size())
	return clampf(1.0 - remaining / total, 0.0, 1.0)

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

func _format_compact_score(value: int) -> String:
	if value >= 100000:
		return "%.1fK" % (float(value) / 1000.0)
	return "%05d" % value

func _format_roman(value: int) -> String:
	var numerals := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	if value >= 0 and value < numerals.size():
		return numerals[value]
	return str(value)
