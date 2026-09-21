extends SceneTree

const Weapons = preload("res://scripts/systems/weapon_registry.gd")
const Navigation = preload("res://scripts/systems/enemy_navigation.gd")
const Upgrades = preload("res://scripts/systems/upgrade_registry.gd")
const Store = preload("res://scripts/profile_store.gd")
const Enemies = preload("res://scripts/systems/enemy_registry.gd")
const Director = preload("res://scripts/systems/director_system.gd")
const Auto = preload("res://scripts/systems/autopilot.gd")
const Scene = preload("res://scenes/main.tscn")
var failures := 0
var checks := 0
var test_path := ""

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	test_path = OS.get_cache_dir().path_join("void-progression-test-%d.json" % Time.get_ticks_usec())
	root.size = Vector2i(430, 760)
	var store := Store.new()
	store.profile_path = test_path
	var base := Upgrades.defaults()
	var temporary := Upgrades.defaults()
	expect(Upgrades.quote("damage", base, temporary, 7, 1, false).count == 0, "Insufficient cash cannot buy")
	var quote := Upgrades.quote("damage", base, temporary, 30, 10, false)
	expect(quote.count == 3 and is_equal_approx(quote.cost, 27.0), "Buy 10 purchases only affordable levels")
	expect(is_equal_approx(Upgrades.workshop_multiplier("damage", 2), 1.12), "Workshop Attack uses a multiplier-only progression")
	expect(Director.phase(25.99) == "spawning" and Director.phase(26.0) == "cooldown" and Director.get_run_level(35.0) == 2, "Wave phase boundaries")
	for wave in [1, 3, 5, 7, 50, 1000]:
		for seed in range(100):
			var id := Enemies.choose_enemy_type_id(wave, seed)
			expect(id in ["void_drone", "red_scout", "ranged_shooter", "void_tank", "armored_drone"], "Spawn roster excludes bosses and deferred enemies")
			expect(Director.spawn_interval(wave) >= 0.45, "Spawn interval floor")
	var expected_rosters := {1:["void_drone"], 3:["void_drone","red_scout"], 5:["void_drone","red_scout","armored_drone","ranged_shooter"], 7:["void_drone","red_scout","armored_drone","ranged_shooter","void_tank"], 10:["void_drone","red_scout","armored_drone","ranged_shooter","void_tank","void_boss"]}
	for wave in expected_rosters:
		var roster := Enemies.get_wave_roster(int(wave))
		var ids: Array[String] = []
		var chance_total := 0.0
		for entry in roster:
			ids.append(str(entry.id))
			if not bool(entry.guaranteed_boss): chance_total += float(entry.spawn_chance)
		expect(ids == expected_rosters[wave], "Wave Intel roster is data-driven at wave %d" % int(wave))
		expect(is_equal_approx(chance_total, 1.0), "Wave Intel normal spawn chances normalize at wave %d" % int(wave))
		if int(wave) == 10:
			expect(bool(roster[-1].guaranteed_boss) and float(roster[-1].spawn_chance) < 0.0, "Boss is guaranteed only in tenth-wave roster")
	var drone_wave_ten := Enemies.get_stats("void_drone", 10)
	var drone_wave_eleven := Enemies.get_stats("void_drone", 11)
	expect(drone_wave_eleven.hp > drone_wave_ten.hp and drone_wave_eleven.contact_damage > drone_wave_ten.contact_damage, "Wave Intel uses combat scaling after wave 10")
	expect(is_equal_approx(Director.wave_timing(26.0).phase_remaining, 9.0) and Director.wave_timing(315.0).boss_scheduled, "Wave Intel timing exposes phase and boss schedule")
	var legacy := {"saveVersion": 2, "totalCoins": 100, "bestScore": 99, "permanentUpgrades": {"xp_gain": 3, "damage": 2}, "discoveredEnemies": ["splitter"]}
	store._write_json(test_path, legacy)
	var migrated := store.load_profile()
	expect(migrated.saveVersion==Store.SAVE_VERSION and migrated.totalCoins==0 and migrated.permanentUpgrades.damage==0,"Old development profile resets instead of migrating")
	expect(migrated.discoveredEnemies.is_empty() and migrated.bestScore==0,"Reset discards legacy local progression")
	expect(store.load_profile().saveVersion==Store.SAVE_VERSION,"Fresh current profile reload is stable")
	expect(not FileAccess.file_exists(test_path+".v2.bak"),"No legacy migration backup is created")
	migrated.totalCoins = 280.0
	migrated.permanentUpgrades.damage = 2
	store.save_profile(migrated)
	var game = Scene.instantiate()
	game.profile_store.profile_path = test_path
	root.add_child(game)
	game.set_process(false)
	game.profile.activeRun = {}
	game.start_run()
	expect(game.runState.cash == 30.0 and game.run_upgrades.damage == 0, "Fresh run has 30 cash and no temporary levels")
	game._on_panel_action("shop")
	game._buy_upgrade("max_hp", 1)
	expect(is_equal_approx(game.player.max_hp, 148.4) and is_equal_approx(game.player.hp, 148.4) and game.runState.cash == 22.0, "Hull purchase raises and heals hull, charges only cash")
	var before_pause: String = JSON.stringify(Store.encode(game.runState))
	var before_hull: float = game.player.hp
	game._process(1.0)
	expect(JSON.stringify(Store.encode(game.runState)) == before_pause and game.player.hp == before_hull, "Shop pause freezes timers, income and regeneration")
	var wallet_before: float = game.profile.totalCoins
	game.menu_view = "workshop"
	game._buy_upgrade("damage", 1)
	expect(game.profile.totalCoins == wallet_before, "Permanent purchases blocked with an unfinished run")
	game._on_panel_action("resume")
	game.runState.elapsedSeconds = 35.0
	game._update_wave_manager()
	var wave_cash: float = game.runState.cash
	game._update_wave_manager()
	expect(wave_cash == 34.0 and game.runState.cash == wave_cash and game.runState.coinsEarned == 2.0, "Wave reward paid once")
	game.runState.elapsedSeconds = 315.0
	game._update_wave_manager()
	game._update_wave_manager()
	expect(game._count_bosses() == 1 and game.runState.wave == 10, "One boss at tenth-wave boundary")
	var boss: Dictionary = game.enemies[0]
	boss.position = game.player.position
	var coins_before: float = game.runState.coinsEarned
	game._resolve_collisions()
	var hp_after_contact: float = game.player.hp
	expect(game._count_bosses() == 1 and game.runState.coinsEarned == coins_before, "Boss survives contact without reward")
	boss.position = game.player.position
	game._resolve_collisions()
	expect(game.player.hp == hp_after_contact, "Per-enemy contact cooldown prevents frame-based damage")
	game.run_upgrades.cash_bonus = 1
	game.run_upgrades.coin_bonus = 1
	game._spawn_enemy_at({"position": Vector2(50, 100)}, "void_drone")
	var drone: Dictionary = game.enemies[-1]
	var earned: float = game.runState.coinsEarned
	game._grant_enemy_rewards(drone)
	game._grant_enemy_rewards(drone)
	expect(is_equal_approx(game.runState.coinsEarned - earned, 1.05), "Fractional rewards retained and enemy reward deduplicated")
	game.enemies.remove_at(game.enemies.size() - 1)
	boss.hp = 123.5
	boss.contact_cooldown = 0.7
	boss.fire_cooldown = 1.9
	game._fire_at_nearest_enemy()
	game._save_run()
	var snapshot: Dictionary = Store.decode(game.profile.activeRun)
	var expected_rng: String = snapshot.rng_state
	game.player.hp = 1
	game.enemies.clear()
	game._restore_run()
	expect(game.status == "paused" and game.enemies.size() == 1 and game.enemies[0].hp == 123.5, "Encounter resumes paused with boss HP intact")
	expect(is_equal_approx(game.enemies[0].contact_cooldown, 0.7) and is_equal_approx(game.enemies[0].fire_cooldown, 1.9), "Attack cooldowns survive snapshot")
	expect(str(game.rng.state) == expected_rng and game.bullets.size() == snapshot.bullets.size(), "RNG state and active projectiles survive snapshot")
	expect(game.enemies[0].position is Vector2, "JSON vectors restored as vectors")
	var intel_state := JSON.stringify(Store.encode(game.runState))
	game._on_panel_action("wave_intel")
	expect(game.status == "paused" and game.menu_view == "wave_intel", "Wave HUD Intel opens while the run remains paused")
	game._on_panel_action("wave_enemy:void_drone")
	expect(game.menu_view == "codex_detail" and game.codex_detail_origin == "wave_intel", "Wave Intel enemy card opens its Codex detail")
	game._on_panel_action("codex_detail_back")
	expect(game.menu_view == "wave_intel" and JSON.stringify(Store.encode(game.runState)) == intel_state, "Codex detail returns to Wave Intel without mutating the run")
	game.metaProgress.discoveredEnemies = []
	game.profile.discoveredEnemies = []
	game._mark_enemy_discovered(Enemies.BOSS_ID)
	game._mark_enemy_discovered(Enemies.RANGED_SHOOTER_ID)
	var post_encounter_roster: Array = game._get_wave_intel_roster(11)
	expect(post_encounter_roster.any(func(entry: Dictionary): return str(entry.id) == Enemies.BOSS_ID and bool(entry.guaranteed_boss)), "Discovered boss remains visible in Wave 11 Intel")
	var remembered_roster: Array = game._get_wave_intel_roster(1)
	expect(remembered_roster.any(func(entry: Dictionary): return str(entry.id) == Enemies.RANGED_SHOOTER_ID and bool(entry.get("encountered_only", false))), "Wave Intel retains every previously encountered active enemy")
	var projectile_stats := Enemies.get_stats("void_drone", 11)
	expect(is_equal_approx(game._enemy_projectile_damage(Enemies.get_definition("void_drone"), projectile_stats), 0.228), "Wave Intel projectile damage follows scaled combat damage")
	var expected_relative: Vector2 = (game.player.position - game._get_playfield_rect(Vector2(430, 760)).position) / game._get_playfield_rect(Vector2(430, 760)).size
	game._remap_viewport(Vector2(430, 760), Vector2(700, 760))
	var actual_relative: Vector2 = (game.player.position - game._get_playfield_rect(Vector2(700, 760)).position) / game._get_playfield_rect(Vector2(700, 760)).size
	expect(expected_relative.is_equal_approx(actual_relative), "Viewport resize preserves relative playable position")
	game._restore_run()
	game._on_panel_action("resume")
	expect(game.status == "running" and game.menu_view == "main", "Wave Intel Resume continues the run")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var paused_seconds: float = game.runState.elapsedSeconds
	game._process(100.0)
	expect(game.status == "paused" and game.runState.elapsedSeconds == paused_seconds, "Backgrounding pauses with no catch-up progress")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_IN)
	game.profile.autoDodgeUnlocked = true
	game.profile.autoDodgeEnabled = true
	game.player_target = Vector2(100, 200)
	game.manual_override = 1.0
	game._update_autopilot(0.1)
	expect(game.player_target == Vector2(100, 200), "Manual input overrides autopilot")
	var bounds := Rect2(20, 90, 390, 500)
	var target := Auto.choose_target(Vector2(21, 91), bounds, game.enemies, game.enemy_projectiles, 470.0)
	expect(bounds.has_point(target) or bounds.end == target, "Autopilot chooses legal position at a corner")
	var total_before: float = game.profile.totalCoins
	var run_coins: float = game.runState.coinsEarned
	game._on_panel_action("retire")
	expect(game.profile.activeRun.is_empty() and is_equal_approx(game.profile.totalCoins, total_before + run_coins), "Retirement banks coins and clears snapshot atomically")
	game._end_run()
	expect(is_equal_approx(game.profile.totalCoins, total_before + run_coins), "Repeated end-run cannot credit twice")
	var reloaded := store.load_profile()
	expect(reloaded.activeRun.is_empty() and is_equal_approx(reloaded.totalCoins, game.profile.totalCoins), "Settlement persists on reload")
	game.start_run()
	expect(game.run_upgrades.max_hp == 0 and game.profile.permanentUpgrades.damage == 2 and game.runState.cash == 30.0, "Next run resets temporary levels and retains permanent levels")
	game.enemies.clear()
	for index in range(40):
		game._spawn_enemy_at({"position": Vector2(50, 100)}, "void_drone")
	for index in range(4):
		game._spawn_enemy_at({"position": Vector2(100, 100)}, "void_boss")
	game.spawn_timer = 0
	game._update_enemy_spawning(100000)
	expect(game.enemies.size() == 44, "Density cap skips excess normal spawn attempts")
	game.runState.wave = 19
	game.runState.elapsedSeconds = 665.0
	game._update_wave_manager()
	expect(game._count_bosses() == 4 and game.last_boss_wave == 20, "Full boss cap skips scheduled boss without a backlog")
	game.enemies.remove_at(0)
	game._update_enemy_spawning(1)
	expect(game.enemies.size() == 43, "Skipped attempts do not accumulate queued spawns")
	game._end_run()
	game.profile.autoDodgeUnlocked = false
	game.profile.highestWave = 29
	game.profile.totalCoins = 2000.0
	game._on_panel_action("unlock_auto")
	expect(not game.profile.autoDodgeUnlocked, "Auto-Dodge respects wave gate")
	game.profile.highestWave = 30
	game.profile.totalCoins = 999.0
	game._on_panel_action("unlock_auto")
	expect(not game.profile.autoDodgeUnlocked, "Auto-Dodge respects coin cost")
	game.profile.totalCoins = 1000.0
	game._on_panel_action("unlock_auto")
	expect(game.profile.autoDodgeUnlocked and game.profile.totalCoins == 0, "Auto-Dodge purchase persists ownership and charges exactly 1000")
	game._on_panel_action("unlock_auto")
	expect(game.profile.totalCoins == 0, "Auto-Dodge cannot be charged twice")
	# Truncated primary must restore the last good file rather than erasing the profile.
	store.save_profile(game.profile)
	var broken := FileAccess.open(test_path, FileAccess.WRITE)
	broken.store_string("{")
	broken.close()
	expect(store.load_profile().autoDodgeUnlocked, "Corrupt primary recovers last-good backup")
	var restored_profile := store.load_profile()
	var settled_again := store.record_run(restored_profile, {"run_id": restored_profile.settledRunId, "coins_earned": 10000})
	expect(settled_again.totalCoins == restored_profile.totalCoins, "Settled run ID prevents replay after reload")
	_test_range_and_visibility(game)
	_test_workshop_speed_damage(game, store)
	_test_stat_layering(game, store)
	_test_railgun_visuals(game, store)
	# Exercise real container minimum sizes after layout settles at each target.
	root.content_scale_size = Vector2i(430, 760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	for dimensions in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 932), Vector2i(844, 390), Vector2i(1280, 800)]:
		root.size = dimensions
		await process_frame
		game.status = "paused"
		game.menu_view = "pause"
		game._refresh_overlay()
		for frame in range(5):
			await process_frame
			game._layout_buttons()
		var scale := root.get_stretch_transform().get_scale().y
		expect(game.overlay.get_rect().end.y <= game.get_viewport_rect().size.y, "Pause panel fits viewport %s" % dimensions)
		for button in game.overlay.footer.get_children():
			expect(button.size.y * scale >= 44.0, "Touch target >=44 pixels at %s" % dimensions)
			expect(button.get_global_rect().end.y <= game.overlay.get_rect().end.y, "Footer button stays on panel at %s" % dimensions)
		game.menu_view = "shop"
		game._refresh_overlay()
		for frame in range(5):
			await process_frame
			game._layout_buttons()
		expect(game.overlay.scroll.size.y > 60, "Shop rows remain scrollable at %s" % dimensions)
		expect(game.overlay.get_rect().end.y <= game.get_viewport_rect().size.y, "Shop panel fits viewport %s" % dimensions)
		game.runState.wave = 12
		game.menu_view = "wave_intel"
		game._refresh_overlay()
		for frame in range(5):
			await process_frame
			game._layout_buttons()
		expect(game.overlay.scroll.size.y > 60 and game.overlay.get_rect().end.y <= game.get_viewport_rect().size.y, "Wave Intel remains scrollable and in bounds at %s" % dimensions)
		for button in game.overlay.footer.get_children():
			expect(button.size.y * scale >= 44.0 and button.get_global_rect().end.y <= game.overlay.get_rect().end.y, "Wave Intel footer stays tappable at %s" % dimensions)
		game._update_buttons()
		expect(game.wave_control.size.y * scale >= 44.0 and game.wave_control.size.x * scale >= 44.0, "Wave Intel HUD target stays tappable at %s" % dimensions)
		expect(not game.wave_control.get_rect().intersects(game.pause_control.get_rect()), "Wave Intel HUD target does not overlap pause at %s" % dimensions)
		expect(game.speed_control.size.y * scale >= 44 and game.speed_control.size.x * scale >= 44, "Speed target stays tappable at %s" % dimensions)
		expect(not game.pause_control.get_rect().intersects(game.speed_control.get_rect()) and not game.speed_control.get_rect().intersects(game.upgrades_control.get_rect()), "Combat buttons do not overlap at %s" % dimensions)
	_test_enemy_orbits(game)
	_test_gunship_shield(game, store)
	_test_salvos(game)
	_test_fleet_navigation(game)
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".v2.bak"]:
		DirAccess.remove_absolute(test_path + suffix)
	var mirror := {}
	for id in Enemies.get_definitions():
		var definition: Dictionary = Enemies.get_definition(id)
		mirror[id] = {"status": definition.status, "unlockWave": definition.unlock_wave, "weight": definition.spawn.weight, "minRunLevel": definition.spawn.min_run_level, "hp": definition.base_stats.hp, "speed": definition.base_stats.speed, "contactDamage": definition.base_stats.contact_damage, "cashReward": definition.base_stats.get("cash_reward", 0), "coinReward": definition.base_stats.coin_reward, "hpMultiplier": definition.scaling.hp_multiplier, "damageMultiplier": definition.scaling.damage_multiplier, "radius": definition.base_stats.radius, "assetKey": definition.asset_key}
		var cycle: Dictionary = Weapons.cycle(str(definition.attack_behavior)) if Weapons.CYCLES.has(str(definition.attack_behavior)) else {}
		mirror[id].weaponDamage = float(cycle.get("damage",0))
		mirror[id].weaponReload = float(cycle.get("reload",0))
		mirror[id].navigationRadius = float(Navigation.TYPES.get(id,{}).get("radius",0))
	var stat_samples := {}
	var roster_samples := {}
	for id in Enemies.get_definitions():
		stat_samples[id] = {}
		for wave in [1, 10, 11, 35, 36, 60, 200]:
			var stats := Enemies.get_stats(id, wave)
			stat_samples[id][str(wave)] = {"hp": stats.hp, "damage": stats.contact_damage}
	for wave in [1, 3, 5, 7, 10]:
		roster_samples[str(wave)] = Enemies.get_wave_roster(wave).map(func(entry): return {"id":str(entry.id),"chance":float(entry.spawn_chance),"boss":bool(entry.guaranteed_boss),"hp":float(entry.stats.hp),"damage":float(entry.stats.contact_damage)})
	print("ENEMY_STATS:" + JSON.stringify(stat_samples))
	print("ENEMY_WAVE_ROSTERS:" + JSON.stringify(roster_samples))
	print("ENEMY_PARITY:" + JSON.stringify(mirror))
	print("Progression checks: %d passed / %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)

func _test_range_and_visibility(game) -> void:
	game.profile.activeRun = {}
	game.profile.permanentUpgrades = Upgrades.defaults()
	game.start_run()
	game.player.position = Vector2(215, 355)
	game.player_target = game.player.position
	var origin: Vector2 = game.player.position
	expect(is_equal_approx(game._player_radius(),8.64),"Player radius comes from active ship blueprint")
	expect(Upgrades.value("range", 0) == 160 and Upgrades.value("range", 30) == 250, "Range base and cap values")
	var permanent := Upgrades.defaults()
	permanent.range = 28
	expect(Upgrades.quote("range", permanent, {}, 1e8, 10, false).count == 2, "Range Buy 10 respects combined cap")
	expect(Upgrades.quote("range", {}, {}, 7, 1, false).count == 0, "Range rejects insufficient funds")
	game._fire_at_nearest_enemy()
	expect(game.bullets.is_empty(), "No target means no projectile")
	game._spawn_enemy_at({"position": origin + Vector2(160.01, 0)}, "void_drone")
	var target: Dictionary = game.enemies[0]
	game._fire_at_nearest_enemy()
	expect(game.bullets.is_empty(), "Target just outside range is excluded")
	target.position = origin + Vector2(160, 0)
	game._fire_at_nearest_enemy()
	expect(game.bullets.size() == 1, "Target exactly at range is eligible")
	var bullet: Dictionary = game.bullets[0]
	expect(is_equal_approx(bullet.position.x + float(bullet.remaining_distance), game._get_playfield_rect(game.get_viewport_rect().size).end.x), "Travel reaches playfield edge independently of targeting range")
	var budget: float = bullet.remaining_distance
	game._spawn_enemy_at({"position": origin + Vector2(60, 0)}, "red_scout")
	expect(game._nearest_target().id == game.enemies[1].id, "Nearest eligible enemy wins")
	game._on_panel_action("shop")
	game._buy_upgrade("range", 1)
	expect(game.run_upgrades.range == 1 and game._stat("range") == 163 and bullet.remaining_distance == budget, "Buying Range expands reach, not existing shots")
	game._process(1)
	expect(bullet.remaining_distance == budget, "Shopping freezes projectile distance")
	game.player.position += Vector2(0, 20)
	game._save_run()
	game._restore_run()
	expect(game.run_upgrades.range == 1 and game.bullets[0].remaining_distance == budget, "Range levels and projectile budget survive save/resume")
	game.enemies.clear()
	game._update_projectiles(1)
	expect(is_equal_approx(game.bullets[0].position.x, game._get_playfield_rect(game.get_viewport_rect().size).end.x), "Moving ship does not extend a shot; oversized step clamps to playfield edge")
	game._resolve_collisions()
	expect(game.bullets.is_empty(), "Exhausted projectile is removed")
	var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
	game.player.position = Vector2(20, 355)
	game._spawn_enemy_at({"position": Vector2(-1, 355)}, "void_drone")
	target = game.enemies[0]
	game._fire_at_nearest_enemy()
	expect(game.bullets.is_empty(), "In-range offscreen enemy is not targeted")
	game.bullets.append(preload("res://scripts/systems/weapon_registry.gd").build_projectile(90001, target.position, Vector2.LEFT, 1000))
	var hp: float = target.hp
	game._resolve_collisions()
	expect(target.hp == hp, "Existing projectiles cannot damage offscreen enemies")
	target.position.x = float(target.radius) - 0.01
	expect(not game._enemy_is_visible(target), "Partly visible collision circle is not eligible")
	target.position.x = float(target.radius) + 0.01
	expect(game._enemy_is_visible(target), "Fully visible collision circle is eligible")
	# A pre-range snapshot must preserve encounter HP/timers without replaying migration.
	game._save_run()
	var old: Dictionary = Store.decode(game.profile.activeRun)
	old.upgrades.erase("range")
	old.bullets[0].erase("remaining_distance")
	old.bullets[0].life = 1.65
	old.enemies[0].radius = 18 * 0.60
	old.enemies[0].hp = 7.5
	old.enemies[0].fire_cooldown = 1.25
	game.profile.activeRun = Store.encode(old)
	game._restore_run()
	expect(game.run_upgrades.range == 0 and game._stat("range") == 160, "Old snapshot defaults Range to zero")
	expect(game.bullets[0].remaining_distance == 160, "Legacy projectile distance is bounded by base range")
	expect(game.enemies[0].hp == 7.5 and game.enemies[0].fire_cooldown == 1.25 and is_equal_approx(game.enemies[0].radius, 5.184), "Legacy encounter preserves HP/cooldowns and updates radius")
	game.enemies.clear()
	game.bullets.clear()
	game.player.position = origin
	game._spawn_enemy_at({"position": origin + Vector2(150, 0)}, "ranged_shooter")
	target = game.enemies[0]
	expect(game._get_enemy_desired_direction(target, origin).x < 0, "Ranged enemy approaches player's reach")
	target.position = origin + Vector2(120, 0)
	expect(game._get_enemy_desired_direction(target, origin).x > 0, "Ranged enemy retreats only inside preferred band")
	target.position = origin + Vector2(155, 0)
	target.fire_cooldown = 0
	game._update_enemy_weapons(0.1)
	expect(target.attack_warmup_timer == 0, "Ranged enemy does not telegraph beyond 95 percent range")
	target.position = origin + Vector2(150, 0)
	game._update_enemy_weapons(0.1)
	expect(target.attack_warmup_timer > 0, "Ranged enemy telegraphs within reachable distance")
	game.rng.seed = 37
	var rng_state: int = game.rng.state
	var spawn: Dictionary = game._get_regular_spawn_position("void_drone")
	game.rng.state = rng_state
	game.next_id += 999
	expect(game._get_regular_spawn_position("void_drone") == spawn, "Saved RNG controls spawn position independently of projectile IDs")
	var edges := {}
	for index in range(100):
		spawn = game._get_regular_spawn_position("void_drone")
		edges[spawn.edge] = true
		expect(not bounds.has_point(spawn.position), "Spawn center lies just outside playfield")
	expect(edges.size() == 4, "Seeded spawns cover all four edges")
	for wave in [1, 15]:
		game.enemies.clear()
		game.runState.wave = wave
		game.runState.phase = "spawning"
		game.spawn_timer = game.FIRST_ENEMY_SPAWN_DELAY
		for frame in range(780): game._update_enemy_spawning(1000.0 / 30)
		expect(absi(game.enemies.size() - (23 if wave == 1 else 32)) <= 1, "Spawn counts match density at wave %d" % wave)
	game._end_run()
	game.menu_view = "workshop"
	game.profile.totalCoins = 100
	game._buy_upgrade("range", 1)
	expect(game.profile_store.load_profile().permanentUpgrades.range == 1, "Permanent Range survives disk reload")
	game.start_run()
	expect(game.run_upgrades.range == 0 and game._stat("range") == 163, "New run resets temporary Range and retains permanent level")

func _test_workshop_speed_damage(game, store) -> void:
	game.profile = store._default_profile()
	game.metaProgress = game.profile
	game.start_run()
	game._end_run()
	game.menu_view = "workshop"
	game.profile.totalCoins = 1000.0
	game.profile.highestWave = 42
	game.profile.discoveredEnemies = ["void_drone"]
	game._buy_upgrade("damage", 10)
	var paid: float = game.profile.workshopSpent
	var left: float = game.profile.totalCoins
	expect(paid > 0 and is_equal_approx(left + paid, 1000), "Workshop tracks exact purchase spend")
	game._on_panel_action("reset_workshop")
	expect(game.menu_view == "reset_workshop" and game.profile.totalCoins == left, "Reset opens confirmation without crediting")
	game._on_panel_action("cancel_reset")
	expect(game.profile.permanentUpgrades.damage > 0 and game.profile.totalCoins == left, "Cancel reset preserves upgrades and wallet")
	game._on_panel_action("reset_workshop")
	game._on_panel_action("confirm_reset")
	expect(game.profile.totalCoins == 1000 and game.profile.permanentUpgrades.damage == 0 and game.profile.workshopSpent == 0, "Confirmed reset refunds exactly once and clears levels")
	expect(game.profile.highestWave == 42 and game.profile.discoveredEnemies == ["void_drone"], "Workshop reset keeps records and Codex")
	game._on_panel_action("confirm_reset")
	expect(game.profile.totalCoins == 1000 and store.load_profile().totalCoins == 1000, "Repeated confirm/reload cannot duplicate reset refund")
	game._on_panel_action("unlock_auto")
	expect(game.profile.workshopSpent == 1000 and game.profile.autoDodgeUnlocked, "Auto-Dodge spend joins reset ledger")
	game._on_panel_action("reset_workshop")
	game._on_panel_action("confirm_reset")
	expect(game.profile.totalCoins == 1000 and not game.profile.autoDodgeUnlocked, "Reset also refunds Auto-Dodge")
	var current_profile: Dictionary = store._default_profile()
	current_profile.workshopSpent = 180
	expect(store._sanitize_profile(current_profile).workshopSpent==180,"Current Workshop ledger is preserved without legacy inference")
	var no_ledger: Dictionary = store._default_profile(); no_ledger.erase("workshopSpent")
	expect(store._sanitize_profile(no_ledger).workshopSpent==0,"Missing current Workshop ledger defaults cleanly")
	game.start_run()
	game.profile.workshopSpent = 25
	game.profile.permanentUpgrades.damage = 1
	game._save_run()
	var blocked: Dictionary = store.reset_workshop(game.profile)
	expect(blocked.permanentUpgrades.damage == 1 and blocked.totalCoins == game.profile.totalCoins, "Reset refuses an unfinished run")
	game.profile.permanentUpgrades = Upgrades.defaults()
	game.metaProgress = game.profile
	for multiplier in Store.GAME_SPEEDS:
		game.reset_world("running")
		game.profile.settings.gameSpeed = multiplier
		game.player.hp = 100.0
		game._process(0.06)
		expect(is_equal_approx(game.runState.elapsedSeconds, 0.06 * multiplier), "Speed %dx scales combat time" % multiplier)
		expect(is_equal_approx(game.player.hp, 100 + 0.5 * 0.06 * multiplier), "Regeneration follows speed %dx" % multiplier)
		game._pause_run()
		var paused_time: float = game.runState.elapsedSeconds
		game._process(0.1)
		expect(game.runState.elapsedSeconds == paused_time, "Speed %dx cannot advance paused combat" % multiplier)
	game.profile.activeRun = {}
	game.start_run()
	game.profile.settings.gameSpeed = 1
	game.pointer_down = true
	game.player_target = game.player.position + Vector2(40, 0)
	for multiplier in [2, 3, 4, 5, 10, 1]:
		game._on_panel_action("speed")
		expect(game._game_speed() == multiplier, "Speed cycles through all six choices")
	expect(not game.pointer_down and game.player_target == game.player.position, "Speed tap does not steer ship")
	game.profile.settings.gameSpeed = 5
	game._save_run()
	game.profile = store.load_profile()
	game._restore_run()
	expect(game.status == "paused" and game._game_speed() == 5, "Speed persists and saved run resumes paused")
	game._on_panel_action("resume")
	game.enemies.clear()
	game.enemy_projectiles.clear()
	game.player.hp = 100.0
	game.player.shield = 0.0
	game._spawn_enemy_at({"position": game.player.position}, "void_drone")
	var enemy: Dictionary = game.enemies[0]
	game._resolve_collisions()
	expect(game.player.hp == 98 and enemy.has_contacted and game.enemies.size() == 1, "First enemy impact deals 2x base without destroying enemy")
	enemy.position = game.player.position
	game._resolve_collisions()
	expect(game.player.hp == 98, "Impact is not repeated every frame")
	enemy.contact_cooldown = 0
	enemy.position = game.player.position
	game._resolve_collisions()
	expect(game.player.hp == 97, "Subsequent contact ticks use normal damage")
	enemy.position = game.player.position + Vector2(Navigation.safe_distance(enemy) + 13.0, 0)
	Navigation.update([enemy], game.player.position, game._stat("range"), game._get_playfield_rect(game.get_viewport_rect().size), game._fleet_orbit_sign(), 0.0)
	expect(not enemy.contact_latched and enemy.contact_hits_in_pass == 0, "Clearing the player resets the two-hit contact pass")
	enemy.position = game.player.position
	enemy.contact_cooldown = 0.0
	game._resolve_collisions()
	expect(not enemy.contact_latched and enemy.contact_hits_in_pass == 1, "A later pass begins with one contact tick")
	enemy.contact_cooldown = 0.0
	enemy.position = game.player.position
	game._resolve_collisions()
	expect(enemy.contact_latched and enemy.contact_hits_in_pass == 2, "A later pass retreats after its second rapid contact tick")
	game._save_run()
	game._restore_run()
	expect(game.enemies[0].has_contacted, "Contact state survives reload without repeating impact bonus")
	for contact_id in ["void_drone", "red_scout", "ranged_shooter", "void_tank", "void_boss"]:
		game.enemies.clear()
		game._spawn_enemy_at({"position": game.player.position}, contact_id)
		var contact_enemy: Dictionary = game.enemies[0]
		game._resolve_collisions()
		var expected_interval: float = float(Enemies.get_definition(contact_id).base_stats.contact_interval)
		expect(is_equal_approx(float(contact_enemy.contact_cooldown), expected_interval), "Per-type contact cadence applies: " + contact_id)
		if contact_id == "red_scout":
			contact_enemy.contact_cooldown = 0.0
			contact_enemy.position = game.player.position
			game._resolve_collisions()
			expect(bool(contact_enemy.contact_latched) and float(contact_enemy.nav_target_distance) > Navigation.safe_distance(contact_enemy), "Scout returns to its outer orbit after fast follow-up contact")
	game.enemies.clear()
	game.player.hp = 97.0
	var center: Vector2 = game.player.position
	game.enemy_projectiles.append({"id": 80000, "position": center + Vector2(40, 0), "previous_position": center - Vector2(40, 0), "velocity": Vector2.RIGHT * 190, "radius": 4.8, "damage": 3.0, "life": 1.0})
	game.run_upgrades.armor = 10
	game._resolve_collisions()
	expect(is_equal_approx(game.player.hp, 92.5), "Swept projectile collision applies doubled damage and armor exactly once")
	expect(game.enemy_projectiles.is_empty(), "Hit projectile is removed")
	expect(not game.damage_numbers.is_empty() and game.player_damage_flash > 0 and game.hull_damage_trail > game.player.hp, "Real damage drives ship flash, numbers and hull trail")
	var feedback_life: float = game.damage_numbers[-1].life
	game._on_panel_action("resume")
	game._process(0.02)
	expect(is_equal_approx(game.damage_numbers[-1].life, feedback_life - 0.02), "Damage feedback uses real time at 5x")
	game._pause_run()
	feedback_life = game.damage_numbers[-1].life
	game._process(0.1)
	expect(game.damage_numbers[-1].life == feedback_life, "Menus freeze damage feedback")
	game._end_run()

func _test_railgun_visuals(game, store) -> void:
	var weapons = load("res://scripts/systems/weapon_registry.gd")
	var effects = load("res://scripts/systems/effect_registry.gd")
	expect(weapons.PROJECTILE_SPEED == 1600.0, "Railgun projectile speed")
	expect(weapons.canonical_id("pulse_cannon") == "railgun", "Legacy weapon alias")
	expect(is_equal_approx(weapons.hit_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(60, 0), 10), 0.5), "Swept intersection is first circle entry")
	expect(weapons.hit_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(60, 20), 10) == INF, "Swept near miss is not damage")
	expect(weapons.hit_fraction(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, 10) == 0.0, "Round starting inside circle hits")
	game.profile = store._default_profile()
	game.metaProgress = game.profile
	game.start_run()
	game.enemies.clear()
	var origin := Vector2(170, 300)
	game.player.position = origin + Vector2(0, 100)
	# Reverse array order deliberately; one fast round must hit the near target only.
	game._spawn_enemy_at({"position": origin + Vector2(80, 0)}, "void_drone")
	game._spawn_enemy_at({"position": origin + Vector2(40, 0)}, "void_drone")
	var far: Dictionary = game.enemies[0]
	var near: Dictionary = game.enemies[1]
	var round: Dictionary = weapons.build_projectile(99001, origin, Vector2.RIGHT, 8, false, 100)
	game.bullets.assign([round])
	game._update_projectiles(0.0625)
	game._resolve_collisions()
	expect(near.hp == 8 and far.hp == 16 and game.bullets.is_empty(), "Fast rail round hits nearest target once and does not pierce")
	var traces: Array = game.particles.filter(func(p): return p.get("kind", "") == "rail_trace")
	expect(traces.size() == 1 and traces[0].end.x < near.position.x, "Trace terminates at impact surface")
	game.enemies.clear()
	game._spawn_enemy_at({"position": origin + Vector2(80, 0)}, "void_drone")
	game.bullets.assign([weapons.build_projectile(99002, origin, Vector2.RIGHT, 100, false, 30)])
	game._update_projectiles(0.1)
	game._resolve_collisions()
	expect(game.enemies[0].hp == 16 and game.bullets.is_empty(), "High speed cannot extend Range")
	game.particles.clear()
	var saved_rng: int = game.rng.state
	var saved_id: int = game.next_id
	var boss := {"type_id": "void_boss", "position": origin, "radius": 22.8}
	game._add_enemy_death_explosion(boss, Color.ORANGE)
	expect(game.rng.state == saved_rng and game.next_id == saved_id, "Boss VFX do not consume gameplay RNG or entity IDs")
	var explosions: Array = game.particles.filter(func(p): return p.get("kind", "") in ["explosion", "boss_explosion"])
	expect(explosions.size() == 4 and explosions[3].delay == 0.4, "Boss destruction has three staggered blasts and central explosion")
	game._update_visual_effects(0.2)
	expect(is_equal_approx(explosions[3].life, 0.6), "Delayed boss explosion keeps full animation duration")
	game._update_visual_effects(1.0)
	expect(game.particles.is_empty(), "Boss debris and explosions complete within one second")
	for index in range(170): game._append_effect(effects.make("explosion", origin))
	game._append_effect(effects.make("debris", origin))
	expect(game.particles.size() == 170 and game.particles.all(func(p): return p.kind == "explosion"), "Low priority debris cannot evict impact/explosion at cap")
	game.particles.clear()
	game._append_effect(effects.make("debris", origin))
	for index in range(170): game._append_effect(effects.make("rail_impact", origin))
	expect(game.particles.size() == 170 and game.particles.all(func(p): return p.kind == "rail_impact"), "Old decorative debris evicted first")
	game.particles.clear()
	game._append_effect(effects.make("explosion", origin))
	game.profile.settings.gameSpeed = 5
	game.status = "running"
	game.fire_timer = 1e8
	game.spawn_timer = 1e8
	game.enemies.clear()
	game._process(0.02)
	expect(is_equal_approx(game.particles[0].life, 0.33), "5x keeps explosion lifetime in real seconds")
	game.status = "paused"
	var frozen := JSON.stringify(game.particles)
	game._process(0.1)
	expect(JSON.stringify(game.particles) == frozen, "Pause freezes all visual effects")
	var frame_hashes := {}
	for index in range(8):
		var texture: Texture2D = game.explosion_frames[index]
		expect(texture != null and texture.get_size() == Vector2(384, 512), "Explosion has stable frame canvas %d" % index)
		var frame := texture.get_image()
		frame_hashes[hash(frame.get_data())] = true
		expect(frame.get_pixel(0, 0).a == 0.0, "Explosion alpha is transparent %d" % index)
		expect(effects.frame_index((index + 0.1) / 8.0) == index, "Chronological frame selection %d" % index)
	expect(frame_hashes.size() == 8, "Explosion uses eight distinct frames")
	game.bullets.assign([{"id": 99003, "position": origin, "velocity": Vector2(540, 0), "damage": 17, "life": 0.1, "remaining_distance": 54.0, "weapon_id": "pulse_cannon"}])
	game._save_run()
	game._restore_run()
	expect(game.bullets[0].weapon_id == "railgun" and game.bullets[0].velocity == Vector2(540, 0) and game.bullets[0].damage == 17 and game.bullets[0].remaining_distance == 54.0, "Legacy projectile alias retains speed, damage and travel budget")
	expect(game.status == "paused", "Legacy projectile run resumes paused")
	var current: Dictionary = store._default_profile()
	expect(current.unlockedShips == ["starter_ship"] and current.equipmentInventory.size()==2,"Current profile owns starter ship and equipment instances")

