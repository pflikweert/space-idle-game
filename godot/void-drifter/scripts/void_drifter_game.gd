extends Control

const ProfileStore := preload("res://scripts/profile_store.gd")

# Gameplay tuning
const PLAYER_HP := 140
const ENEMY_SPAWN_INTERVAL := 1500.0
const MIN_ENEMY_SPAWN_INTERVAL := 620.0
const FIRST_ENEMY_SPAWN_DELAY := 1350.0
const PLAYER_FIRE_INTERVAL := 260.0
const PLAYER_BASE_DAMAGE := 8
const BULLET_SPEED := 540.0
const PLAYER_MOVE_SPEED := 470.0
const PLAYER_BOUNDS_PADDING := 10.0
const PLAYER_RADIUS := 18.0
# Movement sprites use fixed transparent canvases; keep draw height separate from collision radius to avoid pivot jitter.
const PLAYER_SHIP_VISUAL_HEIGHT := 88.0
const PLAYER_SPRITE_CANVAS_HEIGHT := 204.0
const PLAYER_DAMAGED_HP_THRESHOLD := 0.3
const PLAYER_BANKING_THRESHOLD := 1.2
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
const WAVE_SECONDS := 30.0
const LEVELUP_CHOICE_COUNT := 3
const PERMANENT_UPGRADE_MAX_LEVEL := 5

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
const ENEMY_ATTACK_RANGE := 280.0
const ENEMY_ATTACK_WARMUP_SECONDS := 0.42
const ENEMY_ATTACK_VISUAL_SECONDS := 0.20
const ENEMY_DEATH_SPRITE_HEIGHT := 102.0
const ENEMY_PROJECTILE_PREVIEW_HEIGHT := 22.0
const ENEMY_DIRECTION_LOCK_SECONDS := 0.16
const ENEMY_DIRECTION_DOMINANCE := 1.18
const HUD_TOP_RESERVED := 86.0
const HUD_BOTTOM_RESERVED := 116.0

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

