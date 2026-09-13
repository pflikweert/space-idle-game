extends Control

const EnemyNavigation := preload("res://scripts/systems/enemy_navigation.gd")
const EnemyWeapons := preload("res://scripts/systems/enemy_weapons.gd")
const ShieldSystem := preload("res://scripts/systems/shield_system.gd")
const GunshipVisuals := preload("res://scripts/systems/gunship_visuals.gd")
const ProfileStore := preload("res://scripts/profile_store.gd")
const EnemyRegistry := preload("res://scripts/systems/enemy_registry.gd")
const UpgradeRegistry := preload("res://scripts/systems/upgrade_registry.gd")
const EffectRegistry := preload("res://scripts/systems/effect_registry.gd")
const WeaponRegistry := preload("res://scripts/systems/weapon_registry.gd")
const Autopilot := preload("res://scripts/systems/autopilot.gd")
const ProgressionPanel := preload("res://scripts/systems/railgun_panel.gd")
const Cards := preload("res://scripts/systems/railgun_cards.gd")
const DirectorSystem := preload("res://scripts/systems/director_system.gd")
const AudioEvents := preload("res://scripts/systems/audio_events.gd")

# Gameplay tuning
const PLAYER_HP := 140
const FIRST_ENEMY_SPAWN_DELAY := 1350.0
const PLAYER_FIRE_INTERVAL := 500.0
const PLAYER_MOVE_SPEED := 470.0
const PLAYER_BOUNDS_PADDING := 10.0
# Sized for the 430px mobile reference viewport; canvas stretch handles smaller screens.
const COMBAT_SPRITE_SCALE := 0.48
# Nozzle centers measured on the dreadnought's fixed 384x512 idle-up canvas.
const BOSS_ENGINE_NOZZLES := [Vector2(142, 376), Vector2(173, 377), Vector2(215, 377), Vector2(246, 376)]
const EFFECT_SCALE := 0.8
const PLAYER_RADIUS := 18.0 * COMBAT_SPRITE_SCALE
# Movement sprites use fixed transparent canvases; keep draw height separate from collision radius to avoid pivot jitter.
const PLAYER_SHIP_VISUAL_HEIGHT := 88.0 * COMBAT_SPRITE_SCALE
const PLAYER_SPRITE_CANVAS_HEIGHT := 204.0 * COMBAT_SPRITE_SCALE
const PLAYER_DAMAGED_HP_THRESHOLD := 0.3
const PLAYER_BANKING_THRESHOLD := 1.2
const MAX_DELTA_SECONDS := 0.033

# Visual tuning
const PARTICLE_LIFETIME := 0.42
const SPRITE_PARTICLE_LIFETIME := 0.34
const BULLET_SPRITE_HEIGHT := 34.0 * 0.8
const BULLET_TRAIL_LENGTH := 24.0 * 0.8
const ENGINE_TRAIL_HEIGHT := 52.0 * COMBAT_SPRITE_SCALE
const HIT_SPARK_SPRITE_HEIGHT := 30.0 * 0.8
const SHIELD_IMPACT_SPRITE_HEIGHT := 96.0 * 0.8
const ENEMY_DAMAGE_FLASH_SECONDS := 0.16
const PLAYER_DAMAGE_FLASH_SECONDS := 0.38
const FIRST_IMPACT_MULTIPLIER := 2.0
const PROJECTILE_DAMAGE_MULTIPLIER := 2.0
const ENEMY_ATTACK_WARMUP_SECONDS := 0.42
const ENEMY_ATTACK_VISUAL_SECONDS := 0.20
const ENEMY_DEATH_SPRITE_HEIGHT := 102.0
const ENEMY_PROJECTILE_PREVIEW_HEIGHT := 22.0 * 0.8
const ENEMY_DIRECTION_LOCK_SECONDS := 0.16
const ENEMY_DIRECTION_DOMINANCE := 1.18

# HUD presentation
const UI_CYAN := Color("#00E5FF")
const UI_MAGENTA := Color("#FF00FF")
const UI_ORANGE := Color("#FF6D00")
const UI_TEAL := Color("#00E676")
const UI_TEXT := Color("#E0E0FF")