func _test_enemy_orbits(game) -> void:
	game.profile.activeRun = {}
	game.start_run()
	game.player.position = game._get_playfield_rect(game.get_viewport_rect().size).get_center()
	var center: Vector2 = game.player.position
	for id in ["void_drone", "red_scout", "void_tank", "armored_drone"]:
		for spin in [-1.0, 1.0]:
			game.enemies.clear()
			game._spawn_enemy_at({"position": center + Vector2(110, 0)}, id)
			var enemy: Dictionary = game.enemies[0]
			enemy.orbit_sign = spin
			var safe: float = game.EnemyNavigation.safe_distance(enemy)
			for frame in range(900):
				game._update_enemy_movement(1.0/60.0)
				expect(enemy.position.distance_to(center)>=safe-1.0,"Ranged fleet avoids deliberate contact: "+id)
				expect(enemy.velocity.length()<=float(game.EnemyNavigation.TYPES[id].top)+0.001,"Fleet respects type speed cap: "+id)
			expect(enemy.position.distance_to(center)<=game._stat("range")*1.08,"Fleet stays within useful firing/pass distance: "+id)
	game.enemies.clear()
	game._spawn_enemy_at({"position": center + Vector2(110, 0)}, "ranged_shooter")
	var shooter: Dictionary = game.enemies[0]
	for frame in range(600): game._update_enemy_movement(1.0 / 60.0)
	var distance: float = shooter.position.distance_to(center)
	expect(distance >= game._stat("range") * 0.8 and distance <= game._stat("range") * 0.93, "Shooter smoothly settles into reachable orbit")
	shooter.velocity = Vector2(10, -10)
	for speed in Store.GAME_SPEEDS:
		game.profile.settings.gameSpeed = speed
		shooter.visual_rotation = PI
		game._update_visual_effects(0.5)
		expect(absf(wrapf(game._enemy_visual_rotation(shooter) - PI / 4, -PI, PI)) < 0.01, "Sprite nose follows diagonal velocity at speed %d" % speed)
	var saved_rotation: float = shooter.visual_rotation
	var saved_spin: float = shooter.orbit_sign
	shooter.hp = 7.25
	shooter.fire_cooldown = 0.8
	game._save_run()
	game._restore_run()
	expect(game.status == "paused" and is_equal_approx(game.enemies[0].visual_rotation, saved_rotation) and game.enemies[0].orbit_sign == saved_spin, "Resume preserves angle and orbit handedness")
	expect(game.enemies[0].hp == 7.25 and game.enemies[0].fire_cooldown == 0.8, "Orbit resume preserves encounter HP and cooldown")
	var before: String = JSON.stringify(Store.encode(game.enemies))
	game._process(1.0)
	expect(JSON.stringify(Store.encode(game.enemies)) == before, "Paused orbit and facing freeze")
	var old: Dictionary = Store.decode(game.profile.activeRun)
	old.enemies[0].erase("orbit_sign")
	old.enemies[0].erase("visual_rotation")
	old.enemies[0].movement_behavior = "chase"
	var rng_before: String = old.rng_state
	game.profile.activeRun = Store.encode(old)
	game._restore_run()
	expect(game.enemies[0].movement_behavior == "spiral_orbit" and game.enemies[0].has("orbit_sign") and str(game.rng.state) == rng_before, "Legacy movement restored with deterministic orbit default and unchanged RNG")
	expect(is_equal_approx(float(Enemies.get_definition("void_boss").base_stats.radius), 47.5) and is_equal_approx(float(Enemies.get_definition("void_boss").visual_canvas_height), 255.0), "Boss size is unchanged")
	for id in Enemies.get_definitions():
		var definition: Dictionary = Enemies.get_definition(id)
		var path := "res://assets/enemies/%s/idle-up.png" % definition.asset_key
		var frame := Image.load_from_file(ProjectSettings.globalize_path(path))
		expect(frame != null and frame.get_size() == Vector2i(384, 512), "Stable up canvas exists: " + id)
		if id in ["void_drone", "red_scout"]:
			var bounds := frame.get_used_rect()
			expect(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 384 and bounds.end.y < 512, "New ship has transparent edge padding: " + id)