const VOID_DRONE_ID := "void_drone"
const RED_SCOUT_ID := "red_scout"
const VOID_TANK_ID := "void_tank"
const ENEMY_FRAME_STATES := ["idle", "thrust", "attack", "hit"]
const ENEMY_FRAME_DIRECTIONS := ["down", "up", "left", "right"]
const ENEMY_DEFINITIONS := {
	"void_drone": {
		"id": "void_drone",
		"asset_key": "red_scout_drone",
		"name": "Void Drone",
		"role": "Basic chase enemy",
		"description": "Standard void-skimmer that enters from screen edges and pushes the player out of position.",
		"status": "active",
		"unlock_wave": 1,
		"visual_canvas_height": 124.0,
		"death_vfx_key": "enemy_death_small",
		"death_vfx_height": 82.0,
		"base_stats": {
			"hp": 16,
			"speed": 52.0,
			"contact_damage": 10,
			"xp_reward": 4,
			"coin_reward": 2,
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
	"red_scout": {
		"id": "red_scout",
		"asset_key": "red_fighter",
		"name": "Red Scout",
		"role": "Fast low-HP enemy",
		"description": "Fast red scout craft that arrives early and punishes slow movement.",
		"status": "active",
		"unlock_wave": 2,
		"visual_canvas_height": 172.0,
		"death_vfx_key": "enemy_death_medium",
		"death_vfx_height": 104.0,
		"base_stats": {
			"hp": 22,
			"speed": 72.0,
			"contact_damage": 12,
			"xp_reward": 7,
			"coin_reward": 3,
			"score_reward": 24,
			"radius": 22.0,
		},
		"scaling": {
			"hp_per_level": 4,
			"speed_per_level": 1.2,
			"damage_per_level": 1.4,
		},
		"spawn": {
			"weight": 35,
			"min_run_level": 2,
		},
		"abilities": ["chase_player", "contact_damage", "flank_player_later"],
	},
	"void_tank": {
		"id": "void_tank",
		"asset_key": "red_cruiser",
		"name": "Void Tank",
		"role": "Slow high-HP enemy",
		"description": "Armored void hull that soaks fire and compresses safe space later in a run.",
		"status": "active",
		"unlock_wave": 4,
		"visual_canvas_height": 204.0,
		"death_vfx_key": "enemy_death_large",
		"death_vfx_height": 132.0,
		"base_stats": {
			"hp": 90,
			"speed": 25.0,
			"contact_damage": 24,
			"xp_reward": 18,
			"coin_reward": 8,
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
const RUN_UPGRADE_POOL := [
	{ "id": "weapon_damage", "name": "Weapon Damage +20%", "description": "Plasma hits harder for this run." },
	{ "id": "fire_rate", "name": "Fire Rate +15%", "description": "Auto-fire cycles faster for this run." },
	{ "id": "bullet_speed", "name": "Bullet Speed +20%", "description": "Shots reach targets sooner." },
	{ "id": "max_hp", "name": "Max HP +25", "description": "Increase max hull and repair 25 HP." },
	{ "id": "extra_projectile", "name": "Extra Projectile", "description": "Add one plasma shot to each volley." },
	{ "id": "damage_reduction", "name": "Damage Reduction +15%", "description": "Reduce incoming damage for this run." },
]
const PERMANENT_UPGRADES := [
	{ "id": "damage", "name": "Damage", "description": "+10% weapon damage per level." },
	{ "id": "fire_rate", "name": "Fire Rate", "description": "-5% fire interval per level." },
	{ "id": "max_hp", "name": "Max HP", "description": "+20 max hull per level." },
	{ "id": "xp_gain", "name": "XP Gain", "description": "+10% XP per level." },
	{ "id": "coin_bonus", "name": "Coin Bonus", "description": "+10% coins per level." },
]

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
var upgrade_button: Button
var main_menu_button: Button
var choice_buttons: Array[Button] = []
var permanent_upgrade_buttons: Array[Button] = []

var ship_textures := {}
var enemy_textures := {}
var vfx_textures := {}
var sector_textures: Array[Texture2D] = []
var background_textures: Array[Texture2D] = []
var midfield_textures: Array[Texture2D] = []
var foreground_textures: Array[Texture2D] = []
var status := "menu"
var runState := {
	"status": "menu",
	"wave": 1,
	"score": 0,
	"kills": 0,
	"xp": 0,
	"level": 1,
	"coinsEarned": 0,
	"elapsedSeconds": 0.0,
}
var run_upgrades := {}
var pending_level_choices: Array[Dictionary] = []
var menu_view := "main"
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
var profile_store := ProfileStore.new()
var profile := {}
var metaProgress := {}
var run_enemy_kills := {}
var run_discovered_enemies := []
var last_run_records := {}
var run_recorded := false
var weapon_level := 1
var weapon_charge := 0.0
var weapon_timer := 0.0
var highest_weapon_level_this_run := 1
var last_elite_wave := 0

func _ready() -> void:
	set_process(true)
	profile = profile_store.load_profile()
	metaProgress = profile
	_create_runtime_buttons()
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
		VOID_DRONE_ID: _load_enemy_texture_set("red_scout_drone"),
		RED_SCOUT_ID: _load_enemy_texture_set("red_fighter"),
		VOID_TANK_ID: _load_enemy_texture_set("red_cruiser"),
	}
	for sector in BACKGROUND_SECTORS:
		sector_textures.append(load(sector.path))
	for layer in PARALLAX_LAYERS:
		background_textures.append(load(layer.path))
	for layer in MIDFIELD_LAYERS:
		midfield_textures.append(load(layer.path))
	for layer in FOREGROUND_LAYERS:
		foreground_textures.append(load(layer.path))
	reset_world("menu")

func _create_runtime_buttons() -> void:
	upgrade_button = Button.new()
	upgrade_button.text = "Upgrade Ship"
	add_child(upgrade_button)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

	main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	add_child(main_menu_button)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	for index in range(LEVELUP_CHOICE_COUNT):
		var button := Button.new()
		button.text = "Upgrade"
		add_child(button)
		button.pressed.connect(_on_level_choice_pressed.bind(index))
		choice_buttons.append(button)

	for index in range(PERMANENT_UPGRADES.size()):
		var button := Button.new()
		button.text = "Buy"
		add_child(button)
		button.pressed.connect(_on_permanent_upgrade_pressed.bind(index))
		permanent_upgrade_buttons.append(button)

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
	var playfield := _get_playfield_rect(size)
	var start := Vector2(size.x / 2.0, playfield.position.y + playfield.size.y * 0.70)
	status = next_status
	runState = {
		"status": next_status,
		"wave": 1,
		"score": 0,
		"kills": 0,
		"xp": 0,
		"level": 1,
		"coinsEarned": 0,
		"elapsedSeconds": 0.0,
	}
	run_upgrades = _get_default_run_upgrades()
	pending_level_choices = []
	run_enemy_kills = {}
	run_discovered_enemies = []
	last_run_records = {}
	last_elite_wave = 0
	menu_view = "main"
	var player_max_hp := _get_player_max_hp()
	player = {
		"position": start,
		"radius": PLAYER_RADIUS,
		"hp": player_max_hp,
		"max_hp": player_max_hp,
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
	run_recorded = false
	weapon_level = 1
	weapon_charge = 0.0
	weapon_timer = 0.0
	highest_weapon_level_this_run = 1
	_sync_legacy_run_fields()
	_update_buttons()
	queue_redraw()

func start_run() -> void:
	reset_world("running")

func _end_run() -> void:
	if status == "dead":
		return

	if not run_recorded:
		run_recorded = true
		profile = profile_store.record_run(profile, {
			"score": _get_score(),
			"kills": int(runState.kills),
			"wave": int(runState.wave),
			"time_seconds": int(floor(float(runState.elapsedSeconds))),
			"coins_earned": int(runState.coinsEarned),
			"enemy_kills": run_enemy_kills,
			"discovered_enemies": run_discovered_enemies,
		})
		metaProgress = profile
		last_run_records = profile.get("lastRun", {}).get("newRecords", {})

	status = "dead"
	runState.status = "dead"
	bullets = []
	enemy_projectiles = []
	enemies = []

func _update_world(delta: float) -> void:
	var delta_ms := delta * 1000.0
	runState.elapsedSeconds = float(runState.elapsedSeconds) + delta
	_update_wave_manager()
	_sync_legacy_run_fields()
	_update_player(delta)
	_update_enemy_spawning(delta_ms)
	_update_surge_waves(delta_ms, delta)
	_update_weapons(delta_ms)
	_update_enemy_movement(delta)
	_update_enemy_weapons(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_resolve_collisions()
	_sync_legacy_run_fields()

func _update_wave_manager() -> void:
	var previous_wave := int(runState.wave)
	var next_wave := _get_run_level(float(runState.elapsedSeconds))
	runState.wave = next_wave
	if next_wave != previous_wave:
		surge_message = "WAVE " + str(next_wave)
		surge_message_timer = 1.1
	if next_wave >= 5 and next_wave % 5 == 0 and last_elite_wave != next_wave:
		_start_elite_wave(next_wave)

func _start_elite_wave(wave: int) -> void:
	if surge_active:
		return
	last_elite_wave = wave
	surge_level = int(floor(float(wave) / 5.0))
	surge_active = true
	surge_remaining_spawns = _get_current_surge_enemy_count()
	surge_alive_ids = {}
	surge_spawn_timer = 0.0
	surge_spawn_index = 0
	surge_current_pattern = SURGE_PATTERNS[(surge_level - 1) % SURGE_PATTERNS.size()]
	surge_bonus_score = SURGE_CLEAR_BONUS_BASE + (surge_level - 1) * SURGE_CLEAR_BONUS_STEP
	surge_message = "ELITE WAVE " + str(wave)
	surge_message_timer = 1.65

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
	var run_level := int(runState.wave)
	var enemy_type_id := _choose_enemy_type_id(run_level, next_id * 97)
	_spawn_enemy_at(_get_regular_spawn_position(enemy_type_id), 0, enemy_type_id)

func _spawn_enemy_at(spawn_data: Dictionary, surge_id := 0, enemy_type_id := "") -> void:
	var size := get_viewport_rect().size
	var run_level := int(runState.wave)
	var resolved_enemy_type_id := enemy_type_id
	if resolved_enemy_type_id == "":
		resolved_enemy_type_id = _choose_enemy_type_id(run_level, next_id * 97)
	var stats := _get_enemy_stats(resolved_enemy_type_id, run_level)
	var spawn_edge: String = str(spawn_data.get("edge", "top"))
	var position: Vector2 = spawn_data.get("position", Vector2(size.x / 2.0, -_get_enemy_spawn_inset(resolved_enemy_type_id, stats)))
	var enemy_id := next_id
	next_id += 1

	enemies.append({
		"id": enemy_id,
		"type_id": resolved_enemy_type_id,
		"position": position,
		"radius": stats.radius,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"speed": stats.speed * _get_enemy_speed_multiplier(float(runState.elapsedSeconds)),
		"contact_damage": stats.contact_damage,
		"xp_reward": stats.xp_reward,
		"score_reward": stats.score_reward,
		"spawn_edge": spawn_edge,
		"direction": _get_enemy_movement_frame(spawn_edge),
		"visual_state": "idle",
		"hit_flash": 0.0,
		"hit_visual_timer": 0.0,
		"attack_visual_timer": 0.0,
		"attack_warmup_timer": 0.0,
		"direction_lock_timer": 0.0,
		"velocity": Vector2.ZERO,
		"fire_cooldown": 1.15 + float(next_id % 4) * 0.34,
		"surge_id": surge_id,
	})
	_mark_enemy_discovered(resolved_enemy_type_id)
	if surge_id > 0:
		surge_alive_ids[enemy_id] = true
		_add_surge_breach_effect(position, spawn_edge)

func _get_regular_spawn_position(enemy_type_id: String) -> Dictionary:
	var size := get_viewport_rect().size
	var run_level := int(runState.wave)
	var stats := _get_enemy_stats(enemy_type_id, run_level)
	var spawn_edges := ["top", "right", "bottom", "left"]
	var spawn_edge: String = spawn_edges[next_id % spawn_edges.size()]
	var inset: float = _get_enemy_spawn_inset(enemy_type_id, stats)
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
	surge_message = "ELITE WAVE " + str(int(runState.wave))
	surge_message_timer = 1.65

func _get_current_surge_enemy_count() -> int:
	return mini(SURGE_MAX_COUNT, SURGE_BASE_COUNT + surge_level)

func _get_surge_spawn_position(index: int, total: int, pattern: String) -> Dictionary:
	var size := get_viewport_rect().size
	var stats := _get_enemy_stats(VOID_DRONE_ID, int(runState.wave))
	var inset: float = _get_enemy_spawn_inset(VOID_DRONE_ID, stats) + 10.0
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

	return _get_regular_spawn_position(VOID_DRONE_ID)

func _mark_surge_enemy_removed(enemy: Dictionary) -> void:
	if int(enemy.get("surge_id", 0)) <= 0:
		return
	surge_alive_ids.erase(enemy.id)

func _check_surge_clear() -> void:
	if not surge_active or player.hp <= 0 or surge_remaining_spawns > 0 or not surge_alive_ids.is_empty():
		return

	runState.score = int(runState.score) + surge_bonus_score
	runState.coinsEarned = int(runState.coinsEarned) + maxi(4, int(floor(float(surge_bonus_score) / 60.0)))
	_sync_legacy_run_fields()
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
		fire_timer = _get_weapon_fire_interval()

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
	var shot_count := _get_weapon_shot_count()
	var spread := _get_weapon_spread()
	for shot_index in range(shot_count):
		var angle_offset := 0.0
		if shot_count > 1:
			angle_offset = (float(shot_index) - float(shot_count - 1) / 2.0) * spread
		var shot_direction := direction.rotated(angle_offset).normalized()
		var side := Vector2(-direction.y, direction.x)
		var muzzle_offset := side * (float(shot_index) - float(shot_count - 1) / 2.0) * 9.0
		bullets.append({
			"id": next_id,
			"position": Vector2(player_position.x, player_position.y - player.radius) + muzzle_offset,
			"radius": 4.0 + float(int(runState.level) - 1) * 0.18,
			"velocity": shot_direction * _get_bullet_speed(),
			"damage": _get_weapon_damage(),
			"life": 1.65,
			"weapon_level": int(runState.level),
		})
		next_id += 1

func _add_weapon_charge(amount: float) -> void:
	runState.xp = int(runState.xp) + int(round(amount))
	_maybe_trigger_level_up()

func _activate_weapon_boost() -> void:
	# Kept as a compatibility shim for older prototype calls; level-ups now use explicit choices.
	pending_level_choices = _build_level_choices()
	status = "paused"
	runState.status = "paused"
	_add_sprite_effect(player.position, "levelup_burst", 118.0, SPRITE_PARTICLE_LIFETIME * 1.2, 0.0)

func _get_weapon_fire_interval() -> float:
	var permanent_multiplier := 1.0 - float(_get_permanent_upgrade_level("fire_rate")) * 0.05
	return maxf(90.0, PLAYER_FIRE_INTERVAL * float(run_upgrades.fire_interval_multiplier) * permanent_multiplier)

func _get_weapon_damage() -> int:
	var multiplier := float(run_upgrades.damage_multiplier) * (1.0 + float(_get_permanent_upgrade_level("damage")) * 0.10)
	return maxi(1, int(round(float(PLAYER_BASE_DAMAGE) * multiplier)))

func _get_weapon_shot_count() -> int:
	return 1 + int(run_upgrades.extra_projectiles)

func _get_weapon_spread() -> float:
	var shot_count := _get_weapon_shot_count()
	if shot_count >= 3:
		return 0.22
	if shot_count >= 2:
		return 0.15
	return 0.0

func _get_weapon_charge_percent() -> float:
	return clampf(float(runState.xp) / float(_get_xp_threshold(int(runState.level))), 0.0, 1.0)

func _get_bullet_speed() -> float:
	return BULLET_SPEED * float(run_upgrades.bullet_speed_multiplier)

func _update_enemy_movement(delta: float) -> void:
	var player_position: Vector2 = player.position
	for enemy in enemies:
		var direction: Vector2 = (player_position - enemy.position).normalized()
		var velocity: Vector2 = direction * enemy.speed
		enemy.velocity = velocity
		enemy.position += velocity * delta
		_update_enemy_visual_direction(enemy, velocity, delta)
		_update_enemy_visual_state(enemy, velocity)

func _update_enemy_weapons(delta: float) -> void:
	if player.is_empty():
		return

	for enemy in enemies:
		enemy.fire_cooldown = maxf(0.0, float(enemy.get("fire_cooldown", 0.0)) - delta)
		if enemy.fire_cooldown > 0.0:
			enemy.attack_warmup_timer = 0.0
			continue

		var distance: float = enemy.position.distance_to(player.position)
		if distance > ENEMY_ATTACK_RANGE:
			enemy.attack_warmup_timer = 0.0
			continue

		if float(enemy.get("attack_warmup_timer", 0.0)) <= 0.0:
			enemy.attack_warmup_timer = ENEMY_ATTACK_WARMUP_SECONDS
			enemy.attack_visual_timer = maxf(float(enemy.get("attack_visual_timer", 0.0)), ENEMY_ATTACK_WARMUP_SECONDS)
			continue

		enemy.attack_warmup_timer = maxf(0.0, float(enemy.attack_warmup_timer) - delta)
		enemy.attack_visual_timer = maxf(float(enemy.get("attack_visual_timer", 0.0)), enemy.attack_warmup_timer)
		if enemy.attack_warmup_timer > 0.0:
			continue

		_fire_enemy_projectile(enemy)
		enemy.attack_visual_timer = ENEMY_ATTACK_VISUAL_SECONDS
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

func _update_enemy_visual_direction(enemy: Dictionary, velocity: Vector2, delta: float) -> void:
	var current_direction: String = str(enemy.get("direction", "down"))
	enemy.direction_lock_timer = maxf(0.0, float(enemy.get("direction_lock_timer", 0.0)) - delta)
	var next_direction := _get_stable_direction_from_velocity(velocity, current_direction)
	if next_direction == current_direction:
		return
	if float(enemy.get("direction_lock_timer", 0.0)) > 0.0:
		return

	enemy.direction = next_direction
	enemy.direction_lock_timer = ENEMY_DIRECTION_LOCK_SECONDS

func _update_enemy_visual_state(enemy: Dictionary, velocity: Vector2) -> void:
	var next_state := "idle"
	if float(enemy.get("hit_visual_timer", 0.0)) > 0.0 or float(enemy.get("hit_flash", 0.0)) > 0.0:
		next_state = "hit"
	elif float(enemy.get("attack_warmup_timer", 0.0)) > 0.0 or float(enemy.get("attack_visual_timer", 0.0)) > 0.0:
		next_state = "attack"
	elif velocity.length_squared() > 9.0:
		next_state = "thrust"

	enemy.visual_state = next_state

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
		enemy.hit_visual_timer = maxf(0.0, float(enemy.get("hit_visual_timer", 0.0)) - delta)
		enemy.attack_visual_timer = maxf(0.0, float(enemy.get("attack_visual_timer", 0.0)) - delta)

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
				enemy.hp -= int(bullet.get("damage", 1))
				enemy.hit_flash = ENEMY_DAMAGE_FLASH_SECONDS
				enemy.hit_visual_timer = ENEMY_DAMAGE_FLASH_SECONDS
				removed_bullet_ids[bullet.id] = true
				_add_hit_spark(bullet.position)
				if enemy.hp <= 0:
					removed_enemy_ids[enemy.id] = true
					_mark_surge_enemy_removed(enemy)
					_grant_enemy_rewards(enemy)
					_add_enemy_death_explosion(enemy, Color("#f97316"))

	for enemy in enemies:
		if removed_enemy_ids.has(enemy.id):
			continue

		if _circles_overlap(player.position, player.radius, enemy.position, enemy.radius):
			player.hp = maxi(0, int(player.hp) - _get_incoming_damage(enemy.contact_damage))
			player_damage_flash = PLAYER_DAMAGE_FLASH_SECONDS
			removed_enemy_ids[enemy.id] = true
			_mark_surge_enemy_removed(enemy)
			_add_sprite_effect(player.position, "shield_impact", SHIELD_IMPACT_SPRITE_HEIGHT, SPRITE_PARTICLE_LIFETIME * 1.05, 0.0)
			_add_explosion(enemy.position, Color("#67e8f9"), false)

	for projectile in enemy_projectiles:
		if removed_enemy_projectile_ids.has(projectile.id):
			continue

		if _circles_overlap(player.position, player.radius, projectile.position, projectile.radius):
			player.hp = maxi(0, int(player.hp) - _get_incoming_damage(int(projectile.damage)))
			player_damage_flash = PLAYER_DAMAGE_FLASH_SECONDS
			removed_enemy_projectile_ids[projectile.id] = true
			_add_sprite_effect(player.position, "shield_impact", SHIELD_IMPACT_SPRITE_HEIGHT * 0.82, SPRITE_PARTICLE_LIFETIME * 0.8, 0.0)
			_add_hit_spark(projectile.position)

	enemies = enemies.filter(func(enemy): return not removed_enemy_ids.has(enemy.id))
	_remove_expired_projectiles(removed_bullet_ids)
	_remove_expired_enemy_projectiles(removed_enemy_projectile_ids)
	_check_surge_clear()

	if player.hp <= 0:
		_end_run()

func _grant_enemy_rewards(enemy: Dictionary) -> void:
	var enemy_type_id := str(enemy.get("type_id", VOID_DRONE_ID))
	var xp_reward := int(round(float(enemy.get("xp_reward", 0)) * _get_xp_multiplier()))
	var coin_reward := int(round(float(enemy.get("coin_reward", 0)) * _get_coin_multiplier()))
	var score_reward := int(enemy.get("score_reward", 0))
	runState.kills = int(runState.kills) + 1
	runState.score = int(runState.score) + score_reward
	runState.xp = int(runState.xp) + xp_reward
	runState.coinsEarned = int(runState.coinsEarned) + coin_reward
	run_enemy_kills[enemy_type_id] = int(run_enemy_kills.get(enemy_type_id, 0)) + 1
	_sync_legacy_run_fields()
	_maybe_trigger_level_up()

func _maybe_trigger_level_up() -> void:
	if status != "running":
		return
	var threshold := _get_xp_threshold(int(runState.level))
	if int(runState.xp) < threshold:
		return
	runState.xp = int(runState.xp) - threshold
	runState.level = int(runState.level) + 1
	status = "paused"
	runState.status = "paused"
	pending_level_choices = _build_level_choices()
	surge_message = "LEVEL " + str(runState.level)
	surge_message_timer = 0.0
	_add_sprite_effect(player.position, "levelup_burst", 128.0, SPRITE_PARTICLE_LIFETIME * 1.3, 0.0)
	_update_buttons()

func _build_level_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var start := (int(runState.level) * 2 + int(runState.kills)) % RUN_UPGRADE_POOL.size()
	var offset := 0
	while choices.size() < LEVELUP_CHOICE_COUNT and offset < RUN_UPGRADE_POOL.size() * 2:
		var candidate: Dictionary = RUN_UPGRADE_POOL[(start + offset * 2 + offset / 2) % RUN_UPGRADE_POOL.size()]
		var already_added := false
		for choice in choices:
			if str(choice.id) == str(candidate.id):
				already_added = true
				break
		if not already_added:
			choices.append(candidate)
		offset += 1
	return choices

func _apply_run_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"weapon_damage":
			run_upgrades.damage_multiplier = float(run_upgrades.damage_multiplier) * 1.20
		"fire_rate":
			run_upgrades.fire_interval_multiplier = float(run_upgrades.fire_interval_multiplier) * 0.85
		"bullet_speed":
			run_upgrades.bullet_speed_multiplier = float(run_upgrades.bullet_speed_multiplier) * 1.20
		"max_hp":
			run_upgrades.max_hp_bonus = int(run_upgrades.max_hp_bonus) + 25
			player.max_hp = int(player.max_hp) + 25
			player.hp = mini(int(player.max_hp), int(player.hp) + 25)
		"extra_projectile":
			run_upgrades.extra_projectiles = int(run_upgrades.extra_projectiles) + 1
		"damage_reduction":
			run_upgrades.damage_reduction = minf(0.60, float(run_upgrades.damage_reduction) + 0.15)

func _get_xp_threshold(level: int) -> int:
	return 12 + maxi(0, level - 1) * 8

func _get_default_run_upgrades() -> Dictionary:
	return {
		"damage_multiplier": 1.0,
		"fire_interval_multiplier": 1.0,
		"bullet_speed_multiplier": 1.0,
		"extra_projectiles": 0,
		"damage_reduction": 0.0,
		"max_hp_bonus": 0,
	}

func _sync_legacy_run_fields() -> void:
	kills = int(runState.kills)
	score = int(runState.score)
	elapsed = float(runState.elapsedSeconds)
	weapon_level = int(runState.level)

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
	var definition := _get_enemy_definition(str(enemy.get("type_id", VOID_DRONE_ID)))
	var vfx_key: String = str(definition.get("death_vfx_key", "enemy_death_small"))
	var vfx_height: float = float(definition.get("death_vfx_height", ENEMY_DEATH_SPRITE_HEIGHT))
	var origin: Vector2 = enemy.position
	_add_sprite_effect(
		origin,
		vfx_key,
		vfx_height * 0.78,
		SPRITE_PARTICLE_LIFETIME * 1.02,
		float(next_id % 12) * 0.12
	)

	var debris_count := 5
	if float(enemy.radius) >= 36.0:
		debris_count = 8
	elif float(enemy.radius) >= 24.0:
		debris_count = 6

	for index in range(debris_count):
		var angle := TAU * float(index) / float(debris_count) + float(next_id) * 0.17
		var speed := 48.0 + float(index) * 7.0
		particles.append({
			"id": next_id,
			"position": origin,
			"radius": 1.4 + float(index % 2) * 0.8,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": PARTICLE_LIFETIME * 0.72,
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
	_add_sprite_effect(origin, "hit_spark", HIT_SPARK_SPRITE_HEIGHT * 0.76, SPRITE_PARTICLE_LIFETIME * 0.48, float(next_id % 10) * 0.2)

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
	if status == "menu":
		if menu_view == "upgrades":
			_draw_permanent_upgrade_overlay(size)
		elif menu_view == "codex":
			_draw_codex_overlay(size)
		else:
			_draw_ready_overlay(size)
	elif status == "paused":
		_draw_levelup_overlay(size)
	elif status == "dead":
		if menu_view == "upgrades":
			_draw_permanent_upgrade_overlay(size)
		elif menu_view == "codex":
			_draw_codex_overlay(size)
		else:
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

	var compact_bottom := size.x < 640.0 or size.y < 680.0
	var bottom_width := minf(310.0, maxf(224.0, size.x - 164.0))
	if compact_bottom:
		bottom_width = maxf(224.0, size.x - 32.0)
	var bottom_rect := Rect2(16, size.y - 70.0, bottom_width, 56.0 if compact_bottom else 62.0)
	var hp_percent := clampf(float(player.hp) / maxf(1.0, float(player.get("max_hp", PLAYER_HP))), 0.0, 1.0)
	_draw_status_module(bottom_rect, hp_percent)

	_draw_weapon_strip(size, compact_bottom)

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
			var sprite_height := BULLET_SPRITE_HEIGHT + float(int(bullet.get("weapon_level", 1)) - 1) * 3.5
			_draw_centered_texture(texture, bullet.position, sprite_height, rotation, Color(1, 1, 1, 0.98))
		else:
			draw_circle(bullet.position, bullet.radius + 2.0, Color(0.4, 0.91, 0.98, 0.22))
			draw_circle(bullet.position, bullet.radius, Color("#67e8f9"))
			draw_arc(bullet.position, bullet.radius + 1.0, 0.0, TAU, 12, Color("#ecfeff"), 1.0)

func _draw_enemy_projectiles() -> void:
	for projectile in enemy_projectiles:
		var velocity: Vector2 = projectile.velocity
		var direction: Vector2 = velocity.normalized()
		var trail_start: Vector2 = projectile.position - direction * 14.0
		draw_line(trail_start, projectile.position, Color(1.0, 0.16, 0.05, 0.18), 3.0)
		draw_line(trail_start, projectile.position, Color(1.0, 0.76, 0.42, 0.42), 1.0)
		draw_circle(projectile.position, projectile.radius + 4.0, Color(1.0, 0.14, 0.04, 0.09))
		var texture: Texture2D = vfx_textures.get("enemy_red_bullet")
		if texture:
			var rotation: float = velocity.angle() + PI / 2.0
			_draw_centered_texture(texture, projectile.position, ENEMY_PROJECTILE_PREVIEW_HEIGHT * 0.92, rotation, Color(1.0, 1.0, 1.0, 0.86))
		else:
			draw_circle(projectile.position, projectile.radius, UI_ORANGE)

func _draw_enemies() -> void:
	for enemy in enemies:
		var enemy_type_id: String = str(enemy.get("type_id", VOID_DRONE_ID))
		var texture_set: Dictionary = enemy_textures.get(enemy_type_id, enemy_textures.get(VOID_DRONE_ID, {}))
		var enemy_direction: String = str(enemy.get("direction", "down"))
		var enemy_state := str(enemy.get("visual_state", "thrust"))
		var primary_state := _get_enemy_primary_sprite_state(enemy, enemy_state)
		var texture_key := primary_state + "-" + enemy_direction
		var texture: Texture2D = texture_set.get(texture_key, texture_set.get("thrust-" + enemy_direction, texture_set.get("idle-down")))
		if texture == null:
			continue
		var definition := _get_enemy_definition(enemy_type_id)
		var visual_canvas_height: float = float(definition.get("visual_canvas_height", float(enemy.radius) * 6.0))
		var flash: float = clampf(float(enemy.get("hit_flash", 0.0)) / ENEMY_DAMAGE_FLASH_SECONDS, 0.0, 1.0)
		var attack_charge: float = _get_enemy_attack_charge(enemy)
		var pulse: float = 0.5 + sin(background_time * 2.8 + float(enemy.id) * 0.37) * 0.5
		_draw_enemy_void_aura(enemy, flash, attack_charge, pulse)
		var base_alpha: float = 0.95 + flash * 0.05
		var tint := Color(1.0, 1.0 - flash * 0.10, 1.0 - flash * 0.18, clampf(base_alpha, 0.90, 1.0))
		var height := visual_canvas_height * (1.0 + flash * 0.025 + attack_charge * 0.015)
		_draw_centered_texture(texture, enemy.position, height, 0.0, tint)
		_draw_enemy_attack_telegraph(enemy, attack_charge)
		if flash > 0.0:
			draw_circle(enemy.position, enemy.radius * 0.86, Color(1, 0.58, 0.38, 0.08 * flash))
		_draw_enemy_core(enemy, flash, attack_charge, pulse)
		_draw_enemy_hp_feedback(enemy)

func _get_enemy_primary_sprite_state(enemy: Dictionary, visual_state: String) -> String:
	if visual_state == "idle":
		return "idle"
	var velocity: Vector2 = enemy.get("velocity", Vector2.ZERO)
	if velocity.length_squared() <= 9.0:
		return "idle"
	return "thrust"

func _draw_enemy_void_aura(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var radius: float = enemy.radius
	draw_circle(enemy.position, radius * 1.10, Color(1.0, 0.04, 0.06, 0.012 + pulse * 0.008 + attack_charge * 0.018 + flash * 0.030))
	if attack_charge > 0.08:
		draw_arc(enemy.position, radius * 1.32, -PI * 0.22, PI * 0.82, 18, Color(1.0, 0.36, 0.12, attack_charge * 0.12), 0.75)

func _draw_enemy_core(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var core_radius: float = float(enemy.radius) * (0.08 + pulse * 0.018 + attack_charge * 0.035)
	var core_alpha: float = 0.16 + pulse * 0.06 + flash * 0.16 + attack_charge * 0.12
	draw_circle(enemy.position, float(enemy.radius) * 0.22, Color(1.0, 0.05, 0.03, 0.030 + attack_charge * 0.035))
	draw_circle(enemy.position, core_radius, Color(1.0, 0.26, 0.10, clampf(core_alpha, 0.0, 0.42)))
	draw_circle(enemy.position, maxf(1.1, core_radius * 0.30), Color(1.0, 0.82, 0.56, 0.20 + flash * 0.14))

func _draw_enemy_attack_telegraph(enemy: Dictionary, attack_charge: float) -> void:
	if attack_charge <= 0.03:
		return

	var direction: Vector2 = _get_enemy_forward_direction(enemy)
	var origin: Vector2 = enemy.position + direction * float(enemy.radius) * 0.72
	var beam_length: float = lerpf(18.0, 68.0, attack_charge)
	var end: Vector2 = origin + direction * beam_length
	draw_line(origin, end, Color(1.0, 0.10, 0.02, 0.10 + attack_charge * 0.24), 2.0)
	draw_line(origin, end, Color(1.0, 0.72, 0.46, 0.14 + attack_charge * 0.34), 0.9)
	draw_arc(enemy.position, float(enemy.radius) * (0.96 + attack_charge * 0.18), direction.angle() - 0.52, direction.angle() + 0.52, 14, Color(1.0, 0.30, 0.08, attack_charge * 0.18), 0.8)
	var projectile_texture: Texture2D = vfx_textures.get("enemy_red_bullet")
	_draw_centered_texture(projectile_texture, origin + direction * (beam_length + 5.0), ENEMY_PROJECTILE_PREVIEW_HEIGHT * 0.82, direction.angle() + PI / 2.0, Color(1.0, 0.50, 0.22, attack_charge * 0.42))

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
	_draw_centered_texture(trail_texture, player.position + Vector2(0, PLAYER_SHIP_VISUAL_HEIGHT * 0.34), ENGINE_TRAIL_HEIGHT, 0.0, Color(1, 1, 1, trail_alpha))
	if player_damage_flash > 0.0:
		var flash := player_damage_flash / PLAYER_DAMAGE_FLASH_SECONDS
		draw_circle(player.position, PLAYER_RADIUS * 2.3, Color(0.20, 0.88, 1.0, 0.11 * flash))
		draw_arc(player.position, PLAYER_RADIUS * 2.25, -PI * 0.10, PI * 1.36, 38, Color(0.55, 0.95, 1.0, 0.74 * flash), 2.0)
	_draw_centered_texture(texture, player.position, PLAYER_SPRITE_CANVAS_HEIGHT, 0.0, Color.WHITE)

func _draw_ready_overlay(size: Vector2) -> void:
	var rect := Rect2(22, size.y * 0.18, size.x - 44, minf(388.0, size.y - size.y * 0.18 - 26.0))
	_draw_lcars_panel(rect, UI_CYAN, "SYSTEM READY")
	var icon_texture: Texture2D = ship_textures.get("icon")
	_draw_centered_texture(icon_texture, rect.position + Vector2(46, 78), 48.0, 0.0, Color.WHITE)
	draw_string(get_theme_default_font(), rect.position + Vector2(82, 60), "VOID DRIFTER", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 110, 34, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(84, 84), "ボイド ドリフター", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 112, 14, UI_CYAN)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 124), "AUTO SHOOTER - SPACE ROGUELITE", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 12, UI_MAGENTA)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 152), "Survive the sector. Your ship fires automatically.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 15, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 181), "Click or drag to steer. Weapons auto-target the nearest enemy.", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 13, UI_CYAN)
	_draw_lcars_meter(Rect2(rect.position.x + 30, rect.position.y + 212, rect.size.x - 60, 9), 0.82, UI_TEAL, "SECTOR SIGNAL", "82%")
	var profile_y := rect.position.y + 246.0
	var profile_gap := 8.0
	var profile_width := (rect.size.x - 60.0 - profile_gap) / 2.0
	_draw_stat_pill(Rect2(rect.position.x + 30.0, profile_y, profile_width, 46.0), "COINS", str(int(metaProgress.get("totalCoins", 0))), UI_TEAL)
	_draw_stat_pill(Rect2(rect.position.x + 30.0 + profile_width + profile_gap, profile_y, profile_width, 46.0), "BEST", _format_compact_score(int(metaProgress.get("bestScore", 0))), UI_MAGENTA)

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
	_draw_stat_pill(Rect2(rect.position.x + 28.0, stat_y, stat_width, 54.0), "WAVE", str(int(runState.wave)), UI_MAGENTA)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + stat_width + stat_gap, stat_y, stat_width, 54.0), "TIME", _format_time(float(runState.elapsedSeconds)), UI_CYAN)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + (stat_width + stat_gap) * 2.0, stat_y, stat_width, 54.0), "SCORE", str(_get_score()), UI_TEAL)
	_draw_signal_loss_bar(Rect2(rect.position.x + 30.0, rect.position.y + 198.0, rect.size.x - 60.0, 8.0))
	var earned_y := rect.position.y + 224.0
	_draw_stat_pill(Rect2(rect.position.x + 28.0, earned_y, stat_width, 52.0), "KILLS", str(int(runState.kills)), UI_MAGENTA)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + stat_width + stat_gap, earned_y, stat_width, 52.0), "COINS", str(int(runState.coinsEarned)), UI_TEAL)
	_draw_stat_pill(Rect2(rect.position.x + 28.0 + (stat_width + stat_gap) * 2.0, earned_y, stat_width, 52.0), "BEST", _format_compact_score(int(metaProgress.get("bestScore", 0))), UI_CYAN)
	var record_y := rect.position.y + 292.0
	var record_text := _get_record_summary_text()
	draw_string(get_theme_default_font(), rect.position + Vector2(28.0, record_y), record_text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 56.0, 12, UI_ORANGE if record_text != "NO NEW RECORDS" else UI_TEXT_DIM)

func _draw_levelup_overlay(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, 0.44))
	var card_width := minf(520.0, size.x - 36.0)
	var card_height := minf(352.0, size.y - 92.0)
	var rect := Rect2((size.x - card_width) / 2.0, maxf(78.0, size.y * 0.17), card_width, card_height)
	_draw_lcars_panel(rect, UI_MAGENTA, "LEVEL UP")
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 58), "CHOOSE RUN UPGRADE", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 24, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 86), "Level " + str(int(runState.level)) + "  /  XP " + str(int(runState.xp)) + " / " + str(_get_xp_threshold(int(runState.level))), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 12, UI_CYAN)
	for index in range(pending_level_choices.size()):
		var choice: Dictionary = pending_level_choices[index]
		var choice_rect := Rect2(rect.position.x + 28.0, rect.position.y + 116.0 + float(index) * 66.0, rect.size.x - 56.0, 54.0)
		_draw_glass_panel(choice_rect, UI_CYAN if index == 0 else UI_TEAL, "", 0.18)
		draw_string(get_theme_default_font(), choice_rect.position + Vector2(14, 21), str(choice.name), HORIZONTAL_ALIGNMENT_LEFT, choice_rect.size.x - 128, 14, UI_TEXT)
		draw_string(get_theme_default_font(), choice_rect.position + Vector2(14, 40), str(choice.description), HORIZONTAL_ALIGNMENT_LEFT, choice_rect.size.x - 128, 9, UI_TEXT_DIM)