const VOID_DRONE_ID := "void_drone"
const ENEMY_FRAME_STATES := ["idle", "thrust", "attack", "hit"]
const ENEMY_FRAME_DIRECTIONS := ["down", "up", "left", "right"]
const ENEMY_MOVEMENT_FRAMES_BY_EDGE := {
	"top": "down",
	"bottom": "up",
	"left": "right",
	"right": "left",
}
const BACKGROUND_SECTORS := [
	{ "id": "cosmic-bloom", "path": "res://assets/backgrounds/sectors/sector_cosmic_bloom_generated.png", "opacity": 0.62 },
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

var overlay: PanelContainer
var upgrades_control: Button
var pause_control: Button
var auto_control: Button
var speed_control: Button
var auto_cards_control: Button
var build_control: Button
var wave_control: Button
var cards := Cards.fresh()
const RailVisuals := preload("res://scripts/systems/railgun_visuals.gd")
var rail_visuals := RailVisuals.new()
const WeaponHUDCard := preload("res://scripts/systems/weapon_hud_card.gd")
var weapon_hud: Control
var hud_safe := Vector4.ZERO
const CompactUI := preload("res://scripts/systems/compact_ui.gd")
var overview_control: Button
var selected_card := ""
var hud_icon_textures: Dictionary = {}
var card_detail_origin := "railgun_catalog"
var card_detail := "power"
var empty_weapon_slots: Array[Control] = []
var enemy_damage_numbers: Array[Dictionary] = []
var card_notices: Array[String] = []
var card_notice := ""
var card_notice_timer := 0.0
var card_notice_label: Label
var reward_dirty := false
var buy_quantity := 1
var damage_numbers: Array[Dictionary] = []
var hull_damage_trail := 0.0
var hull_damage_timer := 0.0
var shop_category := "Attack"
var codex_tab := "active"
var codex_previews: Dictionary = {}
var wave_intel_tab := "roster"
var codex_detail_id := ""
var codex_detail_origin := "codex"
var codex_detail_wave := 1
var rng := RandomNumberGenerator.new()
var run_id := ""
var save_timer := 0.0
var manual_override := 0.0
var auto_timer := 0.0
var last_boss_wave := 0
var stored_viewport := Vector2.ZERO
var ui_factor := 1.0
var last_layout_size := Vector2.ZERO
var overlay_target_size := Vector2.ZERO
var background_callback: JavaScriptObject
var foreground_callback: JavaScriptObject
var save_error := false

var ship_textures := {}
var enemy_textures := {}
var vfx_textures := {}
var sector_textures: Array[Texture2D] = []
var background_textures: Array[Texture2D] = []
var midfield_textures: Array[Texture2D] = []
var foreground_textures: Array[Texture2D] = []
var run_complete_background: Texture2D
var status := "menu"
var runState := {
	"status": "menu",
	"wave": 1,
	"score": 0,
	"kills": 0,
	"cash": 30.0,
	"phase": "spawning",
	"coinsEarned": 0.0,
	"elapsedSeconds": 0.0,
}
var run_upgrades := UpgradeRegistry.defaults()
var menu_view := "main"
var player := {}
var player_target := Vector2.ZERO
var player_velocity_x := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var visual_time := 0.0
var in_process_frame := false
var cosmetic_id := 0
var gunship := GunshipVisuals.new()
var death_timer := 0.0
var app_backgrounded := false
var rail_recoil := 0.0
var rail_direction := Vector2.UP
var explosion_frames: Array[Texture2D] = []
var muzzle_flashes: Array[Dictionary] = []
var kills := 0
var score := 0
var elapsed := 0.0
var background_time := 0.0
var spawn_timer := FIRST_ENEMY_SPAWN_DELAY
var fire_timer := PLAYER_FIRE_INTERVAL * 0.6
var next_id := 1
var pointer_down := false
var player_damage_flash := 0.0
var wave_message := ""
var wave_message_timer := 0.0
var profile_store := ProfileStore.new()
var profile := {}
var metaProgress := {}
var run_enemy_kills := {}
var run_discovered_enemies := []
var last_run_records := {}
var run_recorded := false
var weapon_level := 1
var screen_shake := 0.0
var level_pulse := 0.0
var wave_pulse := 0.0
var active_draw_offset := Vector2.ZERO
var audio_events := AudioEvents.new()

func _ready() -> void:
	set_process(true)
	profile = profile_store.load_profile()
	metaProgress = profile
	_create_runtime_buttons()
	rng.randomize()
	gunship.load_art(self)
	ship_textures = {"idle": gunship.textures.intact, "damaged": gunship.textures.damaged, "icon": gunship.textures.intact}
	build_control.icon = gunship.textures.intact
	vfx_textures = {"engine_trail": load("res://assets/vfx/engine_trail.png")}
	run_complete_background = load("res://assets/backgrounds/run_complete_victory_generated.png")
	for index in range(8):
		explosion_frames.append(_load_png_texture("res://assets/vfx/railgun/explosion-%02d.png" % index))
	_load_enemy_textures_from_registry()
	for index in [0, 2]:
		background_textures.append(load(PARALLAX_LAYERS[index].path))
	reset_world("menu")
	if not profile.activeRun.is_empty():
		_restore_run()
	_setup_background_events()
	_refresh_overlay()

func _create_runtime_buttons() -> void:
	overlay = ProgressionPanel.new()
	add_child(overlay)
	overlay.selected.connect(_on_panel_action)
	upgrades_control = overlay.button("Upgrades", "shop")
	pause_control = overlay.button("Pause", "pause")
	auto_control = overlay.button("Auto", "auto")
	speed_control = overlay.button("1x", "speed")
	auto_cards_control = overlay.button("Auto Cards: OFF", "auto_cards")
	build_control = overlay.button("Railgun", "build")
	wave_control = overlay.button("WAVE 1", "wave_intel")
	# Preserve a generous touch target without making the wave readout look like a HUD button.
	wave_control.flat = true
	for state in ["normal", "hover", "pressed", "disabled"]:
		wave_control.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	wave_control.add_theme_color_override("font_color", UI_TEXT)
	wave_control.add_theme_color_override("font_hover_color", UI_TEAL)
	build_control.expand_icon = true
	speed_control.tooltip_text = "Tap to cycle 1x, 2x, 3x, 4x, 5x, 10x"
	for control in [upgrades_control, pause_control, auto_control, speed_control, auto_cards_control, build_control, wave_control]:
		add_child(control)
	card_notice_label = Label.new()
	card_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_notice_label.add_theme_color_override("font_color", UI_TEXT)
	add_child(card_notice_label)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(overlay):
		var old_bounds := _get_playfield_rect(stored_viewport)
		last_layout_size = Vector2.ZERO
		_layout_buttons()
		_remap_viewport(stored_viewport, get_viewport_rect().size, old_bounds)
		stored_viewport = get_viewport_rect().size
		call_deferred("_refresh_overlay")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		app_backgrounded = true
		_pause_run()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		app_backgrounded = false

func _process(delta: float) -> void:
	in_process_frame = true
	if status == "running":
		runState.realElapsedSeconds = float(runState.get("realElapsedSeconds",0.0)) + maxf(0.0,delta)
		_update_card_notice(delta)
		_update_damage_feedback(minf(delta, 0.1))
		_update_visual_effects(minf(delta, 0.1))
		var remaining := minf(delta, 0.1) * _game_speed()
		while remaining > 0.00001 and status == "running":
			var step := minf(remaining, MAX_DELTA_SECONDS)
			background_time += step
			_update_world(step)
			remaining -= step
	elif status == "dead" and death_timer > 0.0:
		if not app_backgrounded:
			_update_visual_effects(minf(delta, 0.1))
			_update_damage_feedback(minf(delta, 0.1))
			death_timer = maxf(0.0, death_timer - minf(delta, 0.1))
			if death_timer <= 0.00001:
				death_timer = 0.0
				_refresh_overlay()
	elif status == "menu" or status == "dead":
		background_time += minf(delta, MAX_DELTA_SECONDS)
	_update_buttons()
	queue_redraw()
	in_process_frame = false

func _unhandled_input(event: InputEvent) -> void:
	if status != "running":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		manual_override = 1.0
		if event.pressed:
			player_target = _clamp_point_to_playfield(event.position)
	elif event is InputEventMouseMotion and pointer_down:
		player_target = _clamp_point_to_playfield(event.position)
		manual_override = 1.0
	elif event is InputEventScreenTouch:
		pointer_down = event.pressed
		manual_override = 1.0
		if event.pressed:
			player_target = _clamp_point_to_playfield(event.position)
	elif event is InputEventScreenDrag:
		player_target = _clamp_point_to_playfield(event.position)
		manual_override = 1.0

func reset_world(next_status: String) -> void:
	cards = Cards.fresh()
	card_notice = ""
	card_notice_timer = 0.0
	reward_dirty = false
	damage_numbers.clear()
	enemy_damage_numbers.clear()
	card_notices.clear()
	hull_damage_timer = 0.0
	hull_damage_trail = 0.0
	var size := get_viewport_rect().size
	var playfield := _get_playfield_rect(size)
	var start := playfield.get_center()
	status = next_status
	runState = {
		"status": next_status,
		"wave": 1,
		"score": 0,
		"kills": 0,
		"cash": 30.0,
		"phase": "spawning",
		"coinsEarned": 0.0,
		"elapsedSeconds": 0.0,
		"realElapsedSeconds": 0.0,
		"fleetOrbitSign": 1.0,
	}
	run_upgrades = UpgradeRegistry.defaults()
	run_enemy_kills = {}
	run_discovered_enemies = []
	last_run_records = {}
	menu_view = "main"
	var player_max_hp := _get_player_max_hp()
	player = {
		"position": start,
		"radius": PLAYER_RADIUS,
		"hp": player_max_hp,
		"max_hp": player_max_hp,
		"shield": _stat("shield_capacity"),
		"max_shield": _stat("shield_capacity"),
		"shield_delay": 0.0,
		"weapon": {"ammo": int(WeaponRegistry.cycle("railgun").magazine), "reload_timer": 0.0},
	}
	player_target = start
	player_velocity_x = 0.0
	enemies = []
	bullets = []
	enemy_projectiles = []
	particles = []
	muzzle_flashes = []
	rail_recoil = 0.0
	rail_direction = Vector2.UP
	gunship.reset()
	death_timer = 0.0
	visual_time = 0.0
	cosmetic_id = 0
	kills = 0
	score = 0
	elapsed = 0.0
	background_time = 0.0
	spawn_timer = FIRST_ENEMY_SPAWN_DELAY
	fire_timer = PLAYER_FIRE_INTERVAL * 0.6
	next_id = 1
	pointer_down = false
	player_damage_flash = 0.0
	wave_message = ""
	wave_message_timer = 0.0
	run_recorded = false
	weapon_level = 1
	run_id = ""
	save_timer = 0.0
	last_boss_wave = 0
	manual_override = 0.0
	auto_timer = 0.0
	stored_viewport = size
	screen_shake = 0.0
	level_pulse = 0.0
	wave_pulse = 0.0
	_sync_legacy_run_fields()
	_update_buttons()
	queue_redraw()

func start_run() -> void:
	if not profile.activeRun.is_empty():
		return
	reset_world("running")
	run_id = "%d-%d" % [Time.get_unix_time_from_system() * 1000, rng.randi()]
	cards = Cards.fresh(hash(run_id))
	runState.fleetOrbitSign = -1.0 if rng.randi() % 2 == 0 else 1.0
	_save_run()
	_refresh_overlay()

func _end_run(animate := false) -> void:
	if status == "dead":
		return

	if not run_recorded:
		run_recorded = true
		profile = profile_store.record_run(profile, {
			"run_id": run_id,
			"score": _get_score(),
			"kills": int(runState.kills),
			"wave": int(runState.wave),
			"time_seconds": int(floor(float(runState.elapsedSeconds))),
			"coins_earned": float(runState.coinsEarned),
			"modules_earned": int(cards.modules),
			"enemy_kills": run_enemy_kills,
			"discovered_enemies": run_discovered_enemies,
		})
		metaProgress = profile
		last_run_records = profile.get("lastRun", {}).get("newRecords", {})

	death_timer = 0.8 if animate else 0.0
	if animate:
		for index in range(3):
			var offset := Vector2(-12 + index * 12, -8 + index % 2 * 15)
			_append_effect(EffectRegistry.make("explosion", player.position + offset, 70.0, index * 0.16))
		for index in range(8):
			var debris := EffectRegistry.make("debris", player.position)
			debris.velocity = Vector2.from_angle(index * TAU / 8) * (12 + index * 2)
			debris.color = Color("#7fc9e3")
			debris.radius = 1.5
			_append_effect(debris)
	status = "dead"
	runState.status = "dead"
	menu_view = "main"
	save_error = not profile_store.last_save_ok
	_refresh_overlay()
	bullets = []
	enemy_projectiles = []
	enemies = []
	audio_events.emit(AudioEvents.DEATH, { "score": _get_score(), "wave": int(runState.wave) })

func _update_world(delta: float) -> void:
	# Headless simulations advance the same visual clock without rendering.
	if not is_processing() and not in_process_frame: _update_visual_effects(delta)
	manual_override = maxf(0.0, manual_override - delta)
	if pointer_down:
		manual_override = 1.0
	runState.elapsedSeconds = float(runState.elapsedSeconds) + delta
	var changed_wave := _update_wave_manager()
	_sync_legacy_run_fields()
	_update_autopilot(delta)
	_update_player(delta)
	player.hp = minf(float(player.max_hp), float(player.hp) + _stat("regen") * delta)
	_update_enemy_spawning(delta * 1000.0)
	_update_weapons(delta * 1000.0)
	_update_enemy_movement(delta)
	_update_enemy_weapons(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_resolve_collisions()
	_handle_card_progress()
	_sync_legacy_run_fields()
	save_timer += delta
	if status == "running" and (reward_dirty or changed_wave or save_timer >= 10.0):
		_save_run()
		reward_dirty = false

func _update_wave_manager() -> bool:
	var next_wave := DirectorSystem.get_run_level(float(runState.elapsedSeconds))
	var changed := next_wave != int(runState.wave)
	while int(runState.wave) < next_wave:
		var completed := int(runState.wave)
		runState.cash = float(runState.cash) + (10.0 + 2.0 * completed + _stat("cash_wave")) * _stat("cash_bonus")
		runState.coinsEarned = float(runState.coinsEarned) + 2.0 * _stat("coin_bonus")
		runState.wave = completed + 1
		if int(runState.wave) % 10 == 0 and last_boss_wave != int(runState.wave):
			last_boss_wave = int(runState.wave)
			if _count_bosses() < DirectorSystem.MAX_BOSSES:
				_spawn_enemy_at(_get_regular_spawn_position(EnemyRegistry.BOSS_ID), EnemyRegistry.BOSS_ID)
		wave_message = "BOSS INBOUND" if int(runState.wave) % 10 == 0 else "WAVE %d" % int(runState.wave)
		wave_message_timer = 1.5
		wave_pulse = 0.55
		audio_events.emit(AudioEvents.WAVE_CLEAR, {"wave": completed})
	runState.phase = DirectorSystem.phase(float(runState.elapsedSeconds))
	return changed

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
	player_velocity_x = movement.x / maxf(delta, 0.000001)

func _update_enemy_spawning(delta_ms: float) -> void:
	if runState.phase != "spawning":
		spawn_timer = 0.0
		return
	spawn_timer -= delta_ms
	if spawn_timer <= 0.0:
		var interval := DirectorSystem.spawn_interval(int(runState.wave)) * 1000.0
		# Preserve fractional frame time, but discard missed attempts after a long step.
		spawn_timer = interval + fmod(spawn_timer, interval)
		if enemies.size() - _count_bosses() < DirectorSystem.MAX_NORMAL:
			_spawn_enemy()

func _spawn_enemy() -> void:
	var run_level := int(runState.wave)
	var enemy_type_id := _choose_enemy_type_id(run_level, rng.randi())
	_spawn_enemy_at(_get_regular_spawn_position(enemy_type_id), enemy_type_id)

func _spawn_enemy_at(spawn_data: Dictionary, enemy_type_id := "") -> void:
	var size := get_viewport_rect().size
	var run_level := int(runState.wave)
	var resolved_enemy_type_id := enemy_type_id
	if resolved_enemy_type_id == "":
		resolved_enemy_type_id = _choose_enemy_type_id(run_level, rng.randi())
	var elite_modifier := ""
	var stats := EnemyRegistry.get_stats(resolved_enemy_type_id, run_level, elite_modifier)
	var spawn_edge: String = str(spawn_data.get("edge", "top"))
	var position: Vector2 = spawn_data.get("position", Vector2(size.x / 2.0, -EnemyRegistry.get_spawn_inset(resolved_enemy_type_id, stats)))
	var enemy_id := next_id
	next_id += 1
	var definition := EnemyRegistry.get_definition(resolved_enemy_type_id)
	var shield_value := int(ceil(float(stats.hp) * 0.24)) if elite_modifier == "shielded" else 0

	enemies.append({
		"id": enemy_id,
		"type_id": resolved_enemy_type_id,
		"position": position,
		"radius": stats.radius * COMBAT_SPRITE_SCALE,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"shield": shield_value,
		"max_shield": shield_value,
		"speed": stats.speed,
		"contact_damage": stats.contact_damage,
		"cash_reward": stats.cash_reward,
		"contact_cooldown": 0.0,
		"has_contacted": false,
		"coin_reward": stats.coin_reward,
		"score_reward": stats.score_reward,
		"movement_behavior": str(definition.get("movement_behavior", "chase")),
		"attack_behavior": str(definition.get("attack_behavior", "contact")),
		"elite_modifier": elite_modifier,
		"elite_label": _get_elite_modifier_label(elite_modifier),
		"spawn_edge": spawn_edge,
		"direction": _get_enemy_movement_frame(spawn_edge),
		"visual_state": "idle",
		"hit_flash": 0.0,
		"hit_visual_timer": 0.0,
		"attack_visual_timer": 0.0,
		"attack_warmup_timer": 0.0,
		"direction_lock_timer": 0.0,
		"velocity": Vector2.ZERO,
		"flight_heading": (player.position - position).angle(),
		"visual_rotation": (player.position - position).angle() + PI / 2.0,
		"fire_cooldown": 1.15 + float(next_id % 4) * 0.34,
	})
	if WeaponRegistry.CYCLES.has(str(definition.attack_behavior)):
		WeaponRegistry.ensure_cycle(enemies[-1], str(definition.attack_behavior))
	EnemyNavigation.initialize(enemies[-1], rng, _fleet_orbit_sign())
	if WeaponRegistry.CYCLES.has(str(definition.attack_behavior)):
		enemies[-1].fire_cooldown = rng.randf_range(0.5, float(WeaponRegistry.cycle(str(definition.attack_behavior)).reload))
	_mark_enemy_discovered(resolved_enemy_type_id)

func _get_regular_spawn_position(enemy_type_id: String) -> Dictionary:
	var bounds := _get_playfield_rect(get_viewport_rect().size)
	var stats := EnemyRegistry.get_stats(enemy_type_id, int(runState.wave))
	var edges := ["top", "right", "bottom", "left"]
	var edge: String = edges[rng.randi_range(0, 3)]
	var inset := float(stats.radius) * COMBAT_SPRITE_SCALE + 4.0
	var position := bounds.position + Vector2(rng.randf(), rng.randf()) * bounds.size
	if edge == "top":
		position.y = bounds.position.y - inset
	elif edge == "right":
		position.x = bounds.end.x + inset
	elif edge == "bottom":
		position.y = bounds.end.y + inset
	else:
		position.x = bounds.position.x - inset
	return {"edge": edge, "position": position}

func _enemy_is_visible(enemy: Dictionary) -> bool:
	return _get_playfield_rect(get_viewport_rect().size).grow(-float(enemy.radius)).has_point(enemy.position)

func _nearest_target() -> Dictionary:
	var nearest := {}
	var distance_limit := _stat("range") * _stat("range")
	for enemy in enemies:
		if float(enemy.hp) <= 0.0 or not _enemy_is_visible(enemy):
			continue
		var distance: float = player.position.distance_squared_to(enemy.position)
		if distance <= distance_limit:
			nearest = enemy
			distance_limit = distance
	return nearest

func _update_weapons(delta_ms: float) -> void:
	var cycle := _railgun_stats()
	var remaining := _tick_railgun_reload(delta_ms / 1000.0)
	if float(player.weapon.reload_timer) > 0.0: return
	var overshoot := maxf(0.0, remaining * 1000.0 - fire_timer)
	fire_timer = maxf(0.0, fire_timer - remaining * 1000.0)
	if fire_timer <= 0.000001 and _fire_at_nearest_enemy():
		player.weapon.ammo = maxi(0, int(player.weapon.ammo)-1)
		if int(player.weapon.ammo) == 0: player.weapon.reload_timer = float(cycle.reload)
		fire_timer = maxf(0.0, _get_weapon_fire_interval() - overshoot) if int(player.weapon.ammo) > 0 else 0.0
		if int(player.weapon.ammo) == 0: _tick_railgun_reload(overshoot / 1000.0)

func _fire_at_nearest_enemy() -> bool:
	var nearest := _nearest_target()
	if nearest.is_empty():
		return false
	var player_position: Vector2 = player.position

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
		var muzzle_position := player_position + direction * float(player.radius) + muzzle_offset
		var critical := _roll_critical(next_id)
		var bullet := WeaponRegistry.build_projectile(next_id, muzzle_position, shot_direction, _get_weapon_damage(), critical, _projectile_travel(muzzle_position,shot_direction))
		var stats := _railgun_stats()
		if critical: bullet.damage *= float(stats.crit_multiplier) / 2.0
		bullet.radius *= float(stats.width)
		bullet.hits_left = int(stats.hits)
		bullet.hit_ids = []
		bullet.fragments = int(stats.fragments)
		bullet.rampage = float(stats.rampage)
		bullets.append(bullet)
		_add_muzzle_flash(muzzle_position, shot_direction, critical)
		next_id += 1
	audio_events.emit(AudioEvents.SHOOT, { "source": "player", "weapon": WeaponRegistry.RAILGUN_ID })
	return true

func _get_weapon_fire_interval() -> float:
	return _stat("fire_rate")

func _get_weapon_damage() -> float:
	return float(_railgun_stats().damage)

func _get_weapon_shot_count() -> int:
	return int(_railgun_stats().shots)

func _get_weapon_spread() -> float:
	return 0.0

func _update_enemy_movement(delta: float) -> void:
	var active := enemies.filter(func(enemy): return EnemyNavigation.TYPES.has(str(enemy.type_id)))
	EnemyNavigation.update(active, player.position, _stat("range"), _get_playfield_rect(get_viewport_rect().size), _fleet_orbit_sign(), delta)
	for enemy in enemies:
		enemy.contact_cooldown = maxf(0.0, float(enemy.get("contact_cooldown",0.0))-delta)
		if not EnemyNavigation.TYPES.has(str(enemy.type_id)):
			enemy.velocity = _get_enemy_desired_direction(enemy,player.position)*float(enemy.speed)
			enemy.position += enemy.velocity*delta
		_update_enemy_visual_direction(enemy,enemy.velocity,delta)
		_update_enemy_visual_state(enemy,enemy.velocity)

func _get_enemy_desired_direction(enemy: Dictionary, player_position: Vector2) -> Vector2:
	if EnemyNavigation.TYPES.has(str(enemy.type_id)):
		EnemyNavigation.initialize(enemy, null, _fleet_orbit_sign())
		return EnemyNavigation.preferred_velocity(enemy,player_position,_stat("range"),_get_playfield_rect(get_viewport_rect().size),0.0).normalized()
	# Archived designs keep their historical fallback; they are not spawned.
	var direction: Vector2 = (player_position-enemy.position).normalized()
	match str(enemy.get("movement_behavior","chase")):
		"swarm": return direction.rotated(sin(background_time*3.1+float(enemy.id))*0.34)
		"charge": return direction.rotated(sin(background_time*5.2+float(enemy.id))*0.12)
		"hunter": return (direction+direction.orthogonal()*0.42).normalized()
	return direction

func _update_enemy_weapons(delta: float) -> void:
	if player.is_empty(): return
	for enemy in enemies:
		EnemyWeapons.update(self, enemy, delta)

func _fire_enemy_projectile(enemy: Dictionary) -> void:
	EnemyWeapons.fire(self, enemy)

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
		bullet.previous_position = bullet.position
		var distance := minf(float(bullet.remaining_distance), bullet.velocity.length() * delta)
		bullet.position += bullet.velocity.normalized() * distance
		bullet.remaining_distance = maxf(0.0, float(bullet.remaining_distance) - distance)
		bullet.life -= delta

	for projectile in enemy_projectiles:
		EnemyWeapons.move_projectile(self, projectile, delta)
	if bullets.size() > 140:
		bullets = bullets.slice(bullets.size() - 140, bullets.size())
	if enemy_projectiles.size() > 90:
		enemy_projectiles = enemy_projectiles.slice(enemy_projectiles.size() - 90, enemy_projectiles.size())

func _update_effects(delta: float) -> void:
	ShieldSystem.update(player, delta, _stat("shield_recharge"))

func _resolve_collisions() -> void:
	var removed_bullet_ids := {}
	var removed_enemy_projectile_ids := {}
	var removed_enemy_ids := {}

	var fragments: Array[Dictionary] = []
	for bullet in bullets:
		var start: Vector2 = bullet.get("previous_position", bullet.position)
		var end: Vector2 = bullet.position
		if not bullet.has("hit_ids"): bullet.hit_ids = []
		if not bullet.has("hits_left"): bullet.hits_left = 1
		var contacts: Array[Dictionary] = []
		for enemy in enemies:
			if removed_enemy_ids.has(enemy.id) or bullet.hit_ids.has(enemy.id) or not _enemy_is_visible(enemy): continue
			var fraction := WeaponRegistry.hit_fraction(start,end,enemy.position,float(enemy.radius)+float(bullet.radius))
			if fraction != INF: contacts.append({"fraction":fraction,"enemy":enemy})
		contacts.sort_custom(func(a,b): return a.fraction < b.fraction if a.fraction != b.fraction else a.enemy.id < b.enemy.id)
		for contact in contacts:
			var target: Dictionary = contact.enemy
			var impact := start.lerp(end,float(contact.fraction))
			var prior_hits: int = bullet.hit_ids.size()
			var damage := float(bullet.damage) * (1.0 + float(bullet.get("rampage",0.0))*mini(5,prior_hits))
			_apply_damage_to_enemy(target,damage,bool(bullet.get("critical",false)))
			bullet.hit_ids.append(target.id)
			bullet.hits_left = int(bullet.hits_left)-1
			target.hit_flash = ENEMY_DAMAGE_FLASH_SECONDS
			target.hit_visual_timer = ENEMY_DAMAGE_FLASH_SECONDS
			_add_rail_impact(impact,bullet.velocity.normalized(),bool(bullet.get("critical",false)),RailVisuals.is_fragment(bullet))
			audio_events.emit(AudioEvents.HIT,{"target":"enemy","critical":bool(bullet.get("critical",false))})
			if prior_hits == 0:
				var targets: Array = enemies.filter(func(enemy): return enemy.id != target.id and enemy.hp > 0 and not removed_enemy_ids.has(enemy.id) and _get_playfield_rect(get_viewport_rect().size).has_point(enemy.position))
				targets.sort_custom(func(a,b): return impact.distance_squared_to(a.position) < impact.distance_squared_to(b.position) if impact.distance_squared_to(a.position) != impact.distance_squared_to(b.position) else a.id < b.id)
				for index in range(int(bullet.get("fragments",0))):
					var direction: Vector2 = bullet.velocity.normalized().rotated((index-(int(bullet.fragments)-1)/2.0)*0.18)
					if not targets.is_empty(): direction = (targets[index % targets.size()].position-impact).normalized()
					var fragment := WeaponRegistry.build_projectile(next_id,impact,direction,damage*0.5,false,_projectile_travel(impact,direction))
					fragment.radius = 1.6
					fragment.is_fragment = true
					fragment.hit_ids = [target.id]
					fragment.hits_left = 1
					fragment.fragments = 0
					fragments.append(fragment)
					next_id += 1
			if target.hp <= 0:
				removed_enemy_ids[target.id] = true
				_grant_enemy_rewards(target)
				_add_enemy_death_explosion(target,Color("#f97316"))
			if target.hp > 0 or int(bullet.hits_left) <= 0:
				removed_bullet_ids[bullet.id] = true
				end = impact
				break
		if start.distance_squared_to(end) > 0.01:
			var fragment_visual := RailVisuals.is_fragment(bullet)
			var trace := EffectRegistry.make("rail_trace",RailVisuals.trace_start(start,end,fragment_visual))
			trace.is_fragment = fragment_visual
			trace.projectile_id = bullet.id
			trace.end = end
			trace.critical = bool(bullet.get("critical",false))
			# Replace the previous visual segment, including substeps at 10x speed.
			particles = particles.filter(func(effect): return effect.get("kind","") != "rail_trace" or effect.get("projectile_id",-1) != bullet.id)
			_append_effect(trace)
	bullets.append_array(fragments)

	for enemy in enemies:
		if removed_enemy_ids.has(enemy.id):
			continue

		if _circles_overlap(player.position, player.radius, enemy.position, enemy.radius):
			if float(enemy.contact_cooldown) <= 0.0:
				var impact := not bool(enemy.get("has_contacted", false))
				_apply_damage_to_player(_get_incoming_damage(float(enemy.contact_damage) * (FIRST_IMPACT_MULTIPLIER if impact else 1.0)), "IMPACT" if impact else "CONTACT", enemy.position, player.position - enemy.position)
				enemy.has_contacted = true
				enemy.contact_hits_in_pass = int(enemy.get("contact_hits_in_pass", 0)) + 1
				var definition: Dictionary = EnemyRegistry.get_definition(str(enemy.type_id))
				enemy.contact_cooldown = float(definition.base_stats.get("contact_interval", 1.0))
				if int(enemy.contact_hits_in_pass) >= 2 and not bool(enemy.get("contact_latched", false)):
					EnemyNavigation.restart_after_contact(enemy, _stat("range"))
			var away: Vector2 = enemy.position - player.position
			if away.length_squared() < 0.01:
				away = Vector2.RIGHT.rotated(float(enemy.id) * 2.4)
			enemy.position = player.position + away.normalized() * (float(player.radius) + float(enemy.radius) + 0.1)
	_separate_enemies()

	for projectile in enemy_projectiles:
		if removed_enemy_projectile_ids.has(projectile.id):
			continue

		var start: Vector2 = projectile.get("previous_position", projectile.position)
		var end: Vector2 = projectile.position
		var fraction := WeaponRegistry.hit_fraction(start, end, player.position, float(player.radius) + float(projectile.radius))
		if fraction != INF:
			end = start.lerp(end, fraction)
			_apply_damage_to_player(_get_incoming_damage(float(projectile.damage) * float(projectile.get("damage_multiplier", PROJECTILE_DAMAGE_MULTIPLIER))), "HIT", end, projectile.velocity)
			removed_enemy_projectile_ids[projectile.id] = true
			if projectile.get("weapon_id", "") == "boss_rocket":
				_append_effect(EffectRegistry.make("explosion", end, 22.0))
			audio_events.emit(AudioEvents.PLAYER_DAMAGE, {"source": "projectile"})
		if str(projectile.get("weapon_id", "")).ends_with("railgun") and start.distance_squared_to(end) > 0.01:
			var trace := EffectRegistry.make("enemy_trace", start)
			trace.end = end
			_append_effect(trace)

	enemies = enemies.filter(func(enemy): return not removed_enemy_ids.has(enemy.id))
	_remove_expired_projectiles(removed_bullet_ids)
	_remove_expired_enemy_projectiles(removed_enemy_projectile_ids)

	if player.hp <= 0:
		_end_run(true)

func _apply_damage_to_enemy(enemy: Dictionary, damage: float, critical := false) -> void:
	var before := float(enemy.hp)
	enemy.hp = maxf(0.0, before - damage)
	if before > float(enemy.hp):
		enemy_damage_numbers.append({"position":enemy.position,"amount":before-float(enemy.hp),"critical":critical,"life":0.65})
		if enemy_damage_numbers.size()>40: enemy_damage_numbers.pop_front()

func _apply_damage_to_player(damage: float, source := "HIT", impact := Vector2.INF, incoming := Vector2.ZERO) -> Dictionary:
	var before := float(player.hp)
	var loss := ShieldSystem.absorb(player, damage)
	if float(loss.shield) <= 0.0 and float(loss.hull) <= 0.0: return loss
	gunship.hit(loss, player.position, impact, incoming, source)
	if float(loss.shield) > 0.0:
		_add_damage_number(float(loss.shield), "SHIELD", Color("#73e4ff"))
	if float(loss.hull) > 0.0:
		hull_damage_trail = maxf(hull_damage_trail, before)
		hull_damage_timer = 0.7
		player_damage_flash = PLAYER_DAMAGE_FLASH_SECONDS
		_add_damage_number(float(loss.hull), source, Color("#ff8c4c"))
		_add_screen_shake(3.0 if source == "IMPACT" else 1.5)
	return loss

func _add_damage_number(amount: float, source: String, color: Color) -> void:
	for number in damage_numbers:
		if number.source == source and float(number.life) > 0.35:
			number.amount += amount
			return
	damage_numbers.append({"position": player.position, "amount": amount, "source": source, "color": color, "life": 0.65})
	if damage_numbers.size() > 4: damage_numbers.pop_front()

func _update_damage_feedback(delta: float) -> void:
	# Readability follows real time at every combat speed; menus freeze feedback too.
	player_damage_flash = maxf(0.0, player_damage_flash - delta)
	hull_damage_timer = maxf(0.0, hull_damage_timer - delta)
	if hull_damage_timer == 0.0:
		hull_damage_trail = move_toward(hull_damage_trail, float(player.hp), float(player.max_hp) * delta)
	for number in enemy_damage_numbers: number.life -= delta
	enemy_damage_numbers = enemy_damage_numbers.filter(func(number): return number.life>0)
	for number in damage_numbers: number.life -= delta
	damage_numbers = damage_numbers.filter(func(number): return number.life > 0.0)

func _game_speed() -> int:
	return ProfileStore.valid_speed(int(profile.get("settings", {}).get("gameSpeed", 1)))

func _grant_enemy_rewards(enemy: Dictionary) -> void:
	if bool(enemy.get("rewarded", false)):
		return
	enemy.rewarded = true
	var enemy_type_id := str(enemy.type_id)
	if int(cards.choices) < Cards.MAX_CHOICES: cards.xp = int(cards.xp) + int(Cards.XP.get(enemy_type_id, 0))
	if enemy_type_id == EnemyRegistry.BOSS_ID:
		cards.modules = int(cards.modules) + 1
		reward_dirty = true
	runState.kills = int(runState.kills) + 1
	runState.score = int(runState.score) + int(enemy.get("score_reward", 0))
	runState.cash = float(runState.cash) + float(enemy.cash_reward) * _stat("cash_bonus")
	runState.coinsEarned = float(runState.coinsEarned) + float(enemy.coin_reward) * _stat("coin_bonus")
	run_enemy_kills[enemy_type_id] = int(run_enemy_kills.get(enemy_type_id, 0)) + 1
	audio_events.emit(AudioEvents.ENEMY_DEATH, {"type_id": enemy_type_id})

func _sync_legacy_run_fields() -> void:
	kills = int(runState.kills)
	score = int(runState.score)
	elapsed = float(runState.elapsedSeconds)
	weapon_level = 1

func _remove_expired_projectiles(removed_bullet_ids: Dictionary) -> void:
	var size := get_viewport_rect().size
	bullets = bullets.filter(func(bullet):
		var position: Vector2 = bullet.position
		var in_bounds := position.x > -24.0 and position.x < size.x + 24.0 and position.y > -24.0 and position.y < size.y + 24.0
		return not removed_bullet_ids.has(bullet.id) and bullet.life > 0.0 and float(bullet.remaining_distance) > 0.0 and in_bounds
	)

func _remove_expired_enemy_projectiles(removed_projectile_ids: Dictionary) -> void:
	var size := get_viewport_rect().size
	enemy_projectiles = enemy_projectiles.filter(func(projectile):
		var position: Vector2 = projectile.position
		var in_bounds := position.x > -32.0 and position.x < size.x + 32.0 and position.y > -32.0 and position.y < size.y + 32.0
		return not removed_projectile_ids.has(projectile.id) and projectile.life > 0.0 and (in_bounds or projectile.get("weapon_id", "") == "boss_rocket")
	)

func _add_enemy_death_explosion(enemy: Dictionary, color: Color) -> void:
	var is_boss: bool = enemy.get("type_id", "") == EnemyRegistry.BOSS_ID
	var origin: Vector2 = enemy.position
	var height := float(_get_enemy_definition(str(enemy.type_id)).get("death_vfx_height", 82.0))
	if is_boss:
		for index in range(3):
			var offset := Vector2(-14.0 + index * 14.0, -12.0 + index * 10.0)
			_append_effect(EffectRegistry.make("explosion", origin + offset, 75.0, index * 0.15))
		_append_effect(EffectRegistry.make("boss_explosion", origin, height, 0.4))
	else:
		_append_effect(EffectRegistry.make("explosion", origin, height))
	for index in range(12 if is_boss else 5):
		var angle := index * 2.39996 + cosmetic_id * 0.17
		var debris := EffectRegistry.make("debris", origin, 1.0, 0.35 if is_boss else 0.03)
		debris.velocity = Vector2.from_angle(angle) * (25.0 + index * 3.0)
		debris.color = color
		debris.radius = 1.0 + index % 2
		_append_effect(debris)

func _add_hit_spark(origin: Vector2) -> void:
	_add_rail_impact(origin, Vector2.UP, false)

func _add_sprite_effect(origin: Vector2, texture_key: String, height: float, lifetime: float, rotation: float) -> void:
	_append_effect({"position": origin, "life": lifetime, "max_life": lifetime,
		"texture_key": texture_key, "height": height, "rotation": rotation,
		"layer": "front", "priority": 2, "delay": 0.0})

func _add_muzzle_flash(origin: Vector2, direction: Vector2, critical: bool) -> void:
	rail_direction = direction
	if not gunship.allow_weapon_pulse(): return
	rail_recoil = 1.0
	muzzle_flashes.append({
		"position": origin,
		"direction": direction.normalized(),
		"life": 0.075 if not critical else 0.11,
		"max_life": 0.075 if not critical else 0.11,
		"critical": critical,
	})
	if muzzle_flashes.size() > 16: muzzle_flashes.pop_front()

func _roll_critical(_seed: int) -> bool:
	return rng.randf() < float(_railgun_stats().crit)

func _add_screen_shake(amount: float) -> void:
	var settings: Dictionary = metaProgress.get("settings", {})
	if not bool(settings.get("screenShake", true)):
		return
	screen_shake = minf(1.0, screen_shake + amount * 0.025)

func _get_screen_shake_offset() -> Vector2:
	if screen_shake <= 0.0:
		return Vector2.ZERO
	var strength := screen_shake * 5.0
	return Vector2(
		sin(background_time * 77.0) * strength,
		cos(background_time * 91.0) * strength * 0.72
	)

func _get_enemy_accent_color(enemy: Dictionary) -> Color:
	var modifier := str(enemy.get("elite_modifier", ""))
	if modifier != "" and EnemyRegistry.ELITE_MODIFIERS.has(modifier):
		return EnemyRegistry.ELITE_MODIFIERS[modifier].aura
	var definition := EnemyRegistry.get_definition(str(enemy.get("type_id", VOID_DRONE_ID)))
	return definition.get("visual_color", UI_ORANGE)

func _get_elite_modifier_label(modifier: String) -> String:
	if modifier == "" or not EnemyRegistry.ELITE_MODIFIERS.has(modifier):
		return ""
	return str(EnemyRegistry.ELITE_MODIFIERS[modifier].label)

func _draw() -> void:
	var size := get_viewport_rect().size
	_draw_background(size)
	active_draw_offset = _get_screen_shake_offset()
	draw_set_transform(active_draw_offset, 0.0, Vector2.ONE)
	_draw_range()
	_draw_particles("back")
	_draw_bullets()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_player()
	_draw_muzzle_flashes()
	_draw_particles("front")
	_draw_damage_numbers()
	active_draw_offset = Vector2.ZERO
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_hud(size)
	_draw_wave_message(size)
	if status != "running": draw_rect(Rect2(Vector2.ZERO,size),Color(0.005,0.012,0.025,0.70))

func _draw_range() -> void:
	if player.is_empty():
		return
	var bounds := _get_playfield_rect(get_viewport_rect().size)
	var radius := _stat("range")
	# Clip each small arc segment to the existing playfield, without a second camera.
	for index in range(128):
		var a: Vector2 = player.position + Vector2.from_angle(TAU * index / 128.0) * radius
		var b: Vector2 = player.position + Vector2.from_angle(TAU * (index + 1) / 128.0) * radius
		if bounds.has_point(a) and bounds.has_point(b):
			draw_line(a, b, _with_alpha(Color("#7895a8"), 0.14), 0.75, true)

func _draw_damage_numbers() -> void:
	var font := get_theme_default_font()
	var bounds := _get_playfield_rect(get_viewport_rect().size)
	var line_height := 16.0 * ui_factor
	var base_y := clampf(float(player.position.y) + 26.0 * ui_factor, bounds.position.y + 24.0 * ui_factor, bounds.end.y - maxf(1.0, damage_numbers.size()) * line_height)
	for index in range(damage_numbers.size()):
		var number: Dictionary = damage_numbers[index]
		var amount := "%.1f" % float(number.amount)
		var caption: String = "-%s" % amount
		var point := Vector2(float(player.position.x) + 22.0 * ui_factor, base_y + index * line_height)
		point.x = clampf(point.x, bounds.position.x + 6, maxf(6, bounds.end.x - 48 * ui_factor))
		point.y = clampf(point.y, bounds.position.y + 24 * ui_factor, bounds.end.y - 6)
		var color: Color = number.get("color", Color("#ff8c4c"))
		color.a = minf(1.0, float(number.life) * 3.0)
		draw_string_outline(font, point, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, ceili(12 * ui_factor), 2, Color(0.02, 0.02, 0.04, color.a))
		draw_string(font, point, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, ceili(12 * ui_factor), color)

	for number in enemy_damage_numbers:
		var point: Vector2 = number.position+Vector2(7,-12-(0.65-float(number.life))*18)*ui_factor
		var color := Color("#ffe260") if number.critical else Color.WHITE
		color.a = minf(1,float(number.life)*4)
		var caption := "%.0f" % float(number.amount) if float(number.amount)>=10 else "%.1f" % float(number.amount)
		draw_string_outline(font,point,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,ceili(11*ui_factor),2,Color(0,0,0,color.a))
		draw_string(font,point,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,ceili(11*ui_factor),color)

func _draw_background(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#030a13"))
	if status == "dead" and run_complete_background != null:
		_draw_texture_cover(run_complete_background, Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.88))
		return
	# Only a distant star field and one soft nebula; no combat-obscuring foreground.
	if background_textures.size() >= 2:
		_draw_scrolling_layers([background_textures[0]], [{"speed": 3.0, "opacity": 0.52}], size)
		_draw_scrolling_layers([background_textures[1]], [{"speed": 6.0, "opacity": 0.11}], size)

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

func _draw_scrolling_layers(textures: Array, layer_defs: Array, size: Vector2) -> void:
	var layer_count := mini(textures.size(), layer_defs.size())
	for index in range(layer_count):
		var texture: Texture2D = textures[index]
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
	if player.is_empty() or status == "menu": return
	var font := get_theme_default_font()
	var f := ui_factor
	var hud := CompactUI.hud_layout(size,f,hud_safe)
	var area: Rect2 = hud.area
	var x := area.position.x+8*f
	var y := area.position.y
	var left_width := minf(150*f,area.size.x*0.34)
	# Open header: thin bars instead of a framed panel.
	_draw_icon_text(font,Vector2(x,y+12*f),"%.0f / %.0f" % [player.hp,player.max_hp],HORIZONTAL_ALIGNMENT_LEFT,left_width,ceili(11*f),UI_TEAL)
	_draw_capsule(Rect2(x,y+16*f,left_width,3*f),_with_alpha(UI_TEAL,0.18))
	_draw_capsule(Rect2(x,y+16*f,left_width*clampf(float(player.hp)/player.max_hp,0,1),3*f),UI_TEAL)
	_draw_icon_text(font,Vector2(x,y+29*f),"%.0f shield" % player.shield,HORIZONTAL_ALIGNMENT_LEFT,left_width,ceili(10*f),UI_CYAN)
	_draw_capsule(Rect2(x,y+33*f,left_width,2*f),_with_alpha(UI_CYAN,0.15))
	_draw_capsule(Rect2(x,y+33*f,left_width*clampf(float(player.shield)/maxf(1,player.max_shield),0,1),2*f),UI_CYAN)
	var level_x := area.end.x-(260 if hud.short else 62)*f
	_draw_icon_text(font,Vector2(level_x,y+12*f),"MAX" if int(cards.choices)>=Cards.MAX_CHOICES else "Lv.%d" % (int(cards.choices)+1),HORIZONTAL_ALIGNMENT_LEFT,58*f,ceili(11*f),UI_CYAN)
	_draw_capsule(Rect2(level_x,y+19*f,52*f,3*f),_with_alpha(UI_CYAN,0.18))
	_draw_capsule(Rect2(level_x,y+19*f,52*f*clampf(float(cards.xp)/Cards.threshold(cards),0,1),3*f),UI_CYAN)
	var money_y := y+(44 if hud.short else 51)*f
	var resources := "$ %s ◈ %s" % [_money(runState.cash),_money(runState.coinsEarned)]
	if hud.short: resources += " ▣ %d" % cards.modules
	_draw_icon_text(font,Vector2(x,money_y),resources,HORIZONTAL_ALIGNMENT_LEFT,(area.size.x-190*f) if not hud.short else 280*f,ceili(10*f),Color("#9bafbf"))
	if not hud.short: _draw_icon_text(font,Vector2(x,y+64*f),"▣ %d" % cards.modules,HORIZONTAL_ALIGNMENT_LEFT,90*f,ceili(10*f),Color("#9bafbf"))
	if save_error:
		_draw_icon_text(font,Vector2(x,y+hud.top+12*f),"SAVE FAILED · Pause to retry",HORIZONTAL_ALIGNMENT_LEFT,area.size.x-16*f,ceili(12*f),UI_ORANGE)

func _draw_particles(layer := "back") -> void:
	for particle in particles:
		if particle.get("layer", "back") != layer or float(particle.get("delay", 0.0)) > 0.0: continue
		var progress := 1.0 - clampf(float(particle.life) / maxf(0.001, float(particle.get("max_life", PARTICLE_LIFETIME))), 0.0, 1.0)
		var alpha := 1.0 - progress
		var kind := str(particle.get("kind", ""))
		if kind in ["explosion", "boss_explosion"]:
			if explosion_frames.size() == 8:
				_draw_centered_texture(explosion_frames[EffectRegistry.frame_index(progress)], particle.position, particle.height, 0.0, Color(1, 1, 1, 1))
		elif kind == "enemy_trace":
			draw_line(particle.position, particle.end, Color(1, 0.24, 0.04, 0.45 * alpha), 3.0, true)
			draw_line(particle.position, particle.end, Color(1, 0.95, 0.85, 0.95 * alpha), 0.9, true)
		elif kind == "enemy_muzzle":
			var direction: Vector2 = particle.direction
			draw_line(particle.position - direction * 2, particle.position + direction * 7 * alpha, Color(1, 0.92, 0.78, alpha), 1.7, true)
			draw_circle(particle.position, 3 * alpha, Color(1, 0.32, 0.06, alpha * 0.7))
		elif kind == "rail_trace":
			var fragment_visual := bool(particle.get("is_fragment",false))
			var direction: Vector2 = (particle.end-particle.position).normalized()
			var length: float = particle.position.distance_to(particle.end)
			var thickness := 3.0 if fragment_visual else 6.0
			var texture := rail_visuals.texture("fragment" if fragment_visual else "pulse",progress)
			draw_set_transform(particle.end,direction.angle())
			draw_texture_rect(texture,Rect2(-length,-thickness/2,length,thickness),false,Color(1,1,1,alpha))
			draw_set_transform(Vector2.ZERO)
		elif kind == "rail_impact":
			var fragment_visual := bool(particle.get("is_fragment",false))
			var texture := rail_visuals.texture("fragment_impact" if fragment_visual else "impact",progress)
			_draw_centered_texture(texture,particle.position,5.0 if fragment_visual else 11.0,particle.direction.angle(),Color(1,1,1,alpha))
		elif particle.has("texture_key"):
			_draw_centered_texture(vfx_textures.get(particle.texture_key), particle.position, particle.height, particle.rotation, Color(1, 1, 1, alpha))
		else:
			var color: Color = particle.get("color", Color.ORANGE)
			color.a = alpha
			draw_circle(particle.position, particle.get("radius", 1.0), color)

func _draw_bullets() -> void:
	# Segment traces are retained briefly after collision; no sprite extends beyond impact.
	pass

func _draw_enemy_projectiles() -> void:
	for projectile in enemy_projectiles:
		var velocity: Vector2 = projectile.velocity
		var direction: Vector2 = velocity.normalized()
		if str(projectile.get("weapon_id", "")).ends_with("railgun"): continue
		if projectile.get("weapon_id", "") == "boss_rocket":
			var tip: Vector2 = projectile.position + direction * 5
			var tail: Vector2 = projectile.position - direction * 4
			var side := direction.orthogonal() * 2.2
			draw_colored_polygon(PackedVector2Array([tip, tail + side, tail - side]), Color("#c7cdd2"))
			draw_line(tail, tail - direction * (5 + 2 * sin(visual_time * 35)), Color(1, 0.3, 0.06, 0.85), 2.0, true)
			draw_line(tail, tail - direction * 3, Color(1, 0.94, 0.6), 0.8, true)
			continue
		var trail_start: Vector2 = projectile.position - direction * 14.0 * EFFECT_SCALE
		draw_line(trail_start, projectile.position, Color(1.0, 0.16, 0.05, 0.18), 3.0 * EFFECT_SCALE)
		draw_line(trail_start, projectile.position, Color(1.0, 0.76, 0.42, 0.42), 1.0 * EFFECT_SCALE)
		draw_circle(projectile.position, projectile.radius + 4.0 * EFFECT_SCALE, Color(1.0, 0.14, 0.04, 0.09))
		draw_circle(projectile.position, 2.5, Color("#ffad55"))
		draw_circle(projectile.position, 1.0, Color("#fff4c4"))

func _draw_muzzle_flashes() -> void:
	for flash in muzzle_flashes:
		var progress := 1.0-clampf(float(flash.life)/maxf(0.01,float(flash.max_life)),0,1)
		var texture := rail_visuals.texture("muzzle",progress)
		_draw_centered_texture(texture,flash.position,9.0,flash.direction.angle(),Color(1,1,1,1.0-progress))

func _draw_enemies() -> void:
	var ordered_enemies := enemies.duplicate()
	ordered_enemies.sort_custom(_enemy_draws_before)
	for enemy in ordered_enemies:
		var enemy_type_id: String = str(enemy.get("type_id", VOID_DRONE_ID))
		var texture_set: Dictionary = enemy_textures.get(enemy_type_id, enemy_textures.get(VOID_DRONE_ID, {}))
		var enemy_direction := "up"
		var enemy_state := str(enemy.get("visual_state", "thrust"))
		var primary_state := _get_enemy_primary_sprite_state(enemy, enemy_state)
		var texture_key := primary_state + "-" + enemy_direction
		var texture: Texture2D = texture_set.get(texture_key, texture_set.get("thrust-" + enemy_direction, texture_set.get("idle-down")))
		var definition := _get_enemy_definition(enemy_type_id)
		var visual_canvas_height: float = float(definition.get("visual_canvas_height", float(enemy.radius) / COMBAT_SPRITE_SCALE * 6.0)) * COMBAT_SPRITE_SCALE
		var flash: float = clampf(float(enemy.get("hit_flash", 0.0)) / ENEMY_DAMAGE_FLASH_SECONDS, 0.0, 1.0)
		var attack_charge: float = _get_enemy_attack_charge(enemy)
		var pulse: float = 0.5 + sin(visual_time * 2.8 + float(enemy.id) * 0.37) * 0.5
		if flash > 0.0 or attack_charge > 0.0:
			_draw_enemy_void_aura(enemy, flash, attack_charge, pulse)
		var base_alpha: float = 0.95 + flash * 0.05
		var tint := Color(1.0, 1.0 - flash * 0.18, 1.0 - flash * 0.35, clampf(base_alpha, 0.90, 1.0))
		var height := visual_canvas_height
		if enemy_type_id == EnemyRegistry.BOSS_ID:
			_draw_boss(enemy, height, tint)
		elif texture:
			if enemy_type_id in ["void_drone", "red_scout", "void_tank", "ranged_shooter"]:
				_draw_enemy_engines(enemy, height)
			_draw_centered_texture(texture, enemy.position, height, _enemy_visual_rotation(enemy), tint)
		else:
			_draw_procedural_enemy(enemy, definition, flash, attack_charge, pulse)
		_draw_enemy_attack_telegraph(enemy, attack_charge)
		if flash > 0.0:
			draw_circle(enemy.position, enemy.radius * 0.86, Color(1, 0.58, 0.38, 0.08 * flash))
		_draw_enemy_core(enemy, flash, attack_charge, pulse)
		_draw_enemy_hp_feedback(enemy)

func _enemy_draws_before(a: Dictionary, b: Dictionary) -> bool:
	var layer_a := int(a.get("flight_layer", 0))
	var layer_b := int(b.get("flight_layer", 0))
	if layer_a != layer_b:
		return layer_a < layer_b
	return int(a.get("id", 0)) < int(b.get("id", 0))

func _get_enemy_primary_sprite_state(enemy: Dictionary, visual_state: String) -> String:
	if visual_state == "idle":
		return "idle"
	var velocity: Vector2 = enemy.get("velocity", Vector2.ZERO)
	if velocity.length_squared() <= 9.0:
		return "idle"
	return "thrust"

func _draw_enemy_void_aura(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var radius: float = enemy.radius
	var aura := _get_enemy_accent_color(enemy)
	draw_circle(enemy.position, radius * 1.10, _with_alpha(aura, 0.018 + pulse * 0.010 + attack_charge * 0.020 + flash * 0.034))
	if str(enemy.get("elite_modifier", "")) != "":
		draw_circle(enemy.position, radius * 1.72, _with_alpha(aura, 0.032 + pulse * 0.018))
		draw_arc(enemy.position, radius * 1.92, background_time * 1.8, background_time * 1.8 + PI * 1.35, 24, _with_alpha(aura, 0.45), 1.4)
	if attack_charge > 0.08:
		draw_arc(enemy.position, radius * 1.32, -PI * 0.22, PI * 0.82, 18, Color(1.0, 0.36, 0.12, attack_charge * 0.12), 0.75)

func _draw_procedural_enemy(enemy: Dictionary, definition: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var color: Color = definition.get("visual_color", UI_ORANGE)
	var radius: float = float(enemy.radius)
	var direction := _get_enemy_forward_direction(enemy)
	var side := Vector2(-direction.y, direction.x)
	var nose: Vector2 = enemy.position + direction * radius * 1.15
	var left: Vector2 = enemy.position - direction * radius * 0.78 + side * radius * 0.76
	var right: Vector2 = enemy.position - direction * radius * 0.78 - side * radius * 0.76
	var tail: Vector2 = enemy.position - direction * radius * 1.05
	draw_colored_polygon(PackedVector2Array([nose, left, tail, right]), _with_alpha(color, 0.46 + flash * 0.18))
	draw_polyline(PackedVector2Array([nose, left, tail, right, nose]), _with_alpha(Color.WHITE, 0.26 + flash * 0.32), 1.1)
	draw_circle(enemy.position, radius * 0.42, _with_alpha(color, 0.28 + pulse * 0.10 + attack_charge * 0.12))
	if str(definition.get("archetype", "")) == "swarm":
		draw_circle(enemy.position + side * radius * 0.42, radius * 0.20, _with_alpha(UI_CYAN, 0.55))
	if str(enemy.get("elite_modifier", "")) != "":
		draw_string(get_theme_default_font(), enemy.position + Vector2(-radius * 1.4, -radius * 2.4), str(enemy.get("elite_label", "")), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.8, 8, _get_enemy_accent_color(enemy))

func _draw_enemy_core(enemy: Dictionary, flash: float, attack_charge: float, pulse: float) -> void:
	var core_radius: float = float(enemy.radius) * (0.08 + pulse * 0.018 + attack_charge * 0.035)
	var core_alpha: float = 0.16 + pulse * 0.06 + flash * 0.16 + attack_charge * 0.12
	draw_circle(enemy.position, float(enemy.radius) * 0.22, Color(1.0, 0.05, 0.03, 0.030 + attack_charge * 0.035))
	draw_circle(enemy.position, core_radius, Color(1.0, 0.26, 0.10, clampf(core_alpha, 0.0, 0.42)))
	draw_circle(enemy.position, maxf(1.1, core_radius * 0.30), Color(1.0, 0.82, 0.56, 0.20 + flash * 0.14))

func _draw_enemy_attack_telegraph(enemy: Dictionary, attack_charge: float) -> void:
	var id := EnemyWeapons.weapon_id(enemy)
	if not WeaponRegistry.CYCLES.has(id): return
	var direction := EnemyWeapons.aim(self, enemy)
	var pivot := EnemyWeapons.pivot(self, enemy)
	var origin := EnemyWeapons.origin(self, enemy)
	var reloading := float(enemy.get("reload_timer", 0.0)) > 0.0
	if id != "boss_rocket":
		# Small independent turret; the hull keeps following its flight direction.
		var recoil := minf(1.0, float(enemy.get("attack_visual_timer", 0.0)) / ENEMY_ATTACK_VISUAL_SECONDS)
		draw_circle(pivot, 2.4, Color("#28343e"))
		draw_line(pivot, origin - direction * recoil, Color("#8d9ba5"), 2.1, true)
		draw_line(pivot, origin - direction * recoil, Color(1, 0.33, 0.1, 0.15 if reloading else 0.5 + attack_charge * 0.4), 0.65, true)
	if float(enemy.get("attack_warmup_timer", 0.0)) <= 0.0: return
	if id == "boss_rocket":
		draw_arc(origin, 3.0 + attack_charge * 2, 0, TAU, 16, Color(1, 0.35, 0.08, 0.3 + attack_charge * 0.5), 1.0, true)
	else:
		draw_circle(origin, 1.0 + attack_charge * 1.5, Color(1, 0.6, 0.3, 0.4 + attack_charge * 0.5))

func _draw_enemy_hp_feedback(enemy: Dictionary) -> void:
	var hp_percent: float = clampf(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)), 0.0, 1.0)
	if enemy.type_id != EnemyRegistry.BOSS_ID and hp_percent >= 0.98 and float(enemy.get("hit_flash", 0.0)) <= 0.0:
		return

	var is_boss: bool = enemy.type_id == EnemyRegistry.BOSS_ID
	var bar_width: float = 148.0 if is_boss else float(enemy.radius) * 2.2
	var rect := Rect2(enemy.position + Vector2(-bar_width / 2.0, -float(enemy.radius) * 2.15), Vector2(bar_width, 5.0 if is_boss else 4.0))
	if is_boss:
		var bounds := _get_playfield_rect(get_viewport_rect().size)
		rect.position.x = clampf(rect.position.x, bounds.position.x + 4.0, bounds.end.x - bar_width - 4.0)
		rect.position.y = clampf(rect.position.y, bounds.position.y + 28.0, bounds.end.y - 12.0)
		draw_string(get_theme_default_font(), rect.position - Vector2(0, 5), "DREADNOUGHT  %d%%" % ceili(hp_percent * 100.0), HORIZONTAL_ALIGNMENT_CENTER, bar_width, 13, Color("#ffd6a3"))
	draw_rect(rect.grow(1.0), Color(0.0, 0.0, 0.0, 0.65))
	draw_rect(rect, Color(0.28, 0.03, 0.08, 0.72))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * hp_percent, rect.size.y)), UI_ORANGE if is_boss or hp_percent < 0.35 else UI_MAGENTA)
	if int(enemy.get("max_shield", 0)) > 0 and int(enemy.get("shield", 0)) > 0:
		var shield_percent := clampf(float(enemy.shield) / maxf(1.0, float(enemy.max_shield)), 0.0, 1.0)
		var shield_rect := Rect2(rect.position + Vector2(0.0, -5.0), Vector2(rect.size.x, 2.0))
		draw_rect(shield_rect, _with_alpha(UI_CYAN, 0.22))
		draw_rect(Rect2(shield_rect.position, Vector2(shield_rect.size.x * shield_percent, shield_rect.size.y)), _with_alpha(UI_CYAN, 0.82))