func _test_gunship_shield(game, store) -> void:
	var Shield = load("res://scripts/systems/shield_system.gd")
	game.profile = store._default_profile()
	game.metaProgress = game.profile
	game.start_run()
	expect(game.player.shield == 30 and game.player.max_shield == 30, "New run starts with charged baseline shield")
	var hp: float = game.player.hp
	var result: Dictionary = game._apply_damage_to_player(8.0, "HIT", game.player.position + Vector2(8,0), Vector2.LEFT)
	expect(result.shield == 8 and result.hull == 0 and game.player.hp == hp and game.player.shield == 22, "Shield fully absorbs hit")
	expect(game.player_damage_flash == 0 and game.damage_numbers[-1].source == "SHIELD", "Shield-only hit avoids hull flash and has separate feedback")
	game.player.shield = 2.5
	game.run_upgrades.armor = 10
	result = game._apply_damage_to_player(game._get_incoming_damage(4.0), "IMPACT")
	expect(is_equal_approx(result.hull, 0.5) and result.shield == 2.5 and result.broken, "Armor applied once before fractional shield overflow without second minimum")
	expect(game.player.shield_delay == 3, "Every damaging hit sets three-second delay")
	Shield.update(game.player, 2.9, 3)
	expect(game.player.shield == 0, "No charge before delay ends")
	Shield.update(game.player, 0.2, 3)
	expect(is_equal_approx(game.player.shield, 0.3), "Only remainder beyond delay contributes to charge")
	game._apply_damage_to_player(1)
	expect(game.player.shield_delay == 3 and game.player.shield == 0, "Hit resets partial charge and cooldown")
	game._apply_damage_to_player(1)
	expect(game.player.shield_delay == 3, "Hit resets delay even with empty shield")
	Shield.update(game.player, 100, 3)
	expect(game.player.shield == game.player.max_shield, "Recharge clamps to capacity")
	var upgraded_core: Dictionary = game.EquipmentRegistry.shield_core_stats(20)
	expect(upgraded_core.capacity > 30.0 and upgraded_core.recharge > 0.5 and upgraded_core.recharge_delay < 3.0, "Shield Core milestones own capacity, recharge and restart delay")
	game.player.shield = 4.0
	game.player.shield_delay = 2.25
	game.profile.settings.gameSpeed = 10
	game.rail_direction = Vector2.LEFT
	game._save_run()
	game.profile = store.load_profile()
	game._restore_run()
	expect(game.status == "paused" and game._game_speed() == 10 and game.player.shield == 4 and game.player.shield_delay == 2.25, "10x and exact shield state survive profile reload")
	expect(game.rail_direction == Vector2.LEFT, "Turret heading survives snapshot")
	var snapshot: Dictionary = Store.decode(game.profile.activeRun)
	var saved_hp: float = game.player.hp
	snapshot.player.erase("shield_delay")
	snapshot.player.shield = 0
	snapshot.player.max_shield = 0
	snapshot.upgrades.erase("shield_capacity")
	snapshot.upgrades.erase("shield_recharge")
	game.profile.activeRun = Store.encode(snapshot)
	game._restore_run()
	expect(game.player.shield == 0 and game.player.max_shield == 30 and game.player.shield_delay == 3 and game.player.hp == saved_hp, "Legacy encounter gains empty baseline shield without healing")
	for speed in Store.GAME_SPEEDS:
		game.status = "running"
		game.runState.status = "running"
		game.profile.settings.gameSpeed = speed
		game.player.shield = 0.0
		game.player.shield_delay = 0.0
		game.enemies.clear()
		game.enemy_projectiles.clear()
		game._process(0.05)
		expect(is_equal_approx(game.player.shield, 0.5 * 0.05 * speed), "Shield recharge follows speed %d" % speed)
		game._pause_run()
		var charge: float = game.player.shield
		var visual: float = game.gunship.time
		game._process(0.1)
		expect(game.player.shield == charge and game.gunship.time == visual, "Pause freezes shield and animation at %d" % speed)
	expect(Store.valid_speed(10) == 10 and Store.valid_speed(9) == 1 and Store.valid_speed(-1) == 1, "Speed allowlist rejects unsupported values")
	game.gunship.reset()
	for sample in [[0.59,1],[0.62,1],[0.66,0],[0.29,2],[0.33,2],[0.36,1],[0.7,0]]:
		game.player.hp = game.player.max_hp * sample[0]
		game.gunship.update(game, 0.1)
		expect(game.gunship.damage_state == sample[1], "Damage art has threshold hysteresis")
	game.pointer_down = false
	for direction in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]:
		game.rail_direction = direction
		game.gunship.update(game, 0.1)
		expect(game.gunship.bank == 0, "Turret target changes never turn hull")
	game.gunship.hit({"hull":0,"shield":1,"broken":false}, Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, "HIT")
	expect(is_equal_approx(absf(game.gunship.hit_angle), PI), "Center-crossing projectile feedback uses incoming side")
	game.pointer_down = true
	game.player_target = game.player.position + Vector2(100,0)
	game._update_player(1.0/60.0)
	game.gunship.update(game, 0.5)
	expect(game.gunship.bank > deg_to_rad(5.0) and game.gunship.bank <= deg_to_rad(6.0), "Real manual movement banks within six-degree limit")
	game.pointer_down = false
	game.gunship.update(game, 1.0)
	expect(absf(game.gunship.bank) < 0.001, "Hull returns upright after steering")
	var intact := Image.load_from_file(ProjectSettings.globalize_path("res://assets/player_ship/gunship/intact.png"))
	for state in ["damaged", "critical"]:
		var frame := Image.load_from_file(ProjectSettings.globalize_path("res://assets/player_ship/gunship/%s.png" % state))
		var same_alpha := frame.get_size() == Vector2i(384,512)
		for y in range(512):
			for x in range(384):
				if frame.get_pixel(x,y).a != intact.get_pixel(x,y).a: same_alpha = false
		expect(same_alpha, "Damage frame shares exact alpha/pivot with intact master: " + state)
	game.gunship.reset()
	var pulses := 0
	for index in range(120):
		game.gunship.update(game, 1.0 / 120.0)
		if game.gunship.allow_weapon_pulse(): pulses += 1
	expect(pulses <= 12, "High-speed cosmetic pulses capped at twelve per second")
	var wallet: float = game.profile.totalCoins
	game.runState.coinsEarned = 17.0
	game.player.hp = 0.0
	game.app_backgrounded = false
	game._end_run(true)
	expect(game.status == "dead" and game.death_timer == 0.8 and game.profile.totalCoins == wallet + 17 and not game.overlay.visible, "Death settles immediately and delays result overlay")
	var wave_time: float = game.runState.elapsedSeconds
	game.app_backgrounded = true
	game._process(0.1)
	expect(game.death_timer == 0.8, "Background freezes destruction presentation")
	game.app_backgrounded = false
	for frame in range(8): game._process(0.1)
	expect(game.death_timer == 0 and game.overlay.visible and game.runState.elapsedSeconds == wave_time, "Death animation reveals result without combat progress")
	game._end_run(true)
	expect(game.profile.totalCoins == wallet + 17, "Death cannot credit twice")
	game.profile.activeRun = {}
	game.start_run()
	game._pause_run()
	game._on_panel_action("retire")
	expect(game.death_timer == 0 and game.overlay.visible, "Retire skips destruction")
	var legacy_profile: Dictionary = store._default_profile()
	legacy_profile.saveVersion = 9
	legacy_profile.permanentUpgrades.shield_capacity = 3
	legacy_profile.permanentUpgrades.shield_recharge = 2
	var migrated_profile: Dictionary = store._migrate_shield_core_profile(legacy_profile)
	var migrated_core: Dictionary = migrated_profile.equipmentItems[game.EquipmentRegistry.SHIELD_CORE_INSTANCE_ID]
	expect(not migrated_profile.permanentUpgrades.has("shield_capacity") and migrated_core.legacy_capacity_bonus == 30.0 and migrated_core.legacy_recharge_bonus == 1.0, "Shield Workshop investment migrates into the Shield Core without loss")