func _draw_permanent_upgrade_overlay(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, 0.46))
	var rect := Rect2(20.0, maxf(72.0, size.y * 0.10), size.x - 40.0, minf(506.0, size.y - 96.0))
	_draw_lcars_panel(rect, UI_TEAL, "SHIP UPLINK")
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 58), "PERMANENT UPGRADES", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 23, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 84), "COINS " + str(int(metaProgress.get("totalCoins", 0))), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 13, UI_TEAL)
	for index in range(PERMANENT_UPGRADES.size()):
		var upgrade: Dictionary = PERMANENT_UPGRADES[index]
		var row := Rect2(rect.position.x + 28.0, rect.position.y + 116.0 + float(index) * 62.0, rect.size.x - 56.0, 50.0)
		var level := _get_permanent_upgrade_level(str(upgrade.id))
		var can_buy := level < PERMANENT_UPGRADE_MAX_LEVEL and int(metaProgress.get("totalCoins", 0)) >= _get_permanent_upgrade_cost(level)
		_draw_glass_panel(row, UI_CYAN if can_buy else UI_TEXT_DIM, "", 0.16)
		draw_string(get_theme_default_font(), row.position + Vector2(14, 19), str(upgrade.name) + "  LV " + str(level) + "/" + str(PERMANENT_UPGRADE_MAX_LEVEL), HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 132, 13, UI_TEXT)
		draw_string(get_theme_default_font(), row.position + Vector2(14, 38), str(upgrade.description), HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 132, 9, UI_TEXT_DIM)