func _draw_player() -> void:
	gunship.draw(self)

func _draw_lcars_block(rect: Rect2, color: Color, alpha := 1.0) -> void:
	draw_rect(rect, _with_alpha(color, alpha))

func _update_card_notice(delta: float) -> void:
	if app_backgrounded or wave_message_timer>0: return
	card_notice_timer = maxf(0,card_notice_timer-delta)
	if card_notice_timer<=0 and not card_notices.is_empty():
		card_notice = card_notices.pop_front()
		card_notice_timer = 3.5

func _draw_card_notice(size: Vector2) -> void:
	if card_notice_timer<=0: return
	var hud := CompactUI.hud_layout(size,ui_factor,hud_safe)
	var width := minf(340*ui_factor,hud.area.size.x-16*ui_factor)
	var rect := Rect2(hud.area.get_center().x-width/2,hud.area.position.y+hud.top+8*ui_factor,width,64*ui_factor)
	_draw_glass_panel(rect,Color("#80d9e8"),"",0.65)
	draw_string(get_theme_default_font(),rect.position+Vector2(8,14)*ui_factor,"AUTO CARDS · EQUIPPED",HORIZONTAL_ALIGNMENT_LEFT,-1,ceili(10*ui_factor),Color("#80d9e8"))
	var font := get_theme_default_font()
	var lines := TextParagraph.new()
	lines.add_string(card_notice,font,ceili(12*ui_factor))
	lines.width = rect.size.x-16*ui_factor
	lines.draw(get_canvas_item(),rect.position+Vector2(8,22)*ui_factor,UI_TEXT)