func _test_stat_layering(game, store) -> void:
	game.profile = store._default_profile()
	game.metaProgress = game.profile
	game.start_run()
	var ship_state: Dictionary = game.profile.ships[game._active_ship_id()]
	ship_state.upgrade_level = 10
	game.profile.permanentUpgrades.damage = 2
	game.profile.permanentUpgrades.shield_capacity = 2
	game.metaProgress = game.profile
	var chassis_damage: float = game._ship_base_stat("damage")
	expect(is_equal_approx(chassis_damage, 13.0), "Chassis owns the weapon damage baseline")
	expect(is_equal_approx(game._stat("damage"), chassis_damage * 1.12), "Workshop damage is a multiplier over chassis damage")
	var railgun_stats: Dictionary = game._weapon_runtime_stats({"item":game._railgun_instance(),"blueprint":game.EquipmentRegistry.definition(game.EquipmentRegistry.RAILGUN_ID)})
	expect(is_equal_approx(float(railgun_stats.damage), game._stat("damage")), "Railgun module consumes the layered ship damage")
	expect(is_equal_approx(game._stat("shield_capacity"), 30.0 * 1.10), "Shield module is the authoritative shield base before Workshop scaling")
	expect(is_equal_approx(game._stat("range"), game._ship_base_stat("range")), "Weapon range starts from the chassis baseline")
	game.profile = store._default_profile()
	game.metaProgress = game.profile
	game.status = "menu"
	game.start_run()