func _draw_codex_overlay(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, 0.46))
	var rect := Rect2(20.0, maxf(72.0, size.y * 0.10), size.x - 40.0, minf(482.0, size.y - 96.0))
	_draw_lcars_panel(rect, UI_CYAN, "ENEMY CODEX")
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 58), "VOID HOSTILES", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56, 23, UI_TEXT)
	var index := 0
	for enemy_type_id in ENEMY_DEFINITIONS.keys():
		var enemy: Dictionary = ENEMY_DEFINITIONS[enemy_type_id]
		var discovered := _is_enemy_discovered(str(enemy.id))
		var stats := _get_enemy_stats(str(enemy.id), int(enemy.unlock_wave))
		var row := Rect2(rect.position.x + 28.0, rect.position.y + 96.0 + float(index) * 94.0, rect.size.x - 56.0, 82.0)
		var accent := UI_ORANGE if discovered else UI_TEXT_DIM
		_draw_glass_panel(row, accent, "", 0.18)
		var name := str(enemy.name) if discovered else "LOCKED SIGNAL"
		draw_string(get_theme_default_font(), row.position + Vector2(14, 22), name, HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 28, 15, UI_TEXT if discovered else UI_TEXT_DIM)
		draw_string(get_theme_default_font(), row.position + Vector2(14, 42), "UNLOCK WAVE " + str(int(enemy.unlock_wave)) + "  /  KILLS " + str(_get_enemy_total_kills(str(enemy.id))), HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 28, 10, UI_CYAN)
		var stat_text := "HP %s  SPD %s  DMG %s  XP %s  COIN %s  SCORE %s" % [str(stats.hp), str(int(stats.speed)), str(stats.contact_damage), str(stats.xp_reward), str(stats.coin_reward), str(stats.score_reward)]
		draw_string(get_theme_default_font(), row.position + Vector2(14, 64), stat_text, HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 28, 9, UI_TEXT_DIM if not discovered else UI_TEAL)
		index += 1

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
	var wave := int(runState.wave)
	var wave_text := "WAVE %02d" % wave
	var accent := UI_CYAN
	var meter_color := UI_TEAL
	var meter_percent := clampf(fmod(float(runState.elapsedSeconds), WAVE_SECONDS) / WAVE_SECONDS, 0.0, 1.0)
	if surge_active:
		accent = UI_ORANGE
		meter_color = UI_MAGENTA
		wave_text = "ELITE WAVE " + str(wave)
		meter_percent = _get_surge_progress()

	_draw_glass_panel(rect, accent, "", 0.24 if surge_active else 0.18)
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 19), wave_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.55, 10, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 74, 19), _format_time(float(runState.elapsedSeconds)), HORIZONTAL_ALIGNMENT_RIGHT, 60, 13, accent)
	_draw_lcars_meter(Rect2(rect.position.x + 16, rect.position.y + 36, rect.size.x - 32, 7), meter_percent, meter_color, "", "")
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 55), "ENEMIES " + str(enemies.size()), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 8, UI_MAGENTA if not surge_active else UI_ORANGE)