func _draw_wave_message(size: Vector2) -> void:
	if status != "running":
		return
	if wave_message_timer <= 0.0 or wave_message == "":
		_draw_card_notice(size)
		return

	var alpha := clampf(wave_message_timer / 0.35, 0.0, 1.0)
	var rect_width := minf(220.0 * ui_factor, size.x - 48.0)
	var rect := Rect2((size.x - rect_width) / 2.0, 74.0 * ui_factor + hud_safe.y, rect_width, 24.0 * ui_factor)
	var accent := UI_ORANGE if wave_message.begins_with("BOSS") else UI_TEAL
	_draw_glass_panel(rect, accent, "", 0.18 * alpha)
	_draw_lcars_block(Rect2(rect.position.x + 12.0, rect.position.y, rect.size.x * 0.3, 3.0), accent, 0.8 * alpha)
	draw_string(get_theme_default_font(), rect.position + Vector2(8, 16 * ui_factor), wave_message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, ceili(11 * ui_factor), _with_alpha(UI_TEXT, alpha))

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

func _draw_capsule(rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0: return
	var radius := minf(rect.size.x, rect.size.y) / 2.0
	draw_rect(Rect2(rect.position + Vector2(radius, 0), Vector2(maxf(0.0, rect.size.x - radius * 2.0), rect.size.y)), color)
	draw_circle(rect.position + Vector2(radius, rect.size.y / 2.0), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x - radius, rect.size.y / 2.0), radius, color)