func _test_salvos(game) -> void:
	var weapons = game.WeaponRegistry
	var enemy_weapons = game.EnemyWeapons
	game.profile = game.profile_store._default_profile()
	game.start_run()
	game.fire_timer = 0.0
	game._update_weapons(5000.0)
	expect(game.bullets.is_empty() and game.player.weapon.ammo == 6, "No target never consumes ammunition")
	expect(is_equal_approx(game._get_weapon_fire_interval(), 500.0), "Railgun owns its fire interval instead of Workshop")
	expect(game.EquipmentRegistry.shield_core_stats(1).recharge == 0.5 and game.EquipmentRegistry.shield_core_stats(15).recharge > 1.0, "Shield recharge scales through Shield Core levels")
	game._spawn_enemy_at({"position":game.player.position + Vector2(80,0)}, "void_tank")
	for shot in range(6): game._update_weapons(0.0 if shot == 0 else 500.0)
	expect(game.bullets.size()==6 and game.player.weapon.ammo==0 and game.player.weapon.reload_timer==3.0,"Six player shots enter the existing three-second reload")
	game._update_weapons(2999.0)
	expect(game.bullets.size() == 6, "Player cannot fire before reload completes")
	game._update_weapons(1.0)
	expect(game.bullets.size() == 7 and game.player.weapon.ammo == 5, "Reload completion fires immediately without extra interval")
	game.enemies.clear()
	game.player.weapon = {"ammo":0,"reload_timer":3.0}
	game._update_weapons(3000.0)
	expect(game.player.weapon.ammo == 6 and game.bullets.size() == 7, "Reload proceeds without target, without firing")
	game.player.shield = 0.0
	game.player.shield_delay = 3.0
	game._update_effects(3.0)
	expect(game.player.shield == 0.0 and game.player.shield_delay == 0.0, "Three full game seconds before shield recovery")
	game._update_effects(1.0)
	expect(game.player.shield == 0.5, "Level zero shield recovers half a point per second")
	game._spawn_enemy_at({"position":game.player.position + Vector2(160,0)}, "void_drone")
	game.gunship.reset()
	game.gunship.update(game, 0.1)
	expect(is_equal_approx(game.gunship.shield_visibility,0.5), "Shield fades halfway in after 0.1 real seconds at exact Range")
	game.gunship.update(game, 0.1)
	expect(game.gunship.shield_visibility == 1.0, "Shield fully visible after 0.2 seconds")
	game.enemies[0].position.x += 1.0
	game.gunship.update(game, 0.2)
	expect(game.gunship.shield_visibility == 0.0, "Shield fades out when enemies leave Range")
	game.player.shield = 10.0
	var hull: float = game.player.hp
	game._apply_damage_to_player(2, "HIT", game.player.position + Vector2(10,0))
	game.gunship.update(game,0.01)
	expect(game.player.hp == hull and game.player.shield == 8 and game.gunship.shield_flash > 0, "Invisible contour still absorbs damage and reveals impact")

	game.enemies.clear()
	game.enemy_projectiles.clear()
	game._spawn_enemy_at({"position":game.player.position + Vector2(90,0)}, "ranged_shooter")
	var shooter: Dictionary = game.enemies[-1]
	shooter.fire_cooldown = 0.0
	game._update_enemy_weapons(0.0)
	var locked: Vector2 = shooter.attack_direction
	game.player.position.y += 20
	game._update_enemy_weapons(0.299)
	expect(game.enemy_projectiles.is_empty() and shooter.attack_direction == locked, "Rift warning holds direction and cannot fire early")
	game._update_enemy_weapons(0.001)
	expect(game.enemy_projectiles.size() == 1 and is_equal_approx(game.enemy_projectiles[0].velocity.length(),1600), "Rift fires a high-speed round after warning")
	expect(game.enemy_projectiles[0].position.is_equal_approx(enemy_weapons.origin(game,shooter)), "Railgun round starts at the drawn muzzle anchor")
	expect(game.enemy_projectiles[0].visual_trail_points == [game.enemy_projectiles[0].position], "Enemy rail shot starts with visual-only path history")
	game._update_enemy_weapons(0.2)
	game._update_enemy_weapons(0.3)
	game._update_enemy_weapons(0.2)
	game._update_enemy_weapons(0.3)
	expect(game.enemy_projectiles.size() == 3 and shooter.ammo == 0 and shooter.reload_timer == weapons.cycle("enemy_railgun").reload, "Rift three-round magazine with 0.5-second intervals")
	game._update_enemy_weapons(float(weapons.cycle("enemy_railgun").reload)-0.001)
	expect(game.enemy_projectiles.size() == 3, "Rift cannot fire during reload")
	game._update_enemy_weapons(0.001)
	expect(shooter.ammo == 3 and shooter.reload_timer == 0 and shooter.attack_warmup_timer > 0, "Rift reload completion begins new warning")
	game.enemies.clear()
	game.enemy_projectiles.clear()
	game._spawn_enemy_at({"position":game.player.position + Vector2(80,0)}, "void_drone")
	var drone: Dictionary = game.enemies[-1]
	drone.fire_cooldown = 0.0
	drone.attack_warmup_timer = 0.0
	game._update_enemy_weapons(0.0)
	var locked_target: Vector2 = drone.attack_target
	drone.position += Vector2(0, 30)
	game._update_enemy_weapons(0.45)
	var drone_shot: Dictionary = game.enemy_projectiles[0]
	var shot_end: Vector2 = drone_shot.position + Vector2(drone_shot.velocity).normalized() * 200.0
	expect(Weapons.hit_fraction(drone_shot.position, shot_end, locked_target, float(game.player.radius) + float(drone_shot.radius)) != INF, "Moving Void Drone still fires through its locked warning target")

	game.enemies.clear()
	game.enemy_projectiles.clear()
	game._spawn_enemy_at({"position":game.player.position + Vector2(80,0)}, "void_boss")
	var boss: Dictionary = game.enemies[-1]
	boss.fire_cooldown = 0.0
	game._update_enemy_weapons(0.0)
	var origin: Vector2 = enemy_weapons.origin(game,boss)
	game._update_enemy_weapons(0.6)
	expect(game.enemy_projectiles.size() == 1 and game.enemy_projectiles[0].position.is_equal_approx(origin), "Boss launch matches warned shoulder anchor")
	expect(game.enemy_projectiles[0].visual_trail_points == [origin], "Boss rocket starts with visual-only path history")
	expect(boss.reload_timer == 4.0 and boss.launcher_index == 1, "Single rocket starts four-second reload and alternates launcher")
	game._update_enemy_weapons(4.0)
	game._update_enemy_weapons(0.6)
	expect(game.enemy_projectiles.size() == 2 and boss.launcher_index == 0, "Second rocket uses other launcher")
	game._update_enemy_weapons(4.0)
	game._update_enemy_weapons(10.0)
	expect(game.enemy_projectiles.size() == 2 and boss.ammo == 1, "Per-boss cap waits without consuming ammunition or accumulating shots")
	game._spawn_enemy_at({"position":game.player.position + Vector2(-80,0)}, "void_boss")
	game.enemies[-1].fire_cooldown = 0.0
	game._update_enemy_weapons(0.6)
	expect(enemy_weapons.active_rockets(game,int(boss.id)) == 2 and game.enemy_projectiles.size() == 3, "Another boss owns an independent two-rocket allowance")
	game.enemy_projectiles.remove_at(0)
	game._update_enemy_weapons(0.0)
	expect(boss.attack_warmup_timer == 0.6, "Freed rocket slot still requires warning, no backlog launch")
	var rocket: Dictionary = game.enemy_projectiles[0]
	rocket.velocity = Vector2.RIGHT * 85.0
	game.player.position = rocket.position + Vector2(0,100)
	var start: Vector2 = rocket.position
	enemy_weapons.move_projectile(game,rocket,0.1)
	expect(is_equal_approx(rocket.velocity.angle(),deg_to_rad(3.5)) and is_equal_approx(rocket.position.distance_to(start),8.5), "Rocket speed and turn are bounded")
	expect(rocket.visual_trail_points.size() > 1, "Boss rocket records a smooth presentation trail without changing movement")
	rocket.life = 0.01
	start = rocket.position
	enemy_weapons.move_projectile(game,rocket,0.1)
	expect(is_equal_approx(start.distance_to(rocket.position),0.85) and rocket.life == 0, "Rocket movement stops exactly at remaining lifetime")

	game.enemies.clear()
	game.bullets.clear()
	game.enemy_projectiles.clear()
	game.run_upgrades.armor = 10
	game.player.shield = 2.0
	game.player.hp = 100.0
	game.enemy_projectiles.append({"id":999,"owner_id":999,"weapon_id":"boss_rocket","position":game.player.position+Vector2(50,0),"previous_position":game.player.position-Vector2(50,0),"radius":3.2,"velocity":Vector2.RIGHT*85,"damage":6.0,"damage_multiplier":1.0,"life":1.0})
	game._resolve_collisions()
	expect(is_equal_approx(game.player.hp,97.5) and game.player.shield == 0, "Rocket swept collision applies Armor once, then shield, then 2.5 hull damage")
	expect(game.particles.any(func(effect): return str(effect.get("kind","")) == "enemy_missile_impact"), "Boss rocket impact uses compact enemy-colored missile feedback")
	game._resolve_collisions()
	expect(is_equal_approx(game.player.hp,97.5), "Rocket is consumed at first impact and cannot deal damage twice")

	game._spawn_enemy_at({"position":game.player.position + Vector2(-80,0)},"void_boss")
	boss = game.enemies[-1]
	boss.flight_heading = 0.5
	boss.attack_direction = Vector2(0.6,0.8)
	boss.attack_warmup_timer = 0.27
	boss.hp = 123.0
	boss.fire_cooldown = 0.0
	game.player.weapon = {"ammo":0,"reload_timer":1.234}
	game._fire_enemy_projectile(boss)
	game.enemy_projectiles[-1].life = 6.543
	game._save_run()
	var saved: Dictionary = Store.decode(game.profile.activeRun)
	game._restore_run()
	expect(game.status == "paused" and is_equal_approx(game.player.weapon.reload_timer,1.234), "Player magazine/reload resumes paused exactly")
	boss = game.enemies[0]
	expect(boss.hp == 123.0 and boss.flight_heading == 0.5 and is_equal_approx(boss.attack_warmup_timer,0.27) and boss.attack_direction.is_equal_approx(Vector2(0.6,0.8)), "Boss encounter preserves heading, locked aim, HP and warning")
	expect(is_equal_approx(game.enemy_projectiles[0].life,6.543) and game.enemy_projectiles[0].owner_id == boss.id, "Rocket ownership/lifetime survives save")
	var paused: String = JSON.stringify(Store.encode(game.player))
	var warning: float = boss.attack_warmup_timer
	var visible: float = game.gunship.shield_visibility
	game._process(0.1)
	expect(JSON.stringify(Store.encode(game.player)) == paused and boss.attack_warmup_timer == warning and game.gunship.shield_visibility == visible, "Pause freezes recharge, reload, warning and visual shield fade")
	saved.player.erase("weapon")
	saved.fire_timer = 321.0
	for enemy in saved.enemies:
		enemy.erase("ammo")
		enemy.erase("reload_timer")
		enemy.erase("flight_heading")
		enemy.erase("attack_direction")
		enemy.fire_cooldown = 1.25
		enemy.attack_behavior = "contact"
	saved.enemy_projectiles[0].velocity = Vector2(123,45)
	saved.enemy_projectiles[0].damage = 8.75
	game.profile.activeRun = Store.encode(saved)
	game._restore_run()
	expect(game.player.weapon.ammo == 6 and game.player.weapon.reload_timer == 0 and game.fire_timer == 321, "Legacy player gets full magazine while retaining shot cooldown")
	expect(game.enemies[0].ammo == 1 and game.enemies[0].fire_cooldown == 1.25 and game.enemies[0].attack_behavior == "boss_rocket", "Legacy boss gains rocket cycle without changing existing cooldown")
	expect(game.enemy_projectiles[0].velocity.is_equal_approx(Vector2(123,45)) and game.enemy_projectiles[0].damage == 8.75, "Legacy projectiles retain velocity and damage")
	# Owner death must not remove a missile already launched.
	var launched_id: int = game.enemy_projectiles[0].id
	game.enemies.clear()
	game.player.position += Vector2(0,80)
	game._update_projectiles(0.01)
	game._resolve_collisions()
	expect(game.enemy_projectiles.any(func(shot): return int(shot.id) == launched_id), "Rockets remain alive after owner is removed")
	game.enemy_projectiles[0].position = Vector2(-100,-100)
	game._remove_expired_enemy_projectiles({})
	expect(game.enemy_projectiles.size() == 1, "Guided missile outside viewport retains its lifetime and owner slot")
	game.status = "running"
	var saved_reload: float = game.player.weapon.reload_timer
	var saved_rocket_life: float = game.enemy_projectiles[0].life
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._process(0.1)
	expect(game.status == "paused" and game.player.weapon.reload_timer == saved_reload and game.enemy_projectiles[0].life == saved_rocket_life, "Backgrounding freezes reload and active missile lifetime")
	game.app_backgrounded = false
	for speed in [1,2,3,4,5,10]:
		game.profile.activeRun = {}
		game.start_run()
		game.profile.settings.gameSpeed = speed
		game.player.weapon = {"ammo":0,"reload_timer":2.0}
		game._process(0.05)
		expect(is_equal_approx(game.player.weapon.reload_timer, 2.0 - speed * 0.05), "Player reload follows speed %d" % speed)
		game._spawn_enemy_at({"position":game.player.position + Vector2(60,0)}, "void_boss")
		boss = game.enemies[-1]
		boss.reload_timer = 4.0
		boss.ammo = 0
		game._process(0.05)
		expect(is_equal_approx(boss.reload_timer,4.0-speed*0.05), "Boss reload follows speed %d" % speed)
	game.profile.activeRun = {}
	game.start_run()
	game._spawn_enemy_at({"position":game.player.position+Vector2(90,0)},"void_boss")
	boss = game.enemies[-1]
	var direction: Vector2 = game._get_enemy_desired_direction(boss,game.player.position)
	expect(absf(direction.y)>0.1 and direction.x>0, "Boss moves outward when inside its preferred outer orbit")
	var angle: float = boss.flight_heading
	game._update_enemy_movement(0.1)
	expect(absf(wrapf(boss.flight_heading-angle,-PI,PI)) <= deg_to_rad(3.0)+0.00001, "Boss turn is limited to 30 degrees per second")
	var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
	for position in [Vector2(bounds.position.x,bounds.get_center().y),Vector2(bounds.end.x,bounds.get_center().y),Vector2(bounds.get_center().x,bounds.position.y),Vector2(bounds.get_center().x,bounds.end.y)]:
		boss.position = position
		var inward: Vector2 = (bounds.get_center()-position).normalized()
		direction = game._get_enemy_desired_direction(boss,game.player.position)
		expect(direction.dot(inward)>0, "Boss edge steering points back into arena")