func _draw_score_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_MAGENTA, "", 0.24)
	_draw_lcars_block(Rect2(rect.position.x + 18, rect.position.y, rect.size.x * 0.58, 6), UI_MAGENTA, 0.64)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 19), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_MAGENTA)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 38), _format_compact_score(_get_score()), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 17, UI_TEXT)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 55), "KILLS " + str(int(runState.kills)) + "  C " + str(int(runState.coinsEarned)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 8, UI_TEAL)

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
		draw_string(get_theme_default_font(), rect.position + Vector2(24, 58), "TOUGHER HOSTILES / BONUS REWARDS", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 48, 9, _with_alpha(UI_ORANGE, alpha))

func _draw_time_module(rect: Rect2) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.16)
	_draw_compact_chip(Rect2(rect.position.x + 10, rect.position.y + 9, 72, 30), "TIME", _format_time(elapsed), UI_TEAL)
	_draw_compact_chip(Rect2(rect.position.x + 88, rect.position.y + 9, 34, 30), "EN", str(enemies.size()), UI_MAGENTA)

func _draw_status_module(rect: Rect2, hp_percent: float) -> void:
	_draw_glass_panel(rect, UI_CYAN, "", 0.18)
	draw_string(get_theme_default_font(), rect.position + Vector2(22, 18), "HULL STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI_CYAN)
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 26, rect.size.x - 44, 12), hp_percent, UI_TEAL if hp_percent > 0.3 else UI_ORANGE, "HP", str(player.hp) + " / " + str(int(player.get("max_hp", PLAYER_HP))))
	var weapon_label := "XP"
	var weapon_value := "LV " + str(int(runState.level))
	_draw_compact_meter(Rect2(rect.position.x + 22, rect.position.y + 48, rect.size.x - 44, 8), _get_weapon_charge_percent(), UI_ORANGE if weapon_level > 1 else UI_PLAYER_BLUE, weapon_label, weapon_value)