func _draw_scanlines(size: Vector2) -> void:
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018), 1.0)

func _draw_centered_texture(texture: Texture2D, center: Vector2, height: float, rotation := 0.0, modulate := Color.WHITE) -> void:
	if texture == null:
		return

	var width := height * float(texture.get_width()) / maxf(1.0, float(texture.get_height()))
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-width / 2.0, -height / 2.0), Vector2(width, height)), false, modulate)
	draw_set_transform(active_draw_offset, 0.0, Vector2.ONE)

func _load_enemy_texture_set(enemy_type_id: String) -> Dictionary:
	var frames := {}
	for state in ENEMY_FRAME_STATES:
		for direction in ENEMY_FRAME_DIRECTIONS:
			var frame_key: String = str(state) + "-" + str(direction)
			var path := "res://assets/enemies/" + enemy_type_id + "/" + frame_key + ".png"
			if not ResourceLoader.exists(path) and not FileAccess.file_exists(path): path = "res://assets/enemies/" + enemy_type_id + "/thrust-" + str(direction) + ".png"
			frames[frame_key] = _load_png_texture(path)
	return frames

func _load_enemy_textures_from_registry() -> void:
	enemy_textures = {}
	for enemy_type_id in EnemyRegistry.get_definitions().keys():
		var definition: Dictionary = EnemyRegistry.get_definition(str(enemy_type_id))
		var asset_key := str(definition.get("asset_key", ""))
		if asset_key == "" or str(definition.status) != "active":
			continue
		enemy_textures[str(enemy_type_id)] = _load_enemy_texture_set(asset_key)

func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture

	var image := Image.new()
	if image.load(path) != OK:
		return null

	return ImageTexture.create_from_image(image)

func _get_player_max_hp() -> float:
	return _stat("max_hp")

func _get_incoming_damage(raw_damage: float) -> float:
	# Never inflate a newly fractional weapon hit up to one whole damage point.
	return maxf(minf(1.0, raw_damage), raw_damage * (1.0 - _stat("armor")))

func _mark_enemy_discovered(enemy_type_id: String) -> void:
	if not run_discovered_enemies.has(enemy_type_id):
		run_discovered_enemies.append(enemy_type_id)
	# Codex discovery persists immediately so a later run can show this enemy in
	# full-preparation Wave Intel, even before it can spawn in that run.
	var discovered: Array = metaProgress.get("discoveredEnemies", []).duplicate()
	if not discovered.has(enemy_type_id):
		discovered.append(enemy_type_id)
		metaProgress.discoveredEnemies = discovered
		profile.discoveredEnemies = discovered
		if status in ["running", "paused"]:
			_save_run()
		else:
			profile_store.save_profile(profile)

func _is_enemy_discovered(enemy_type_id: String) -> bool:
	var discovered: Array = metaProgress.get("discoveredEnemies", [])
	return discovered.has(enemy_type_id)

func _get_enemy_total_kills(enemy_type_id: String) -> int:
	var total_kills: Dictionary = metaProgress.get("enemyKills", {})
	return int(total_kills.get(enemy_type_id, 0)) + (0 if run_recorded else int(run_enemy_kills.get(enemy_type_id, 0)))

func _get_codex_preview(enemy_id: String, definition: Dictionary) -> Texture2D:
	if not codex_previews.has(enemy_id):
		var source := _load_png_texture("res://assets/enemies/%s/preview.png" % str(definition.get("asset_key", "")))
		if source != null:
			# Portrait cropping is strictly for UI; the gameplay sprite keeps its fixed canvas.
			var portrait := AtlasTexture.new()
			portrait.atlas = source
			portrait.region = Rect2(source.get_image().get_used_rect()).grow(12).intersection(Rect2(Vector2.ZERO, source.get_size()))
			codex_previews[enemy_id] = portrait
		else:
			codex_previews[enemy_id] = null
	return codex_previews[enemy_id]

func _format_stat_value(value: float) -> String:
	return str(int(roundi(value))) if is_equal_approx(value, roundf(value)) else "%.1f" % value

func _enemy_projectile_damage(definition: Dictionary, stats: Dictionary) -> float:
	var behavior := str(definition.get("attack_behavior", ""))
	if not WeaponRegistry.CYCLES.has(behavior):
		return 0.0
	var cycle := WeaponRegistry.cycle(behavior)
	var base_stats: Dictionary = definition.get("base_stats", {})
	var base_contact := maxf(0.001, float(base_stats.get("contact_damage", 0.0)))
	return float(cycle.get("damage", 0.0)) * float(stats.get("contact_damage", 0.0)) / base_contact * PROJECTILE_DAMAGE_MULTIPLIER

func _enemy_weapon_line(definition: Dictionary, stats: Dictionary) -> String:
	var behavior := str(definition.get("attack_behavior", ""))
	if not WeaponRegistry.CYCLES.has(behavior):
		return ""
	var cycle := WeaponRegistry.cycle(behavior)
	var label := "ROCKET" if behavior == "boss_rocket" else "RAILGUN"
	return "%s HIT %s  ·  SALVO %d  ·  RELOAD %.1fs" % [label, _format_stat_value(_enemy_projectile_damage(definition, stats)), int(cycle.get("magazine", 1)), float(cycle.get("reload", 0.0))]

func _enemy_wave_stat_lines(definition: Dictionary, stats: Dictionary, detailed := false) -> String:
	var base: Dictionary = definition.get("base_stats", {})
	var current_hull := _format_stat_value(float(stats.get("hp", 0.0)))
	var current_hit := _format_stat_value(float(stats.get("contact_damage", 0.0)))
	var first_impact := _format_stat_value(float(stats.get("contact_damage", 0.0)) * FIRST_IMPACT_MULTIPLIER)
	var speed := _format_stat_value(float(stats.get("speed", 0.0)))
	var weapon := _enemy_weapon_line(definition, stats)
	if not detailed:
		var compact := "HULL %s   IMPACT %s   SPEED %s" % [current_hull, current_hit, speed]
		return compact + ("\n" + weapon if weapon != "" else "")
	var lines := [
		"HULL  %s → %s" % [_format_stat_value(float(base.get("hp", 0.0))), current_hull],
		"CONTACT  %s → %s   ·   FIRST IMPACT %s" % [_format_stat_value(float(base.get("contact_damage", 0.0))), current_hit, first_impact],
		"SPEED  %s  ·  FIXED" % speed,
		"CONTACT CADENCE  %.2fs" % float(base.get("contact_interval", 1.0)),
	]
	if weapon != "": lines.append(weapon)
	return "\n".join(lines)

func _wave_intel_table_row(definition: Dictionary, wave: int, detailed: bool) -> Dictionary:
	var enemy_id := str(definition.get("id", ""))
	var stats: Dictionary = definition.get("stats", EnemyRegistry.get_stats(enemy_id, wave))
	var base: Dictionary = definition.get("base_stats", {})
	var guaranteed := bool(definition.get("guaranteed_boss", false))
	var encountered_only := bool(definition.get("encountered_only", false))
	var spawn := "BOSS" if guaranteed else ("ENCOUNTERED" if encountered_only else "%.0f%%" % (float(definition.get("spawn_chance", 0.0)) * 100.0))
	var hull := _format_stat_value(float(stats.get("hp", 0.0)))
	var hit := _format_stat_value(float(stats.get("contact_damage", 0.0)))
	var speed := _format_stat_value(float(stats.get("speed", 0.0)))
	var shot := "—"
	if str(definition.get("attack_behavior", "")) in WeaponRegistry.CYCLES:
		shot = _format_stat_value(_enemy_projectile_damage(definition, stats))
	var values := [spawn, hull, hit, speed] if not detailed else [
		"%s/%s" % [_format_stat_value(float(base.get("hp", 0.0))), hull],
		"%s/%s" % [_format_stat_value(float(base.get("contact_damage", 0.0))), hit],
		speed,
		shot,
	]
	return {
		"enemy_name": str(definition.get("name", "UNKNOWN CONTACT")),
		"preview": _get_codex_preview(enemy_id, definition),
		"role": str(definition.get("role", "Unknown")),
		"boss": guaranteed,
		"values": values,
		"action": "wave_enemy:" + enemy_id,
	}

func _get_wave_intel_roster(wave: int) -> Array[Dictionary]:
	var roster := EnemyRegistry.get_wave_roster(wave)
	var listed := {}
	for entry in roster:
		listed[str(entry.id)] = true
	if wave % 10 != 0 and _is_enemy_discovered(EnemyRegistry.BOSS_ID):
		var boss := EnemyRegistry.get_definition(EnemyRegistry.BOSS_ID).duplicate(true)
		boss.stats = EnemyRegistry.get_stats(EnemyRegistry.BOSS_ID, maxi(1, wave))
		boss.spawn_chance = -1.0
		boss.guaranteed_boss = true
		roster.append(boss)
		listed[EnemyRegistry.BOSS_ID] = true
	for id in EnemyRegistry.get_definitions():
		var enemy_id := str(id)
		var definition := EnemyRegistry.get_definition(enemy_id)
		if definition.status != "active" or listed.has(enemy_id) or not _is_enemy_discovered(enemy_id):
			continue
		var encountered := definition.duplicate(true)
		encountered.stats = EnemyRegistry.get_stats(enemy_id, maxi(1, wave))
		encountered.spawn_chance = 0.0
		encountered.encountered_only = true
		roster.append(encountered)
	return roster

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
	if not is_instance_valid(overlay): return
	var size := get_viewport_rect().size
	if size == last_layout_size:
		if overlay.size != overlay_target_size: overlay.size = overlay_target_size
		return
	last_layout_size = size
	var screen_scale := get_viewport().get_stretch_transform().get_scale().x
	if OS.has_feature("web"):
		screen_scale = float(JavaScriptBridge.eval("window.innerWidth",true))/maxf(1,size.x)
	ui_factor = 1.0/maxf(0.1,screen_scale)
	hud_safe = _hud_safe_area(ui_factor)
	var f := ui_factor
	# Card choices use the CSS viewport width so mobile web viewports stack cards.
	overlay.wide_cards = size.x / maxf(0.1, f) >= 600.0
	overlay.rail_ui_factor = f
	overlay.set_ui_factor(f)
	for control in [upgrades_control,pause_control,auto_control,speed_control,auto_cards_control,build_control,wave_control]:
		control.custom_minimum_size.y = ceil(44*f)
		control.add_theme_font_size_override("font_size",ceili(12*f))
	wave_control.add_theme_font_size_override("font_size",ceili(14*f))
	var rail_view := status=="card_choice" or menu_view in ["railgun","railgun_catalog","railgun_detail","build"]
	# All menus fill the safe viewport height on mobile and desktop/web.
	var safe_origin := Vector2(hud_safe.x,hud_safe.y) + Vector2.ONE * 6*f
	var safe_size := size - Vector2(hud_safe.x+hud_safe.z,hud_safe.y+hud_safe.w) - Vector2.ONE * 12*f
	# Bound the panel against the actual viewport. The logical stretch factor can
	# otherwise make the railgun panel wider than a small web/mobile viewport.
	var available_width := maxf(1.0, safe_size.x)
	var width := minf((624.0 if rail_view else 480.0)*f,available_width)
	var choice_view := status == "card_choice"
	# Keep a three-card choice grid inside the panel, including its panel padding,
	# grid gaps, card borders and card-content insets.
	var choice_grid_width := maxf(1.0,width - 12.0*f)
	overlay.choice_card_art_size = maxf(1.0,floor((choice_grid_width - 8.0*f)/3.0) - 4.0*f)
	# The five loadout slots use the same total width as the choice grid.
	overlay.choice_loadout_slot_size = maxf(1.0,floor((choice_grid_width - 16.0*f)/5.0))
	# Choice contents have a fixed compact target height. Measuring the live scroll
	# container can inherit its previous full-screen height and pin this overlay to top.
	var choice_height := (540.0 if overlay.wide_cards else 460.0) * f
	var height := minf(safe_size.y,choice_height) if choice_view else maxf(1.0,safe_size.y)
	var vertical_offset := (safe_size.y-height)/2.0 if choice_view else 0.0
	overlay.position = Vector2(safe_origin.x+(safe_size.x-width)/2.0,safe_origin.y+vertical_offset)
	overlay_target_size = Vector2(width,height)
	overlay.size = overlay_target_size
	var hud := CompactUI.hud_layout(size,f,hud_safe)
	var controls := [pause_control,speed_control,upgrades_control]
	for index in range(controls.size()):
		if not is_instance_valid(controls[index]): continue
		controls[index].position = hud.buttons[index + 1].position
		controls[index].size = hud.buttons[index + 1].size
	wave_control.position = hud.wave.position
	wave_control.size = hud.wave.size
	build_control.position = hud.weapon.position
	build_control.size = hud.weapon.size
	auto_control.position = hud.dodge.position
	auto_control.size = hud.dodge.size
	auto_cards_control.position = hud.cards.position
	auto_cards_control.size = hud.cards.size