func _test_fleet_navigation(game) -> void:
	game.profile = game.profile_store._default_profile()
	game.start_run()
	game.rng.seed=37
	var center: Vector2=game.player.position
	var fleet_sign: float = game._fleet_orbit_sign()
	var layers := {}
	for index in range(6):
		game._spawn_enemy_at({"position":center+Vector2(100+index,0)},"void_drone")
		var fleet_enemy: Dictionary=game.enemies[-1]
		expect(fleet_enemy.orbit_sign==fleet_sign,"All ships inherit one saved fleet orbit direction")
		expect(int(fleet_enemy.flight_layer) in [-1,0,1],"Flight layer is one of three visual altitude lanes")
		layers[int(fleet_enemy.flight_layer)]=true
	expect(layers.size()==3,"Deterministic fleet IDs distribute ships over all three altitude lanes")
	game.enemies.clear()
	game._spawn_enemy_at({"position":center+Vector2(100,0)},"void_drone")
	game._spawn_enemy_at({"position":center+Vector2(100,0)},"void_drone")
	game.enemies[0].flight_layer=-1
	game.enemies[1].flight_layer=1
	var shared_crossing_position: Vector2=game.enemies[0].position
	game._separate_enemies()
	expect(game.enemies[0].position==shared_crossing_position and game.enemies[1].position==shared_crossing_position,"Different altitude lanes may pass directly over or under each other")
	for id in Navigation.TYPES:
		game.enemies.clear()
		game.enemy_projectiles.clear()
		game._spawn_enemy_at({"position":center+Vector2(100,0)},id)
		var enemy: Dictionary=game.enemies[0]
		var spec: Dictionary=Navigation.TYPES[id]
		expect(enemy.cruise_factor>=0.88 and enemy.cruise_factor<=1.0,"Saved cruise preference within range: "+id)
		expect(enemy.navigation_radius>enemy.radius,"Navigation uses visible hull instead of hitbox: "+id)
		expect(float(spec.orbit)>0.0 and float(spec.approach)>0.0,"Every active type has an inward orbit: "+id)
		enemy.approach_time=float(spec.delay)
		var outer_distance: float=Navigation.preferred_distance(enemy,120.0)
		enemy.approach_time=float(spec.delay)+float(spec.approach)*0.5
		var middle_distance: float=Navigation.preferred_distance(enemy,120.0)
		enemy.approach_time=float(spec.delay)+float(spec.approach)
		var impact_distance: float=Navigation.preferred_distance(enemy,120.0)
		expect(outer_distance>middle_distance and middle_distance>impact_distance and impact_distance<Navigation.safe_distance(enemy),"Orbit contracts gradually through contact: "+id)
		enemy.approach_time=0.0
		enemy.approach_progress=0.0
		var last_speed := 0.0
		var last_angle: float=enemy.flight_heading
		for frame in range(300):
			game._update_enemy_movement(1.0/60)
			var speed: float=enemy.velocity.length()
			expect(absf(speed-last_speed)<=float(spec.top)*4.0/60+0.001,"Linear acceleration/braking bounded: "+id)
			expect(absf(wrapf(enemy.flight_heading-last_angle,-PI,PI))<=deg_to_rad(float(spec.turn))/60+0.00001,"Heading turns smoothly: "+id)
			last_speed=speed
			last_angle=enemy.flight_heading
		# Independently exercise each weapon, without movement obscuring its cycle.
		enemy.position=center+Vector2(100,0)
		enemy.scout_phase="approach"
		enemy.fire_cooldown=0.0
		enemy.attack_warmup_timer=0.0
		enemy.attack_direction=Vector2.LEFT
		enemy.reload_timer=0.0
		var cycle: Dictionary=Weapons.CYCLES.get(str(enemy.attack_behavior),{})
		if cycle.is_empty():
			expect(str(enemy.attack_behavior)=="contact","Contact-only active type has no projectile cycle: "+id)
			continue
		enemy.ammo=int(cycle.magazine)
		game._update_enemy_weapons(0.0)
		game._update_enemy_weapons(float(cycle.warmup))
		expect(game.enemy_projectiles.size()==1,"Every active projectile type fires: "+id)
		var shot: Dictionary=game.enemy_projectiles[0]
		expect(is_equal_approx(float(shot.damage),float(cycle.damage)) and shot.damage_multiplier==1.0,"Explicit projectile damage has no second multiplier: "+id)
		if id=="red_scout":
			enemy.reload_timer=0.0
			enemy.fire_cooldown=0.0
			enemy.ammo=1
			enemy.scout_phase="reposition"
			game._update_enemy_weapons(1.0)
			expect(game.enemy_projectiles.size()==1 and enemy.ammo==1,"Scout cannot shoot while breaking away")
		enemy.scout_goal=center+Vector2(90,10)
		enemy.scout_phase="reposition"
		enemy.boss_orbit_time=31.25
		enemy.hp=7.25
		game._save_run()
		var saved: String=JSON.stringify(Store.encode(enemy))
		game._restore_run()
		expect(JSON.stringify(Store.encode(game.enemies[0]))==saved,"Complete flight and weapon state resumes exactly: "+id)
		var snapshot: Dictionary=Store.decode(game.profile.activeRun)
		for key in ["nav_preference","cruise_factor","variation_phase","scout_goal","scout_line","scout_phase","boss_orbit_time","nav_time","approach_time","approach_progress","escape_timer","avoid_side","avoid_timer","nav_entered","nav_target_distance"]: snapshot.enemies[0].erase(key)
		var rng_before: String=snapshot.rng_state
		game.profile.activeRun=Store.encode(snapshot)
		game._restore_run()
		expect(game.enemies[0].hp==7.25 and str(game.rng.state)==rng_before and game.enemies[0].has("nav_preference"),"Old encounter gets deterministic navigation without HP refill or RNG consumption: "+id)
		game.status="running"
	game.enemies.clear()
	game.enemy_projectiles.clear()
	game._spawn_enemy_at({"position":center+Vector2(190,0)},"void_boss")
	var boss: Dictionary=game.enemies[0]
	expect(boss.max_hp==400 and boss.speed==10,"New boss starts with more hull and lower top speed")
	game._update_enemy_movement(0.1)
	expect(boss.boss_orbit_time==0,"Boss spiral contraction waits until arrival")
	boss.position=center+Vector2(108,0)
	for frame in range(1800):game._update_enemy_movement(1.0/30.0)
	expect(is_equal_approx(boss.boss_orbit_time,60) and float(boss.approach_progress)>0.0 and boss.position.distance_to(center)>Navigation.safe_distance(boss),"Boss slowly contracts while continuing its orbit")
	game._apply_damage_to_player(game._get_incoming_damage(0.1),"HIT")
	expect(is_equal_approx(game._get_incoming_damage(0.1),0.1),"Small railgun damage is not inflated to a whole point")
	game.enemies.clear()
	game._spawn_enemy_at({"position":center+Vector2(100,0)},"red_scout")
	game.enemies[0].scout_goal=center+Vector2(-100,0)
	var previous: Vector2=game.get_viewport_rect().size
	var old_goal: Vector2=game.enemies[0].scout_goal
	var old_bounds: Rect2=game._get_playfield_rect(previous)
	var resized := previous+Vector2(100,100)
	var new_bounds: Rect2=game._get_playfield_rect(resized)
	game._remap_viewport(previous,resized)
	expect(game.enemies[0].scout_goal.is_equal_approx(new_bounds.position+(old_goal-old_bounds.position)*new_bounds.size/old_bounds.size),"Resize remaps the saved Scout waypoint")