func _draw_weapon_strip(size: Vector2, compact_bottom := false) -> void:
	var slot_count := 5
	var strip_width := float(slot_count) * WEAPON_SLOT_SIZE + float(slot_count - 1) * WEAPON_SLOT_GAP
	var start := Vector2(maxf(16.0, size.x - strip_width - 18.0), size.y - WEAPON_SLOT_SIZE - 24.0)
	if compact_bottom:
		start = Vector2(maxf(8.0, (size.x - strip_width) / 2.0), size.y - WEAPON_SLOT_SIZE - 78.0)
	for index in range(slot_count):
		var rect := Rect2(start + Vector2(float(index) * (WEAPON_SLOT_SIZE + WEAPON_SLOT_GAP), 0), Vector2(WEAPON_SLOT_SIZE, WEAPON_SLOT_SIZE))
		if index == 0:
			_draw_weapon_slot(rect, "LV" + str(int(runState.level)), UI_TEAL if int(runState.level) == 1 else UI_ORANGE, true)
		elif index < _get_weapon_shot_count():
			_draw_weapon_slot(rect, "+SHOT", UI_CYAN, true)
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

func _get_permanent_upgrade_level(upgrade_id: String) -> int:
	var upgrades: Dictionary = metaProgress.get("permanentUpgrades", {})
	return clampi(int(upgrades.get(upgrade_id, 0)), 0, PERMANENT_UPGRADE_MAX_LEVEL)