func _update_buttons() -> void:
	if not is_instance_valid(overview_control):
		overview_control = overlay.button("","build")
		add_child(overview_control)
		overview_control.icon = load("res://assets/ui/icons/cards.svg")
		pause_control.icon = load("res://assets/ui/icons/pause.svg")
		pause_control.text = ""
		for compact_button in [pause_control,overview_control,speed_control,upgrades_control]:
			compact_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			for state in ["normal","hover","pressed","disabled"]:
				var inset := compact_button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				inset.set_expand_margin_all(-6*ui_factor)
				compact_button.add_theme_stylebox_override(state,inset)
		upgrades_control.icon = load("res://assets/ui/icons/shop.svg")
		upgrades_control.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		auto_cards_control.icon = null
		build_control.icon = overlay.illustration("hero")
	_layout_buttons()
	overview_control.visible = false
	for icon_button in [pause_control,auto_cards_control,upgrades_control]:
		icon_button.add_theme_constant_override("icon_max_width",ceili(18*ui_factor))
		icon_button.expand_icon = true
	for control in [upgrades_control,pause_control,speed_control,auto_cards_control,build_control,wave_control]: control.visible = status=="running"
	auto_control.visible = false
	speed_control.text = "%dx" % _game_speed()
	upgrades_control.text = ""
	auto_control.text = "Dodge ON" if bool(profile.autoDodgeEnabled) and bool(profile.autoDodgeUnlocked) else "Dodge OFF"
	auto_control.disabled = not bool(profile.autoDodgeUnlocked)
	auto_control.tooltip_text = "Unlock Auto-Dodge in Workshop after wave 30" if auto_control.disabled else "Toggle Auto-Dodge"
	auto_cards_control.text = ("Auto Cards\nON" if profile.settings.get("autoCards",false) else "Auto Cards\nOFF")
	build_control.text = ""
	build_control.icon = null
	wave_control.text = "WAVE %d" % int(runState.wave)
	wave_control.tooltip_text = "Wave Intel · pauses the run"
	if not is_instance_valid(weapon_hud):
		weapon_hud = WeaponHUDCard.new()
		weapon_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		build_control.add_child(weapon_hud)
		weapon_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		weapon_hud.art = overlay.illustration("hero")
	var slot_layout := CompactUI.hud_layout(get_viewport_rect().size,ui_factor,hud_safe)
	if empty_weapon_slots.is_empty():
		for index in range(4):
			var slot := WeaponHUDCard.new()
			slot.empty = true
			slot.selected = false
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(slot)
			empty_weapon_slots.append(slot)
	for index in range(4):
		var slot := empty_weapon_slots[index]
		slot.visible = status == "running"
		slot.position = slot_layout.slots[index+1].position
		slot.size = slot_layout.slots[index+1].size
		slot.units = ui_factor
		slot.queue_redraw()
	weapon_hud.units = ui_factor
	weapon_hud.epic = Cards.epic_count(cards)>0
	weapon_hud.stars = Cards.epic_count(cards) if weapon_hud.epic else mini(3,int(cards.choices))
	weapon_hud.star_slots = 4 if weapon_hud.epic else 3
	weapon_hud.epic_fraction = Cards.progress_fraction(cards)
	var stats := _railgun_stats()
	weapon_hud.update_state(float(player.weapon.reload_timer),float(stats.reload),int(player.weapon.ammo),int(stats.magazine),status=="running" and not app_backgrounded)
	build_control.tooltip_text = "Railgun · Open build"
	card_notice_label.visible = false

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
	return CompactUI.layout(size,ui_factor).field

func _circles_overlap(a_position: Vector2, a_radius: float, b_position: Vector2, b_radius: float) -> bool:
	var hit_distance := a_radius + b_radius
	return a_position.distance_squared_to(b_position) <= hit_distance * hit_distance

func _get_player_ship_texture() -> Texture2D:
	return gunship.textures[["intact", "damaged", "critical"][gunship.damage_state]]

func _get_enemy_definition(enemy_type_id: String) -> Dictionary:
	return EnemyRegistry.get_definition(enemy_type_id)

func _choose_enemy_type_id(run_level: int, seed: int) -> String:
	return EnemyRegistry.choose_enemy_type_id(run_level, seed, "pressure")

func _get_enemy_movement_frame(spawn_edge: String) -> String:
	return ENEMY_MOVEMENT_FRAMES_BY_EDGE.get(spawn_edge, "down")

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
	return 0

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
	if player.is_empty():
		return 0.0

	var warmup: float = float(enemy.get("attack_warmup_timer", 0.0))
	if warmup > 0.0:
		var duration := float(WeaponRegistry.cycle(str(enemy.attack_behavior)).warmup) if WeaponRegistry.CYCLES.has(str(enemy.attack_behavior)) else ENEMY_ATTACK_WARMUP_SECONDS
		return clampf(1.0 - warmup / duration, 0.0, 1.0)
	if float(enemy.get("attack_visual_timer", 0.0)) > 0.0:
		return clampf(float(enemy.attack_visual_timer) / ENEMY_ATTACK_VISUAL_SECONDS, 0.0, 1.0) * 0.42
	return 0.0

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

func _stat(id: String) -> float:
	return UpgradeRegistry.value(id, UpgradeRegistry.level(id, metaProgress.get("permanentUpgrades", {}), run_upgrades))

func _fleet_orbit_sign() -> float:
	return -1.0 if float(runState.get("fleetOrbitSign", 1.0)) < 0.0 else 1.0

func _count_bosses() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.type_id == EnemyRegistry.BOSS_ID:
			count += 1
	return count

func _separate_enemies() -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		for other_index in range(index + 1, enemies.size()):
			var other: Dictionary = enemies[other_index]
			if int(enemy.get("flight_layer", 0)) != int(other.get("flight_layer", 0)):
				continue
			var offset: Vector2 = other.position - enemy.position
			# Navigation handles normal traffic. Only unwind deep intersections here,
			# and do it partially so crowded ships may pass through a little.
			var minimum := (float(enemy.radius) + float(other.radius)) * 0.40
			var distance := offset.length()
			if distance >= minimum:
				continue
			var direction := offset / distance if distance > 0.01 else Vector2.RIGHT.rotated(float(enemy.id))
			var correction := direction * (minimum - distance) * 0.22
			enemy.position -= correction
			other.position += correction
		# Pair separation must not push a body back inside the player's hull.
	for enemy in enemies:
		var offset: Vector2 = enemy.position - player.position
		var minimum := float(enemy.radius) + float(player.radius)
		if offset.length() < minimum:
			var direction := offset.normalized() if offset.length_squared() > 0.01 else Vector2.RIGHT
			enemy.position = player.position + direction * minimum

func _update_autopilot(delta: float) -> void:
	auto_timer -= delta
	if not bool(profile.autoDodgeUnlocked) or not bool(profile.autoDodgeEnabled) or pointer_down or manual_override > 0.0:
		return
	if auto_timer <= 0.0:
		auto_timer = 0.1
		var bounds := _get_playfield_rect(get_viewport_rect().size).grow(-(PLAYER_RADIUS + PLAYER_BOUNDS_PADDING))
		player_target = Autopilot.choose_target(player.position, bounds, enemies, enemy_projectiles, PLAYER_MOVE_SPEED)

func _pause_run() -> void:
	if status not in ["running", "card_choice"]:
		return
	status = "paused"
	runState.status = "paused"
	pointer_down = false
	player_target = player.position
	manual_override = 1.0
	menu_view = "pause"
	_save_run()
	_refresh_overlay()

func _setup_background_events() -> void:
	if not OS.has_feature("web"):
		return
	background_callback = JavaScriptBridge.create_callback(func(_args):
		app_backgrounded = bool(JavaScriptBridge.get_interface("document").hidden)
		_pause_run())
	foreground_callback = JavaScriptBridge.create_callback(func(_args):
		app_backgrounded = false
		_pause_run())
	var document := JavaScriptBridge.get_interface("document")
	var window := JavaScriptBridge.get_interface("window")
	document.addEventListener("visibilitychange", background_callback)
	window.addEventListener("focus", foreground_callback)
	window.addEventListener("pagehide", background_callback)

func _save_run() -> void:
	if run_id == "" or status == "dead" or status == "menu":
		return
	profile.activeRun = ProfileStore.encode({
		"version": 1, "run_id": run_id, "runState": runState, "cards": cards,
		"upgrades": run_upgrades, "player": player, "player_target": player_target,
		"enemies": enemies, "bullets": bullets, "enemy_projectiles": enemy_projectiles,
		"spawn_timer": spawn_timer, "fire_timer": fire_timer, "next_id": next_id,
		"last_boss_wave": last_boss_wave, "rng_state": str(rng.state),
		"enemy_kills": run_enemy_kills, "discovered": run_discovered_enemies,
		"viewport": get_viewport_rect().size, "manual_override": manual_override,
		"playfield_position": _get_playfield_rect(get_viewport_rect().size).position,
		"playfield_size": _get_playfield_rect(get_viewport_rect().size).size,
		"auto_timer": auto_timer, "rail_direction": rail_direction,
	})
	save_error = not profile_store.save_profile(profile)
	metaProgress = profile
	save_timer = 0.0

func _restore_run() -> void:
	selected_card = ""
	var snapshot: Dictionary = ProfileStore.decode(profile.activeRun)
	# Keep an unrecognized snapshot intact; do not silently replace it with a new run.
	if int(snapshot.get("version", 0)) != 1 or not snapshot.has_all(["run_id", "player", "runState", "upgrades", "enemies", "bullets", "enemy_projectiles"]):
		save_error = true
		return
	run_id = str(snapshot.run_id)
	if run_id == str(profile.settledRunId):
		profile.activeRun = {}
		profile_store.save_profile(profile)
		return
	runState = snapshot.runState
	if not runState.has("realElapsedSeconds"):
		runState.realElapsedSeconds = float(runState.get("elapsedSeconds",0.0)) / maxf(1.0,float(_game_speed()))
	cards = Cards.migrate(snapshot.get("cards", Cards.fresh(hash(run_id))))
	if not runState.has("fleetOrbitSign"):
		var legacy_sign := 0.0
		for saved_enemy in snapshot.enemies:
			if saved_enemy.has("orbit_sign"):
				legacy_sign = float(saved_enemy.orbit_sign)
				break
		if legacy_sign == 0.0:
			legacy_sign = -1.0 if hash(run_id) % 2 == 0 else 1.0
		runState.fleetOrbitSign = -1.0 if legacy_sign < 0.0 else 1.0
	run_upgrades = UpgradeRegistry.defaults()
	run_upgrades.merge(snapshot.upgrades, true)
	player = snapshot.player
	player.radius = PLAYER_RADIUS
	if not player.has("weapon"): player.weapon = {}
	WeaponRegistry.ensure_cycle(player.weapon, "railgun")
	player.max_shield = _stat("shield_capacity")
	if not player.has("shield_delay"):
		player.shield = 0.0
		player.shield_delay = ShieldSystem.RECHARGE_DELAY
	player.shield = clampf(float(player.get("shield", 0.0)), 0.0, float(player.max_shield))
	player.shield_delay = maxf(0.0, float(player.shield_delay))
	rail_direction = snapshot.get("rail_direction", Vector2.UP)
	gunship.reset(float(player.hp) / maxf(1, float(player.max_hp)))
	player_target = snapshot.get("player_target", player.position)
	enemies.assign(snapshot.enemies)
	bullets.assign(snapshot.bullets)
	enemy_projectiles.assign(snapshot.enemy_projectiles)
	for enemy in enemies:
		enemy.id = int(enemy.id)
		enemy.radius = float(EnemyRegistry.get_definition(str(enemy.type_id)).base_stats.radius) * COMBAT_SPRITE_SCALE
		enemy.movement_behavior = str(EnemyRegistry.get_definition(str(enemy.type_id)).movement_behavior)
		enemy.attack_behavior = str(EnemyRegistry.get_definition(str(enemy.type_id)).attack_behavior)
		if WeaponRegistry.CYCLES.has(str(enemy.attack_behavior)):
			WeaponRegistry.ensure_cycle(enemy, str(enemy.attack_behavior))
		if not enemy.has("flight_heading"): enemy.flight_heading = (player.position - enemy.position).angle()
		if not enemy.has("attack_direction"): enemy.attack_direction = _get_enemy_forward_direction(enemy)
		EnemyNavigation.initialize(enemy, null, _fleet_orbit_sign())
	for bullet in bullets:
		bullet.hit_ids = bullet.get("hit_ids", []).map(func(id): return int(id))
		bullet.radius = float(bullet.get("radius", 3.2))
		bullet.weapon_id = WeaponRegistry.canonical_id(str(bullet.get("weapon_id", "pulse_cannon")))
		bullet.previous_position = bullet.position
		if not bullet.has("remaining_distance"):
			bullet.remaining_distance = minf(UpgradeRegistry.value("range", 0), maxf(0.0, float(bullet.life)) * bullet.velocity.length())
	for projectile in enemy_projectiles:
		projectile.previous_position = projectile.position
	spawn_timer = float(snapshot.spawn_timer)
	fire_timer = float(snapshot.fire_timer)
	next_id = int(snapshot.next_id)
	last_boss_wave = int(snapshot.last_boss_wave)
	rng.state = int(snapshot.rng_state)
	run_enemy_kills = snapshot.enemy_kills
	run_discovered_enemies = snapshot.discovered
	manual_override = float(snapshot.get("manual_override", 1.0))
	auto_timer = float(snapshot.get("auto_timer", 0.0))
	_remap_viewport(snapshot.viewport, get_viewport_rect().size, Rect2(snapshot.get("playfield_position", _get_playfield_rect(snapshot.viewport).position), snapshot.get("playfield_size", _get_playfield_rect(snapshot.viewport).size)))
	status = "paused"
	runState.status = "paused"
	menu_view = "pause"
	pointer_down = false
	_sync_legacy_run_fields()

func _remap_viewport(previous: Vector2, current: Vector2, previous_bounds := Rect2()) -> void:
	if previous.x <= 0.0 or current.x <= 0.0 or player.is_empty():
		return
	var old_bounds := previous_bounds if previous_bounds.has_area() else _get_playfield_rect(previous)
	var new_bounds := _get_playfield_rect(current)
	var ratio := new_bounds.size / old_bounds.size
	player.position = new_bounds.position + (player.position - old_bounds.position) * ratio
	player_target = new_bounds.position + (player_target - old_bounds.position) * ratio
	for collection in [enemies, bullets, enemy_projectiles]:
		for entity in collection:
			entity.position = new_bounds.position + (entity.position - old_bounds.position) * ratio
			if entity.has("scout_goal") and Vector2(entity.scout_goal)!=Vector2.ZERO:
				entity.scout_goal = new_bounds.position + (entity.scout_goal-old_bounds.position)*ratio
	_clamp_player_to_viewport()