func _get_permanent_upgrade_cost(current_level: int) -> int:
	return 25 + current_level * 35

func _get_player_max_hp() -> int:
	return PLAYER_HP + _get_permanent_upgrade_level("max_hp") * 20 + int(run_upgrades.get("max_hp_bonus", 0))

func _get_xp_multiplier() -> float:
	return 1.0 + float(_get_permanent_upgrade_level("xp_gain")) * 0.10

func _get_coin_multiplier() -> float:
	return 1.0 + float(_get_permanent_upgrade_level("coin_bonus")) * 0.10

func _get_incoming_damage(raw_damage: int) -> int:
	var reduction := clampf(float(run_upgrades.get("damage_reduction", 0.0)), 0.0, 0.80)
	return maxi(1, int(ceil(float(raw_damage) * (1.0 - reduction))))

func _mark_enemy_discovered(enemy_type_id: String) -> void:
	if not run_discovered_enemies.has(enemy_type_id):
		run_discovered_enemies.append(enemy_type_id)
	var discovered: Array = metaProgress.get("discoveredEnemies", [])
	if discovered.has(enemy_type_id):
		return
	discovered.append(enemy_type_id)
	metaProgress.discoveredEnemies = discovered
	profile = metaProgress
	profile_store.save_profile(profile)

func _is_enemy_discovered(enemy_type_id: String) -> bool:
	var discovered: Array = metaProgress.get("discoveredEnemies", [])
	return discovered.has(enemy_type_id)

func _get_enemy_total_kills(enemy_type_id: String) -> int:
	var total_kills: Dictionary = metaProgress.get("enemyKills", {})
	return int(total_kills.get(enemy_type_id, 0)) + int(run_enemy_kills.get(enemy_type_id, 0))

func _get_record_summary_text() -> String:
	var records := []
	if bool(last_run_records.get("bestScore", false)):
		records.append("BEST SCORE")
	if bool(last_run_records.get("highestWave", false)):
		records.append("HIGHEST WAVE")
	if bool(last_run_records.get("longestRunSeconds", false)):
		records.append("LONGEST RUN")
	if records.is_empty():
		return "NO NEW RECORDS"
	return "NEW RECORD: " + " / ".join(records)

func _with_alpha(color: Color, alpha: float) -> Color:
	var next := color
	next.a = alpha
	return next

func _layout_buttons() -> void:
	if not is_instance_valid(action_button) or not is_instance_valid(header_restart_button) or not is_instance_valid(enemies_button) or not is_instance_valid(upgrade_button) or not is_instance_valid(main_menu_button):
		return

	var size := get_viewport_rect().size
	if status == "paused":
		var card_width := minf(520.0, size.x - 36.0)
		var rect := Rect2((size.x - card_width) / 2.0, maxf(78.0, size.y * 0.17), card_width, minf(352.0, size.y - 92.0))
		for index in range(choice_buttons.size()):
			var button := choice_buttons[index]
			button.size = Vector2(96.0, 38.0)
			button.position = Vector2(rect.end.x - 132.0, rect.position.y + 124.0 + float(index) * 66.0)
	elif menu_view == "upgrades":
		var upgrade_rect := Rect2(20.0, maxf(72.0, size.y * 0.10), size.x - 40.0, minf(506.0, size.y - 96.0))
		for index in range(permanent_upgrade_buttons.size()):
			var button := permanent_upgrade_buttons[index]
			button.size = Vector2(92.0, 34.0)
			button.position = Vector2(upgrade_rect.end.x - 128.0, upgrade_rect.position.y + 124.0 + float(index) * 62.0)
		main_menu_button.size = Vector2(116.0, 36.0)
		main_menu_button.position = Vector2(upgrade_rect.end.x - 146.0, upgrade_rect.position.y + 26.0)
	elif menu_view == "codex":
		var codex_rect := Rect2(20.0, maxf(72.0, size.y * 0.10), size.x - 40.0, minf(482.0, size.y - 96.0))
		main_menu_button.size = Vector2(116.0, 36.0)
		main_menu_button.position = Vector2(codex_rect.end.x - 146.0, codex_rect.position.y + 26.0)
	elif status == "dead":
		var death_rect := _get_death_card_rect(size)
		var death_button_gap := 10.0
		var button_width := minf(124.0, (death_rect.size.x - 76.0 - death_button_gap * 2.0) / 3.0)
		action_button.size = Vector2(button_width, 46.0)
		upgrade_button.size = Vector2(button_width, 46.0)
		main_menu_button.size = Vector2(button_width, 46.0)
		enemies_button.size = Vector2(138.0, 32.0)
		var start_x := death_rect.position.x + (death_rect.size.x - button_width * 3.0 - death_button_gap * 2.0) / 2.0
		action_button.position = Vector2(start_x, death_rect.position.y + 330.0)
		upgrade_button.position = Vector2(start_x + button_width + death_button_gap, death_rect.position.y + 330.0)
		main_menu_button.position = Vector2(start_x + (button_width + death_button_gap) * 2.0, death_rect.position.y + 330.0)
		enemies_button.position = Vector2(death_rect.position.x + (death_rect.size.x - enemies_button.size.x) / 2.0, death_rect.position.y + 382.0)
	else:
		var ready_button_y := size.y * 0.18 + 308.0
		if size.x >= 520.0:
			var ready_button_gap := 12.0
			action_button.size = Vector2(154, 50)
			upgrade_button.size = Vector2(154, 50)
			enemies_button.size = Vector2(154, 50)
			var row_width := action_button.size.x + upgrade_button.size.x + enemies_button.size.x + ready_button_gap * 2.0
			action_button.position = Vector2((size.x - row_width) / 2.0, ready_button_y)
			upgrade_button.position = Vector2(action_button.position.x + action_button.size.x + ready_button_gap, ready_button_y)
			enemies_button.position = Vector2(upgrade_button.position.x + upgrade_button.size.x + ready_button_gap, ready_button_y)
		else:
			action_button.size = Vector2(170, 50)
			action_button.position = Vector2((size.x - action_button.size.x) / 2.0, ready_button_y)
			upgrade_button.size = Vector2(170, 42)
			upgrade_button.position = Vector2((size.x - upgrade_button.size.x) / 2.0, action_button.position.y + 58.0)
			enemies_button.size = Vector2(170, 38)
			enemies_button.position = Vector2((size.x - enemies_button.size.x) / 2.0, upgrade_button.position.y + 50.0)
	header_restart_button.size = Vector2(78, 28)
	header_restart_button.position = Vector2(size.x - header_restart_button.size.x - 16.0, 70.0)