func _money(amount: float) -> String:
	if amount >= 1.0e12:
		return "%.1e" % amount
	return str(int(floor(amount))) if amount < 10000 else "%.1fK" % (amount / 1000.0)

func _refresh_overlay() -> void:
	if not is_instance_valid(overlay):
		return
	if status == "running" or death_timer > 0.0:
		overlay.hide()
		return
	if status == "card_choice" or menu_view in ["railgun", "railgun_catalog", "railgun_detail", "build"]:
		overlay.set_overlay_background(null, false)
		last_layout_size = Vector2.ZERO
		_layout_buttons()
		overlay.show_railgun(self)
		# The panel builds its card grid dynamically; measure it again afterwards.
		last_layout_size = Vector2.ZERO
		_layout_buttons()
		return
	overlay.set_overlay_opacity(0.76 if status == "dead" else 0.96)
	overlay.set_overlay_background(run_complete_background, status == "dead")
	var entries := []
	var actions := []
	var tabs := []
	var quantities := []
	var title := "VOID DRIFTER"
	var summary := "Hold position or drag to steer. Railgun fires automatically."
	if menu_view == "shop" or menu_view == "workshop":
		var workshop := menu_view == "workshop"
		title = "WORKSHOP" if workshop else "RUN UPGRADES"
		var wallet := float(profile.totalCoins) if workshop else float(runState.cash)
		summary = ("◈ %s available · Permanent" if workshop else "CASH %s / Paused") % _money(wallet)
		for category in ["Attack", "Defense", "Utility"]:
			tabs.append({"text": category, "action": "tab:" + category, "selected": category == shop_category})
		for quantity in [1, 10]:
			quantities.append({"text": "Buy %d" % quantity, "action": "quantity:%d" % quantity, "selected": quantity == buy_quantity})
		for entry in UpgradeRegistry.CATALOG:
			if entry.category != shop_category: continue
			var levels := UpgradeRegistry.level(entry.id, profile.permanentUpgrades, {} if workshop else run_upgrades)
			var quote := UpgradeRegistry.quote(entry.id, profile.permanentUpgrades, run_upgrades, wallet, buy_quantity, workshop)
			var next_value := "MAX" if levels == int(entry.cap) else UpgradeRegistry.display_value(entry.id, levels + maxi(1, int(quote.count)))
			var price := float(quote.cost) if int(quote.count) > 0 else UpgradeRegistry.cost(levels, workshop)
			var caption := "MAX" if levels == int(entry.cap) else "Buy %d\n%s %s" % [maxi(1, int(quote.count)), _money(price), "◈" if workshop else "cash"]
			entries.append({"upgrade_name": entry.name, "level": levels, "cap": entry.cap, "values": "%s -> %s" % [UpgradeRegistry.display_value(entry.id, levels), next_value], "purchase": {"text": caption, "action": "buy:%s:%d" % [entry.id, buy_quantity], "disabled": int(quote.count) == 0 or (workshop and not profile.activeRun.is_empty())}})

		if workshop and shop_category == "Utility":
			entries.append({"text": "AUTO-DODGE / Permanent unlock\nReach wave 30, then spend ◈ 1,000.", "buttons": [{"text": "Unlocked" if profile.autoDodgeUnlocked else "Unlock / ◈ 1,000", "action": "unlock_auto", "disabled": bool(profile.autoDodgeUnlocked) or int(profile.highestWave) < 30 or float(profile.totalCoins) < 1000.0 or not profile.activeRun.is_empty()}]})
		actions = [{"text": "Resume Run" if not workshop else "Back", "action": "resume" if not workshop else "back"}]
		if workshop:
			actions = [{"text": "Reset", "action": "reset_workshop", "inline": true, "disabled": profile_store.workshop_refund(profile) <= 0 or not profile.activeRun.is_empty()}, {"text": "Back", "action": "back"}]
	elif menu_view == "developers":
		title = "DEVELOPERS"
		summary = "◈ %s / ▣ %d" % [_money(float(profile.totalCoins)),int(profile.railgunModules)]
		entries = [
			{"text":"Add permanent currency. Changes save immediately.","buttons":[{"text":"+1,000 ◈","action":"dev_coins_small"},{"text":"+10,000 ◈","action":"dev_coins_large"}]},
			{"text":"Railgun upgrade ▣","buttons":[{"text":"+10 ▣","action":"dev_modules_small"},{"text":"+100 ▣","action":"dev_modules_large"}]},
			{"text":"Reset every saved upgrade, currency, record, Codex entry and setting.","buttons":[{"text":"Reset entire game...","action":"dev_reset"}]},
		]
		actions = [{"text":"Back","action":"back"}]
	elif menu_view == "dev_reset":
		title = "RESET ENTIRE GAME?"
		summary = "All local progress will be lost."
		entries = [{"text":"◈ and ▣ return to zero. Workshop upgrades, Railgun levels, unlocks, records, Codex history, settings and any saved run return to their starting state. This cannot be undone in the game."}]
		actions = [{"text":"Cancel","action":"developers"},{"text":"Reset entire game","action":"dev_reset_confirm"}]
	elif menu_view == "reset_workshop":
		title = "RESET WORKSHOP?"
		summary = "Refund ◈ %s" % _money(profile_store.workshop_refund(profile))
		entries = [{"text": "Reset all permanent upgrade levels and Auto-Dodge. Your ◈, records and Enemy Codex history are kept. This is available only when no run is unfinished."}]
		actions = [{"text": "Cancel", "action": "cancel_reset"}, {"text": "Reset / Refund ◈", "action": "confirm_reset"}]
	elif menu_view == "wave_intel":
		var wave := int(runState.wave)
		var timing := DirectorSystem.wave_timing(float(runState.elapsedSeconds))
		title = "WAVE %d INTEL" % wave
		summary = ""
		for tab in ["roster", "stats"]:
			tabs.append({"text": tab.to_upper(), "action": "wave_intel_tab:" + tab, "selected": wave_intel_tab == tab})
		var wave_rows := []
		for definition in _get_wave_intel_roster(wave):
			wave_rows.append(_wave_intel_table_row(definition, wave, wave_intel_tab == "stats"))
		entries.append({"wave_intel_table": true, "mode": wave_intel_tab, "rows": wave_rows})
		actions = [{"text": "Resume", "action": "resume"}]
	elif menu_view == "codex_detail" and codex_detail_id != "":
		var definition := EnemyRegistry.get_definition(codex_detail_id)
		var full_intel := codex_detail_origin == "wave_intel"
		var discovered := full_intel or _is_enemy_discovered(codex_detail_id) or run_discovered_enemies.has(codex_detail_id)
		var detail_wave := maxi(1, codex_detail_wave)
		var detail_stats := EnemyRegistry.get_stats(codex_detail_id, detail_wave)
		title = str(definition.name).to_upper()
		summary = "WAVE %d COMBAT INTEL" % detail_wave if full_intel else "ENEMY CODEX"
		var arrival := "EVERY 10 WAVES" if codex_detail_id == EnemyRegistry.BOSS_ID else "FROM WAVE %d" % int(definition.unlock_wave)
		var detail_values := _enemy_wave_stat_lines(definition, detail_stats, true)
		detail_values += "\nKILL  +%s cash / +◈ %s" % [_money(float(definition.base_stats.get("cash_reward", 0))), _money(float(definition.base_stats.get("coin_reward", 0)))]
		entries.append({
			"enemy_name": str(definition.name),
			"preview": _get_codex_preview(codex_detail_id, definition),
			"role": str(definition.role),
			"boss": codex_detail_id == EnemyRegistry.BOSS_ID,
			"discovered": discovered,
			"arrival": arrival,
			"description": str(definition.description) if discovered else "Encounter this enemy to reveal its Codex data.",
			"stats": detail_values if discovered else "",
			"note": "Combat values include this wave's Hull and damage scaling. Armor is applied separately." if discovered else "",
			"kills": _get_enemy_total_kills(codex_detail_id),
		})
		actions = [{"text": "Back to Wave Intel" if full_intel else "Back to Codex", "action": "codex_detail_back"}]
	elif menu_view == "codex":
		title = "ENEMY CODEX"
		var definitions: Array = EnemyRegistry.get_definitions().values()
		definitions.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.unlock_wave) < int(b.unlock_wave))
		var counts := {"active": 0, "archive": 0}
		var discovered_count := 0
		for entry in definitions:
			var group := "active" if entry.status == "active" else "archive"
			counts[group] += 1
			if group == "active" and (_is_enemy_discovered(entry.id) or run_discovered_enemies.has(entry.id)):
				discovered_count += 1
		summary = "%d / %d encountered • Base stats" % [discovered_count, counts.active] if codex_tab == "active" else "Archived designs • Not spawning in this mode"
		for group in ["active", "archive"]:
			tabs.append({"text": "%s / %d" % [group.capitalize(), counts[group]], "action": "codex_tab:" + group, "selected": codex_tab == group})
		for entry in definitions:
			var active: bool = entry.status == "active"
			if active != (codex_tab == "active"): continue
			var id: String = entry.id
			var discovered := _is_enemy_discovered(id) or run_discovered_enemies.has(id)
			var stats: Dictionary = entry.base_stats
			var values := ["HULL  %s" % _money(float(stats.hp)), "FIRST IMPACT  %s" % _money(float(stats.contact_damage) * FIRST_IMPACT_MULTIPLIER), "CONTACT HIT  %s" % _money(float(stats.contact_damage)), "CONTACT CADENCE  %.2fs" % float(stats.get("contact_interval", 1.0))]
			if WeaponRegistry.CYCLES.has(str(entry.attack_behavior)):
				values.append(("ROCKET  %s" if entry.attack_behavior == "boss_rocket" else "RAILGUN  %s") % ("%.1f" % float(WeaponRegistry.cycle(str(entry.attack_behavior)).damage)))
			if WeaponRegistry.CYCLES.has(str(entry.attack_behavior)):
				var cycle := WeaponRegistry.cycle(str(entry.attack_behavior))
				values.append("SALVO  %d / RELOAD  %.1fs" % [int(cycle.magazine),float(cycle.reload)])
			values.append("KILL  +%s cash / +◈ %s" % [_money(float(stats.get("cash_reward", 0))), _money(float(stats.coin_reward))])
			entries.append({"enemy_name": entry.name, "preview": _get_codex_preview(id, entry), "role": entry.role, "boss": id == EnemyRegistry.BOSS_ID, "discovered": discovered, "arrival": ("EVERY 10 WAVES" if id == EnemyRegistry.BOSS_ID else "FROM WAVE %d" % int(entry.unlock_wave)) if active else "ARCHIVE", "description": entry.description if discovered else "Encounter this enemy to reveal its combat data.", "stats": "\n".join(values) if discovered else "", "note": "Base values before armor / bonuses. Hull and damage grow after wave %d." % EnemyRegistry.GROWTH_START_WAVE if discovered and active else "", "kills": _get_enemy_total_kills(id), "action": "codex_enemy:" + id})
		actions = [{"text": "Back", "action": "back"}]
	elif status == "paused":
		title = "RUN PAUSED"
		summary = "Wave %d / %s\nCash %s / Run ◈ %s\nYour run is saved. No progress while away." % [int(runState.wave), _format_time(elapsed), _money(float(runState.cash)), _money(float(runState.coinsEarned))]
		actions = [{"text": "Resume Run", "action": "resume"}, {"text": "Wave Intel", "action": "wave_intel"}, {"text": "Run Upgrades", "action": "shop", "disabled": not cards.offer.is_empty()}, {"text": "Enemy Codex", "action": "codex"}, {"text": "Retire Run / Bank ◈", "action": "retire"}]
	elif status == "dead":
		title = "RUN COMPLETE"
		summary = ""
		entries = [{"run_results": [
			{"wide":true, "label":"WAVE", "value":("%d\n[b]NEW RECORD[/b]" % int(runState.wave)) if last_run_records.values().any(func(record): return bool(record)) else str(int(runState.wave))},
			{"label":"GAME TIME", "value":_format_time(float(runState.elapsedSeconds))},
			{"label":"REAL TIME", "value":_format_time(float(runState.get("realElapsedSeconds",0.0)))},
			{"label":"◈ COINS EARNED", "value":"◈ %s" % _money(float(runState.coinsEarned))},
			{"label":"▣ BOSS MODULE EARNED", "value":"▣ +%d" % cards.modules}
		]}]
		actions = [{"text": "Run Again", "action": "start"}, {"text": "Main Menu", "action": "menu"}]
	else:
		summary += "\n◈ %s / BEST WAVE %d" % [_money(float(profile.totalCoins)), int(profile.highestWave)]
		entries = [{"text": "Defeat enemies for XP and choose your railgun cards. Bosses drop upgrade ▣.\n\nEnable Auto Cards to keep your run idle. Progress saves automatically."}]
		actions = [{"text": "Start Run", "action": "start", "disabled": not profile.activeRun.is_empty()}, {"text": "Workshop", "action": "workshop", "disabled": not profile.activeRun.is_empty()}, {"text": "Enemy Codex", "action": "codex"}]
	if menu_view == "main" and status == "menu":
		actions.append({"text":"Developers","action":"developers"})
	if menu_view == "main" or menu_view == "pause":
		if status == "menu":
			actions.insert(1, {"text":"Railgun Lv.%d  ·  ▣ %d" % [profile.railgunLevel,profile.railgunModules],"action":"railgun"})
			entries.append({"text":Cards.next_unlock(int(profile.railgunLevel),profile.get("railgunPreservedUnlocks",[]))})
		elif status == "paused":
			actions.insert(1, {"text":_auto_cards_text(),"action":"auto_cards"})
			actions.insert(2, {"text":"Railgun Build","action":"build"})
			actions.append({"text":"Dodge ON" if profile.autoDodgeEnabled else "Dodge OFF","action":"auto","disabled":not profile.autoDodgeUnlocked})
	if save_error and status != "dead":
		summary += "\nSave failed. Keep this tab open and retry."
		actions.append({"text": "Retry Save", "action": "save"})
	overlay.scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	overlay.show_content(title, summary, tabs, entries, actions, quantities)
	if status == "dead":
		overlay.scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		overlay.rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if menu_view == "main" and status == "menu":
		var hero: TextureRect = overlay.portrait("hero",160)
		overlay.rows.add_child(hero)
		overlay.rows.move_child(hero,0)
	last_layout_size = Vector2.ZERO
	_layout_buttons()

func _on_panel_action(action: String) -> void:
	if action.begins_with("card:"):
		if status == "card_choice" and cards.offer.has(action.get_slice(":",1)):
			_choose_card(action.get_slice(":",1))
			selected_card = ""
	elif action == "equip_card":
		if status == "card_choice" and not app_backgrounded and cards.offer.has(selected_card):
			_choose_card(selected_card)
			selected_card = ""
	elif action == "card_detail_back":
		menu_view = card_detail_origin
	elif action.begins_with("card_info:"):
		card_detail_origin = menu_view
		card_detail = action.get_slice(":",1)
		menu_view = "railgun_detail"
	elif action.begins_with("wave_intel_tab:"):
		wave_intel_tab = "stats" if action.get_slice(":", 1) == "stats" else "roster"
		overlay.scroll.scroll_vertical = 0
	elif action.begins_with("wave_enemy:"):
		codex_detail_id = action.get_slice(":", 1)
		codex_detail_origin = "wave_intel"
		codex_detail_wave = int(runState.wave)
		menu_view = "codex_detail"
		overlay.scroll.scroll_vertical = 0
	elif action.begins_with("codex_enemy:"):
		codex_detail_id = action.get_slice(":", 1)
		codex_detail_origin = "codex"
		codex_detail_wave = int(runState.wave)
		menu_view = "codex_detail"
		overlay.scroll.scroll_vertical = 0
	elif action == "codex_detail_back":
		menu_view = codex_detail_origin
		overlay.scroll.scroll_vertical = 0
	elif action.begins_with("codex_tab:"):
		codex_tab = "archive" if action.get_slice(":", 1) == "archive" else "active"
		overlay.scroll.scroll_vertical = 0
	elif action.begins_with("tab:"):
		shop_category = action.get_slice(":", 1)
		overlay.scroll.scroll_vertical = 0
	elif action.begins_with("quantity:"):
		buy_quantity = 10 if action.get_slice(":", 1) == "10" else 1
	elif action.begins_with("buy:"):
		_buy_upgrade(action.get_slice(":", 1), int(action.get_slice(":", 2)))
	else:
		match action:
			"developers":
				if status == "menu":
					menu_view = "developers"
					overlay.scroll.scroll_vertical = 0
			"dev_coins_small", "dev_coins_large", "dev_modules_small", "dev_modules_large":
				if status == "menu" and menu_view == "developers":
					if action.begins_with("dev_coins"):
						profile.totalCoins += 1000 if action == "dev_coins_small" else 10000
					else:
						profile.railgunModules += 10 if action == "dev_modules_small" else 100
					save_error = not profile_store.save_profile(profile)
			"dev_reset":
				if status == "menu" and menu_view == "developers": menu_view = "dev_reset"
			"dev_reset_confirm":
				if status == "menu" and menu_view == "dev_reset":
					profile = profile_store._default_profile()
					metaProgress = profile
					save_error = not profile_store.save_profile(profile)
					# Rotate the fresh profile into the recovery backup as well.
					if not save_error: save_error = not profile_store.save_profile(profile)
					reset_world("menu")
					menu_view = "developers"
			"auto_cards":
				pointer_down = false
				player_target = player.position
				profile.settings.autoCards = not bool(profile.settings.get("autoCards",false))
				_save_run()
				_handle_card_progress()
			"railgun", "railgun_catalog":
				if status in ["menu", "dead"]: menu_view = action
				overlay.scroll.scroll_vertical = 0
			"railgun_buy": _buy_railgun()
			"build":
				if status == "running": _pause_run()
				if status == "paused": menu_view = "build"
			"speed":
				if status == "running":
					profile.settings.gameSpeed = ProfileStore.GAME_SPEEDS[(ProfileStore.GAME_SPEEDS.find(_game_speed()) + 1) % ProfileStore.GAME_SPEEDS.size()]
					pointer_down = false
					player_target = player.position
					_save_run()
			"reset_workshop":
				if menu_view == "workshop" and profile.activeRun.is_empty(): menu_view = "reset_workshop"
			"cancel_reset": menu_view = "workshop"
			"confirm_reset":
				if menu_view == "reset_workshop" and profile.activeRun.is_empty() and status in ["menu", "dead"]:
					profile = profile_store.reset_workshop(profile)
					metaProgress = profile
					save_error = not profile_store.last_save_ok
					menu_view = "workshop"
			"start": start_run()
			"pause": _pause_run()
			"shop":
				if status == "running":
					_pause_run()
				if status == "paused" and cards.offer.is_empty():
					menu_view = "shop"
			"wave_intel":
				if status == "running":
					_pause_run()
				if status == "paused":
					menu_view = "wave_intel"
					wave_intel_tab = "roster"
			"workshop":
				if profile.activeRun.is_empty() and status in ["menu", "dead"]:
					menu_view = "workshop"
			"resume":
				if status == "paused" and not app_backgrounded:
					status = "running"
					runState.status = "running"
					menu_view = "main"
					pointer_down = false
					_handle_card_progress()
			"retire":
				if status == "paused":
					_end_run()
			"codex":
				menu_view = "codex"
				overlay.scroll.scroll_vertical = 0
			"back": menu_view = "pause" if status == "paused" else "main"
			"menu": reset_world("menu")
			"auto":
				if profile.autoDodgeUnlocked:
					profile.autoDodgeEnabled = not profile.autoDodgeEnabled
					if not profile.autoDodgeEnabled:
						player_target = player.position
					_save_run()
			"unlock_auto":
				if profile.activeRun.is_empty() and int(profile.highestWave) >= 30 and float(profile.totalCoins) >= 1000.0 and not bool(profile.autoDodgeUnlocked):
					profile.totalCoins = float(profile.totalCoins) - 1000.0
					profile.workshopSpent = float(profile.workshopSpent) + 1000.0
					profile.autoDodgeUnlocked = true
					save_error = not profile_store.save_profile(profile)
			"save":
				if status in ["paused", "card_choice"]:
					_save_run()
				else:
					save_error = not profile_store.save_profile(profile)
	_refresh_overlay()

func _buy_upgrade(id: String, count: int) -> void:
	var workshop := menu_view == "workshop"
	if workshop and (not profile.activeRun.is_empty() or status not in ["menu", "dead"]):
		return
	if not workshop and (menu_view != "shop" or status != "paused" or not cards.offer.is_empty()):
		return
	var wallet := float(profile.totalCoins) if workshop else float(runState.cash)
	var quote := UpgradeRegistry.quote(id, profile.permanentUpgrades, run_upgrades, wallet, count, workshop)
	if int(quote.count) <= 0:
		return
	if workshop:
		profile.totalCoins = wallet - float(quote.cost)
		profile.workshopSpent = float(profile.workshopSpent) + float(quote.cost)
		profile.permanentUpgrades[id] = int(profile.permanentUpgrades.get(id, 0)) + int(quote.count)
		metaProgress = profile
		save_error = not profile_store.save_profile(profile)
	else:
		runState.cash = wallet - float(quote.cost)
		run_upgrades[id] = int(run_upgrades.get(id, 0)) + int(quote.count)
		if id == "max_hp":
			player.max_hp = _stat("max_hp")
			player.hp = minf(float(player.max_hp), float(player.hp) + 20.0 * int(quote.count))
		if id == "shield_capacity":
			player.max_shield = _stat("shield_capacity")
		_save_run()

func _append_effect(effect: Dictionary) -> void:
	cosmetic_id += 1
	if particles.size() >= EffectRegistry.MAX_EFFECTS:
		var oldest := 0
		for index in range(particles.size()):
			if int(particles[index].get("priority", 0)) < int(particles[oldest].get("priority", 0)): oldest = index
		if int(particles[oldest].get("priority", 0)) > int(effect.get("priority", 0)): return
		particles.remove_at(oldest)
	particles.append(effect)

func _add_rail_impact(origin: Vector2, direction: Vector2, critical: bool, fragment_visual := false) -> void:
	var impact := EffectRegistry.make("rail_impact", origin)
	impact.direction = direction
	impact.critical = critical
	impact.is_fragment = fragment_visual
	_append_effect(impact)

func _update_visual_effects(delta: float) -> void:
	visual_time += delta
	if not player.is_empty(): gunship.update(self, delta)
	rail_recoil = maxf(0.0, rail_recoil - delta * 12.0)
	wave_message_timer = maxf(0.0, wave_message_timer - delta)
	screen_shake = maxf(0.0, screen_shake - delta * 8.0)
	level_pulse = maxf(0.0, level_pulse - delta * 1.6)
	wave_pulse = maxf(0.0, wave_pulse - delta * 1.8)
	for enemy in enemies:
		enemy.hit_flash = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
		enemy.hit_visual_timer = maxf(0.0, float(enemy.get("hit_visual_timer", 0.0)) - delta)
		enemy.attack_visual_timer = maxf(0.0, float(enemy.get("attack_visual_timer", 0.0)) - delta)
		var velocity: Vector2 = enemy.get("velocity", Vector2.ZERO)
		if velocity.length_squared() > 0.01:
			var desired := velocity.angle() + PI / 2.0
			enemy.visual_rotation = lerp_angle(_enemy_visual_rotation(enemy), desired, 1.0 - exp(-delta * 16.0 * _game_speed()))
	for flash in muzzle_flashes: flash.life -= delta
	muzzle_flashes = muzzle_flashes.filter(func(flash): return float(flash.life) > 0.0)
	for particle in particles:
		var step := delta
		if float(particle.get("delay", 0.0)) > 0.0:
			step = maxf(0.0, delta - float(particle.delay))
			particle.delay = maxf(0.0, float(particle.delay) - delta)
		if particle.has("velocity"): particle.position += particle.velocity * step
		particle.life -= step
	particles = particles.filter(func(particle): return particle.life > 0.0)

func _draw_boss(enemy: Dictionary, height: float, tint: Color) -> void:
	var texture: Texture2D = enemy_textures.get(EnemyRegistry.BOSS_ID, {}).get("idle-up")
	var rotation := _enemy_visual_rotation(enemy)
	var forward := Vector2.UP.rotated(rotation)
	var center: Vector2 = enemy.position
	var damaged := float(enemy.hp) / maxf(1.0, float(enemy.max_hp)) < 0.3
	var pixel_scale := height / float(texture.get_height())
	for index in range(BOSS_ENGINE_NOZZLES.size()):
		var offset: Vector2 = (BOSS_ENGINE_NOZZLES[index] - texture.get_size() * 0.5) * pixel_scale
		var nozzle := center + offset.rotated(rotation)
		var exhaust := -forward * (18.0 + 6.0 * sin(visual_time * 21.0 + index)) * pixel_scale
		draw_line(nozzle, nozzle + exhaust, Color(1, 0.29, 0.04, 0.55), 6.0 * pixel_scale, true)
		draw_line(nozzle, nozzle + exhaust * 0.65, Color(1, 0.8, 0.35, 0.9), 2.5 * pixel_scale, true)
	_draw_centered_texture(texture, center, height, rotation, tint)
	var core: Vector2 = center + Vector2(0, height * 0.03).rotated(rotation)
	var intensity := 0.45 + 0.2 * sin(visual_time * (29.0 if damaged else 3.0))
	draw_circle(core, 2.0, Color(1, 0.55, 0.1, intensity))
	if damaged:
		for index in range(3):
			var direction := Vector2.from_angle(visual_time * 4.0 + index * 2.1)
			draw_line(core + direction * 3.0, core + direction * (5.0 + intensity * 6.0), Color(1, 0.55, 0.2, intensity), 1.0, true)

func _enemy_visual_rotation(enemy: Dictionary) -> float:
	var velocity: Vector2 = enemy.get("velocity", Vector2.ZERO)
	var fallback := velocity.angle() + PI / 2.0 if velocity.length_squared() > 0.01 else _get_enemy_forward_direction(enemy).angle() + PI / 2.0
	return float(enemy.get("visual_rotation", fallback))

func _draw_enemy_engines(enemy: Dictionary, height: float) -> void:
	var forward := Vector2.UP.rotated(_enemy_visual_rotation(enemy))
	var side := forward.orthogonal()
	for index in [-1, 1]:
		var origin: Vector2 = enemy.position - forward * height * 0.3 + side * index * height * 0.085
		var length := height * (0.045 + 0.02 * sin(visual_time * 19.0 + enemy.id + index))
		draw_line(origin, origin - forward * length, Color(1, 0.35, 0.1, 0.65), 2.5, true)
		draw_line(origin, origin - forward * length * 0.6, Color(1, 0.8, 0.35, 0.9), 1.0, true)

func _railgun_stats() -> Dictionary:
	return Cards.stats(cards, int(profile.get("railgunLevel",1)), _stat("damage"), _stat("crit_chance"))

func _tick_railgun_reload(delta: float) -> float:
	var delay := float(player.weapon.reload_timer)
	if delay <= 0.0: return delta
	player.weapon.reload_timer = maxf(0.0,delay-delta)
	if float(player.weapon.reload_timer) <= 0.000001:
		player.weapon.reload_timer = 0.0
		player.weapon.ammo = int(_railgun_stats().magazine)
	return maxf(0.0,delta-delay)

func _auto_cards_text() -> String:
	return "Auto Cards: ON" if bool(profile.get("settings",{}).get("autoCards",false)) else "Auto Cards: OFF"

func _queue_card_notice(notice: String) -> void:
	# A saved/resumed offer or repeated progress check must not replay the same popup.
	if notice == card_notice or card_notices.has(notice): return
	card_notices.append(notice)

func _handle_card_progress() -> void:
	if app_backgrounded or status not in ["running","card_choice"]: return
	if not Cards.ensure_offer(cards,int(profile.railgunLevel),_stat("crit_chance"),profile.get("railgunPreservedUnlocks",[])): return
	if bool(profile.settings.get("autoCards",false)):
		_choose_card(Cards.auto_pick(cards),true)
	else:
		var newly_opened := status != "card_choice"
		status = "card_choice"
		runState.status = status
		pointer_down = false
		player_target = player.position
		_save_run()
		if newly_opened: _refresh_overlay()

func _choose_card(id: String, automatic := false) -> void:
	selected_card = ""
	if not Cards.choose(cards,id): return
	var entry := Cards.definition(id)
	if automatic:
		_queue_card_notice("%s · %s" % [entry.name,entry.short_effect.replace("\n"," · ")])
	status = "running"
	runState.status = status
	menu_view = "main"
	# Store the applied choice and the next offer together. No reroll on reload.
	Cards.ensure_offer(cards,int(profile.railgunLevel),_stat("crit_chance"),profile.get("railgunPreservedUnlocks",[]))
	if not cards.offer.is_empty() and not bool(profile.settings.get("autoCards",false)):
		status = "card_choice"
		runState.status = status
	_save_run()
	_refresh_overlay()

func _buy_railgun() -> void:
	var level := int(profile.railgunLevel)
	if level >= Cards.MAX_LEVEL or not profile.activeRun.is_empty() or status not in ["menu","dead"]: return
	var cost := Cards.price(level)
	if profile.totalCoins < cost.coins or profile.railgunModules < cost.modules: return
	profile.totalCoins -= cost.coins
	profile.railgunModules -= cost.modules
	profile.railgunCoinsSpent += cost.coins
	profile.railgunModulesSpent += cost.modules
	profile.railgunLevel += 1
	save_error = not profile_store.save_profile(profile)

func _projectile_travel(origin: Vector2, direction: Vector2) -> float:
	var bounds := _get_playfield_rect(get_viewport_rect().size)
	var distance := INF
	if direction.x > 0.000001: distance = minf(distance,(bounds.end.x-origin.x)/direction.x)
	elif direction.x < -0.000001: distance = minf(distance,(bounds.position.x-origin.x)/direction.x)
	if direction.y > 0.000001: distance = minf(distance,(bounds.end.y-origin.y)/direction.y)
	elif direction.y < -0.000001: distance = minf(distance,(bounds.position.y-origin.y)/direction.y)
	return maxf(0,distance) if distance != INF else 0.0

func _draw_icon_text(font: Font, position: Vector2, value: String, _alignment: int, width: float, pixels: int, color: Color) -> void:
	var icons := {"◈":"coin","▣":"module","✦":"star","★":"star","☆":"star_empty"}
	var cursor := position
	for character in value:
		if cursor.x-position.x > width: break
		if icons.has(character):
			if not hud_icon_textures.has(character): hud_icon_textures[character] = load("res://assets/ui/icons/%s.svg" % icons[character])
			var texture: Texture2D = hud_icon_textures[character]
			draw_texture_rect(texture,Rect2(cursor-Vector2(0,pixels-2),Vector2.ONE*pixels),false,color)
			cursor.x += pixels+2
		else:
			draw_string(font,cursor,character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
			cursor.x += font.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x

func _hud_safe_area(units: float) -> Vector4:
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("(()=>{const e=document.createElement('div');e.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';document.body.appendChild(e);const s=getComputedStyle(e);const v=[s.paddingLeft,s.paddingTop,s.paddingRight,s.paddingBottom].map(parseFloat);e.remove();return v.join(',')})()",true)
		if raw is String:
			var parts: PackedStringArray = raw.split(",")
			if parts.size()==4: return Vector4(float(parts[0]),float(parts[1]),float(parts[2]),float(parts[3]))*units
	elif OS.get_name() in ["Android","iOS"]:
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		return Vector4(safe.position.x,safe.position.y,screen.x-safe.end.x,screen.y-safe.end.y)*units
	return Vector4.ZERO