func _update_buttons() -> void:
	_layout_buttons()
	header_restart_button.visible = status == "running"
	action_button.visible = (status == "menu" and menu_view == "main") or (status == "dead" and menu_view == "main")
	upgrade_button.visible = action_button.visible
	enemies_button.visible = action_button.visible
	main_menu_button.visible = (status == "dead" and menu_view == "main") or menu_view == "upgrades" or menu_view == "codex"
	action_button.text = "Start Run" if status == "menu" else "Run Again"
	upgrade_button.text = "Upgrade Ship"
	enemies_button.text = "Enemy Codex"
	main_menu_button.text = "Back" if menu_view != "main" else "Main Menu"
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index]
		button.visible = status == "paused" and index < pending_level_choices.size()
		if index < pending_level_choices.size():
			button.text = "Select"
	for index in range(permanent_upgrade_buttons.size()):
		var button := permanent_upgrade_buttons[index]
		var upgrade: Dictionary = PERMANENT_UPGRADES[index]
		var level := _get_permanent_upgrade_level(str(upgrade.id))
		var cost := _get_permanent_upgrade_cost(level)
		button.visible = menu_view == "upgrades"
		button.disabled = level >= PERMANENT_UPGRADE_MAX_LEVEL or int(metaProgress.get("totalCoins", 0)) < cost
		button.text = "MAX" if level >= PERMANENT_UPGRADE_MAX_LEVEL else str(cost)
	_apply_button_style(action_button, UI_ORANGE if status == "dead" else UI_CYAN, false)
	_apply_button_style(upgrade_button, UI_TEAL, true)
	_apply_button_style(enemies_button, UI_MAGENTA, true)
	_apply_button_style(main_menu_button, UI_CYAN, true)
	_apply_button_style(header_restart_button, UI_MAGENTA, true)
	for button in choice_buttons:
		_apply_button_style(button, UI_TEAL, true)
	for button in permanent_upgrade_buttons:
		_apply_button_style(button, UI_ORANGE if not button.disabled else UI_TEXT_DIM, true)

func _on_action_button_pressed() -> void:
	start_run()

func _on_enemies_button_pressed() -> void:
	menu_view = "codex"
	_update_buttons()
	queue_redraw()

func _on_upgrade_button_pressed() -> void:
	menu_view = "upgrades"
	_update_buttons()
	queue_redraw()

func _on_main_menu_button_pressed() -> void:
	if menu_view != "main":
		menu_view = "main"
		_update_buttons()
		queue_redraw()
		return
	reset_world("menu")

func _on_level_choice_pressed(index: int) -> void:
	if status != "paused" or index >= pending_level_choices.size():
		return
	var choice: Dictionary = pending_level_choices[index]
	_apply_run_upgrade(str(choice.id))
	pending_level_choices = []
	status = "running"
	runState.status = "running"
	_update_buttons()
	queue_redraw()

func _on_permanent_upgrade_pressed(index: int) -> void:
	if index < 0 or index >= PERMANENT_UPGRADES.size():
		return
	var upgrade: Dictionary = PERMANENT_UPGRADES[index]
	var upgrade_id := str(upgrade.id)
	var level := _get_permanent_upgrade_level(upgrade_id)
	if level >= PERMANENT_UPGRADE_MAX_LEVEL:
		return
	var cost := _get_permanent_upgrade_cost(level)
	if int(metaProgress.get("totalCoins", 0)) < cost:
		return
	metaProgress.totalCoins = int(metaProgress.totalCoins) - cost
	metaProgress.permanentUpgrades[upgrade_id] = level + 1
	profile = profile_store._sanitize_profile(metaProgress)
	metaProgress = profile
	profile_store.save_profile(profile)
	_update_buttons()
	queue_redraw()

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
	var card_height := minf(426.0, size.y - 112.0)
	return Rect2((size.x - card_width) / 2.0, maxf(82.0, size.y * 0.18), card_width, card_height)

func _clamp_player_to_viewport() -> void:
	if player.is_empty():
		return
	player.position = _clamp_point_to_playfield(player.position)
	player_target = _clamp_point_to_playfield(player_target)

func _clamp_point_to_playfield(point: Vector2) -> Vector2:
	var size := get_viewport_rect().size
	var playfield := _get_playfield_rect(size)
	var inset := PLAYER_RADIUS + PLAYER_BOUNDS_PADDING
	return Vector2(
		clampf(point.x, inset, maxf(inset, size.x - inset)),
		clampf(point.y, playfield.position.y + inset, maxf(playfield.position.y + inset, playfield.end.y - inset))
	)

func _get_playfield_rect(size: Vector2) -> Rect2:
	var top_reserved := minf(HUD_TOP_RESERVED, maxf(58.0, size.y * 0.16))
	var bottom_reserved := minf(HUD_BOTTOM_RESERVED, maxf(76.0, size.y * 0.22))
	var bottom := maxf(top_reserved + 160.0, size.y - bottom_reserved)
	return Rect2(0.0, top_reserved, size.x, minf(size.y, bottom) - top_reserved)

func _circles_overlap(a_position: Vector2, a_radius: float, b_position: Vector2, b_radius: float) -> bool:
	var hit_distance := a_radius + b_radius
	return a_position.distance_squared_to(b_position) <= hit_distance * hit_distance

func _get_player_ship_texture() -> Texture2D:
	if float(player.hp) / maxf(1.0, float(player.get("max_hp", PLAYER_HP))) <= PLAYER_DAMAGED_HP_THRESHOLD:
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
	return 1 + int(floor(seconds / WAVE_SECONDS))

func _get_enemy_definition(enemy_type_id: String) -> Dictionary:
	return ENEMY_DEFINITIONS[enemy_type_id]

func _get_enemy_stats(enemy_type_id: String, level: int) -> Dictionary:
	var definition := _get_enemy_definition(enemy_type_id)
	var base_stats: Dictionary = definition.base_stats
	var scaling: Dictionary = definition.scaling
	var level_offset := maxi(0, level - 1)
	var stats := {
		"level": level,
		"hp": base_stats.hp + scaling.hp_per_level * level_offset,
		"speed": base_stats.speed + scaling.speed_per_level * level_offset,
		"contact_damage": base_stats.contact_damage + scaling.damage_per_level * level_offset,
		"xp_reward": base_stats.xp_reward,
		"coin_reward": base_stats.coin_reward + int(floor(float(level_offset) * 0.5)),
		"score_reward": base_stats.score_reward,
		"radius": base_stats.radius,
	}
	if level >= 5 and level % 5 == 0:
		stats.hp = int(ceil(float(stats.hp) * 1.45))
		stats.contact_damage = int(ceil(float(stats.contact_damage) * 1.15))
		stats.xp_reward = int(ceil(float(stats.xp_reward) * 1.5))
		stats.coin_reward = int(ceil(float(stats.coin_reward) * 1.6))
		stats.score_reward = int(ceil(float(stats.score_reward) * 1.5))
	return stats

func _get_enemy_spawn_inset(enemy_type_id: String, stats: Dictionary) -> float:
	var definition := _get_enemy_definition(enemy_type_id)
	var visual_canvas_height: float = float(definition.get("visual_canvas_height", float(stats.radius) * 6.0))
	return maxf(float(stats.radius) + 12.0, visual_canvas_height * 0.34)

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
		return VOID_DRONE_ID

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

func _get_stable_direction_from_velocity(velocity: Vector2, fallback: String) -> String:
	var abs_x := absf(velocity.x)
	var abs_y := absf(velocity.y)
	if abs_x < 1.0 and abs_y < 1.0:
		return fallback
	if abs_x > abs_y * ENEMY_DIRECTION_DOMINANCE:
		return "left" if velocity.x < 0.0 else "right"
	if abs_y > abs_x * ENEMY_DIRECTION_DOMINANCE:
		return "up" if velocity.y < 0.0 else "down"
	return fallback

func _get_active_sector_index() -> int:
	if BACKGROUND_SECTORS.is_empty():
		return 0
	var sector_time: float = float(runState.elapsedSeconds) if status == "running" else background_time
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

	var warmup: float = float(enemy.get("attack_warmup_timer", 0.0))
	if warmup > 0.0:
		return clampf(1.0 - warmup / ENEMY_ATTACK_WARMUP_SECONDS, 0.0, 1.0)
	if float(enemy.get("attack_visual_timer", 0.0)) > 0.0:
		return clampf(float(enemy.attack_visual_timer) / ENEMY_ATTACK_VISUAL_SECONDS, 0.0, 1.0) * 0.42
	return 0.0

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
	return int(runState.score) + int(floor(float(runState.elapsedSeconds))) * 5

func _format_compact_score(value: int) -> String:
	if value >= 100000:
		return "%.1fK" % (float(value) / 1000.0)
	return "%05d" % value

func _format_roman(value: int) -> String:
	var numerals := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	if value >= 0 and value < numerals.size():
		return numerals[value]
	return str(value)
