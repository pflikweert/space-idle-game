extends SceneTree

const Store := preload("res://scripts/profile_store.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const WeaponRegistry := preload("res://scripts/systems/weapon_registry.gd")
const Game := preload("res://scripts/void_drifter_game.gd")

var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run_tests")

func _enemy(enemy_id: int, position: Vector2, hp := 100.0) -> Dictionary:
	return {"id":enemy_id,"hp":hp,"max_hp":hp,"position":position,"radius":8.0,"type_id":"void_drone","cash_reward":0.0,"coin_reward":0.0,"score_reward":0}

func run_tests() -> void:
	root.size = Vector2i(390, 844)
	var profile := Store.new()._default_profile()
	profile.unlockedEquipmentBlueprints.append(Equipment.MICRO_MISSILE_RACK_ID)
	profile.equipmentItems[Equipment.MICRO_MISSILE_RACK_INSTANCE_ID] = {"id":Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,"blueprint_id":Equipment.MICRO_MISSILE_RACK_ID,"level":1}
	profile.equipmentInventory.append(Equipment.MICRO_MISSILE_RACK_INSTANCE_ID)
	profile.ships.starter_ship.loadout.W2 = Equipment.MICRO_MISSILE_RACK_INSTANCE_ID
	profile.permanentUpgrades.damage = 2
	var store := Store.new()
	store.profile_path = OS.get_cache_dir().path_join("void-missiles-%d.json" % Time.get_ticks_usec())
	store.save_profile(profile)
	var game := Game.new()
	game.profile_store = store
	root.add_child(game)
	game.set_process(false)
	game.profile = profile
	game.metaProgress = profile
	game.reset_world("menu")
	game.start_run()
	game.set_process(false)
	var origin: Vector2 = game.player.position
	var entry := {"item":profile.equipmentItems[Equipment.MICRO_MISSILE_RACK_INSTANCE_ID],"blueprint":Equipment.definition(Equipment.MICRO_MISSILE_RACK_ID)}
	var stats: Dictionary = game._weapon_runtime_stats(entry)
	var missile_mount := Equipment.definition(Equipment.MICRO_MISSILE_RACK_ID)
	var volley_stats := Equipment.micro_missile_stats(10)
	var impact_burst_stats := Equipment.micro_missile_stats(30)
	var shatter_stats := Equipment.micro_missile_stats(35)
	var echo_stats := Equipment.micro_missile_stats(40)
	expect(int(volley_stats.volley_bonus) == 3 and is_equal_approx(float(volley_stats.damage_multiplier),1.28), "Missile Volley adds three missiles and applies the twenty percent per-missile damage penalty")
	expect(is_equal_approx(float(Equipment.micro_missile_stats(15).explosion_radius_multiplier),1.3) and is_equal_approx(float(Equipment.micro_missile_stats(15).explosion_ratio_multiplier),1.3), "Blast Amplifier scales radius and explosion damage independently")
	expect(is_equal_approx(float(Equipment.micro_missile_stats(20).super_chance),0.3) and is_equal_approx(float(Equipment.micro_missile_stats(20).super_multiplier),3.0), "Enhanced Missile resolves the Super Missile chance and multiplier")
	expect(int(Equipment.micro_missile_stats(25).splinter_count) == 2 and is_equal_approx(float(Equipment.micro_missile_stats(25).splinter_damage_ratio),0.25), "Splinter Missiles creates two impact-only splinters")
	expect(is_equal_approx(float(impact_burst_stats.small_explosion_chance),0.3), "Impact Burst applies its thirty percent small-missile explosion chance")
	expect(int(shatter_stats.fragment_count) == 4 and is_equal_approx(float(shatter_stats.fragment_damage_ratio),0.25), "Shatter Strike Core creates four impact fragments")
	expect(is_equal_approx(float(echo_stats.echo_damage_ratio),0.6) and is_equal_approx(float(echo_stats.echo_radius_multiplier),1.5), "Echo Detonation resolves its secondary explosion payload")
	expect(str(missile_mount.mount_art).contains("weapon_socket_cover") and not str(missile_mount.overlay_art).is_empty() and not bool(missile_mount.rotates_to_target),"Missile payload sits on the complete fixed weapon-socket cover")
	expect(is_equal_approx(float(stats.damage),11.648),"Missile level one scales from permanent Ship Attack")
	expect(is_equal_approx(float(stats.range), 200.0), "Missile level 1 range starts at 200 units")
	expect(is_equal_approx(game._weapon_target_range(Equipment.MICRO_MISSILE_RACK_ID, stats), 200.0), "Missile target range uses its own baseline")
	profile.permanentUpgrades.range = 2
	game.run_upgrades.range = 3
	game.run_upgrades.damage = 3
	game.metaProgress = profile
	stats = game._weapon_runtime_stats(entry)
	expect(is_equal_approx(float(stats.damage),13.74464),"Run Attack scales Micro Missiles from the same layered Ship Attack stat")
	var upgraded_range := game._weapon_target_range(Equipment.MICRO_MISSILE_RACK_ID, stats)
	expect(is_equal_approx(upgraded_range, 215.3375), "Workshop and run range multipliers add to missile range")
	profile.permanentUpgrades.crit_chance = 50
	game.metaProgress = profile
	var critical_stats: Dictionary = game._weapon_runtime_stats(entry)
	expect(is_equal_approx(float(critical_stats.crit), 0.5), "Universal Workshop Critical Chance reaches every weapon from the ship baseline")
	profile.permanentUpgrades.crit_chance = 0
	game.metaProgress = profile
	stats = game._weapon_runtime_stats(entry)

	game.enemies = [_enemy(101, origin + Vector2(0, -80)), _enemy(102, origin + Vector2(70, -20))]
	game._update_weapons(1000.0)
	var missile: Dictionary = {}
	var missile_count := 0
	for bullet in game.bullets:
		if str(bullet.get("visual_kind", "")) == "micro_missile":
			missile_count += 1
			if bool(bullet.get("launched", false)): missile = bullet
	expect(missile_count == 3, "Missile weapon fires a three-rocket salvo")
	expect(game.mount_visuals.has(Equipment.MICRO_MISSILE_RACK_INSTANCE_ID) and str(game.mount_visuals[Equipment.MICRO_MISSILE_RACK_INSTANCE_ID].kind) == "missile", "Missile salvo triggers the equipped rack visual")
	expect(is_equal_approx(float(missile.velocity.length()), 210.0), "Missile speed is 210 units per second after the 50 percent reduction")
	var lanes := []
	for bullet in game.bullets:
		if str(bullet.get("visual_kind", "")) == "micro_missile": lanes.append(float(bullet.launch_lane))
	lanes.sort()
	expect(lanes == [-1.0, 0.0, 1.0], "Salvo uses fixed left, middle and right launch lanes")
	expect(float(missile.boost_remaining) > 0.0 and missile.trail_points.size() == 1, "Missile begins with a short boost and path history")
	var launch_delays := []
	var launched_count := 0
	for bullet in game.bullets:
		if str(bullet.get("visual_kind", "")) == "micro_missile":
			launch_delays.append(float(bullet.launch_delay))
			if bool(bullet.launched): launched_count += 1
	launch_delays.sort()
	expect(launched_count == 1 and launch_delays == [0.0, 0.075, 0.15], "Salvo staggers rockets by a small launch delay")
	var missile_runtime: Dictionary = game.weapon_runtime_by_item_id[Equipment.MICRO_MISSILE_RACK_INSTANCE_ID]
	expect(int(missile_runtime.ammo) == 0 and float(missile_runtime.reload_timer) > 0.0, "Missile salvo consumes the full three-rocket magazine")
	expect(is_equal_approx(float(missile.remaining_distance), 615.3375), "Missile flight budget is current range plus 400")

	missile.position = origin
	missile.previous_position = origin
	missile.velocity = Vector2.RIGHT * 210.0
	missile.remaining_distance = 610.0
	missile.target_id = 101
	missile.boost_remaining = 0.0
	game._update_projectiles(0.1)
	var turn_angle := absf(Vector2.RIGHT.angle_to(missile.velocity.normalized()))
	expect(turn_angle > 0.01 and turn_angle <= 0.81, "Blue missile turns directly without a broad arc")
	missile.position = origin
	missile.previous_position = origin
	missile.velocity = Vector2.RIGHT * 210.0
	missile.remaining_distance = 610.0
	missile.target_id = 101
	missile.boost_remaining = 0.0
	game._update_projectiles(0.1)
	var second_turn_angle := absf(Vector2.RIGHT.angle_to(missile.velocity.normalized()))
	expect(second_turn_angle > 0.01 and second_turn_angle <= 0.81, "Missile turn rate remains deterministic")
	game.enemies = [_enemy(101, origin + Vector2(0, -80))]
	game.bullets.clear()
	game.rng.seed = 41
	game._fire_runtime_weapon(missile_runtime, stats)
	var missile_damage_valid := true
	for bullet in game.bullets:
		if str(bullet.get("visual_kind", "")) == "micro_missile":
			missile_damage_valid = missile_damage_valid and is_equal_approx(float(bullet.damage), float(stats.damage))
	expect(missile_damage_valid, "Every missile uses the resolved module damage")

	game.enemies = [_enemy(101, origin + Vector2(0, -80)), _enemy(102, origin + Vector2(70, -20))]
	game.enemies[0].hp = 0.0
	missile.position = origin
	missile.velocity = Vector2.LEFT * 210.0
	missile.boost_remaining = 0.0
	game._update_missile_heading(missile, 0.01)
	var retarget_turn := absf(Vector2.LEFT.angle_to(missile.velocity.normalized()))
	expect(int(missile.target_id) == 102 and retarget_turn > 0.1 and retarget_turn < 0.2 and is_equal_approx(float(missile.retarget_correction_remaining), 42.0), "Dead-target retargeting curves over a short correction distance")

	game.enemies.clear()
	var limited := WeaponRegistry.build_projectile(70001, origin, Vector2.RIGHT, 1.0, false, 10.0)
	limited.visual_kind = "micro_missile"
	limited.target_id = -1
	game.bullets = [limited]
	game._update_projectiles(1.0)
	expect(is_equal_approx(float(limited.remaining_distance), 0.0) and is_equal_approx(limited.position.x - origin.x, 10.0), "Missile stops at its exact remaining flight distance")
	limited.remaining_distance = 50.0
	game.enemies = [_enemy(103, limited.position + Vector2(100, 0))]
	game._update_missile_heading(limited, 0.1)
	expect(int(limited.target_id) == -1, "Missile ignores targets outside its remaining flight zone")

	var kill_target := _enemy(201, origin + Vector2(42, 0), 10.0)
	var continuing := WeaponRegistry.build_projectile(70003, origin, Vector2.RIGHT, 20.0, false, 600.0)
	continuing.visual_kind = "micro_missile"; continuing.velocity = Vector2.RIGHT * 210.0; continuing.position = origin + Vector2(80, 0); continuing.previous_position = origin
	continuing.remaining_distance = 520.0; continuing.life = 520.0 / 210.0; continuing.target_id = 201; continuing.hit_ids = []; continuing.hits_left = 1; continuing.launched = true; continuing.boost_remaining = 0.0; continuing.trail_points = [origin, continuing.position]
	game.enemies = [kill_target]
	game.bullets = [continuing]
	game._resolve_collisions()
	expect(game.bullets.is_empty(), "Missile ends on every impact, including a killing hit")

	var durable_target := _enemy(203, origin + Vector2(42, 0), 100.0)
	var stopping := WeaponRegistry.build_projectile(70004, origin, Vector2.RIGHT, 20.0, false, 600.0)
	stopping.visual_kind = "micro_missile"; stopping.velocity = Vector2.RIGHT * 210.0; stopping.position = origin + Vector2(80, 0); stopping.previous_position = origin
	stopping.remaining_distance = 520.0; stopping.life = 520.0 / 210.0; stopping.target_id = 203; stopping.hit_ids = []; stopping.hits_left = 1; stopping.launched = true; stopping.boost_remaining = 0.0; stopping.trail_points = [origin, stopping.position]
	game.enemies = [durable_target]
	game.bullets = [stopping]
	game._resolve_collisions()
	expect(game.bullets.is_empty(), "Missile ends on a non-lethal direct hit")

	var railgun := WeaponRegistry.build_projectile(70002, origin, Vector2.RIGHT, 1.0, false, 10.0)
	game.bullets = [railgun]
	game._update_projectiles(0.1)
	expect(railgun.velocity.normalized() == Vector2.RIGHT, "Railgun projectile remains straight")
	var moving_target := _enemy(204, origin + Vector2(0, -120), 100.0)
	var precision_railgun := WeaponRegistry.build_projectile(70005, origin, Vector2.UP, 20.0, false, 180.0)
	precision_railgun.target_id = 204
	moving_target.position += Vector2(80, 0)
	game.enemies = [moving_target]
	game.bullets = [precision_railgun]
	game._update_projectiles(0.1)
	game._resolve_collisions()
	expect(moving_target.hp < 100.0, "Railgun corrects onto its moving target instead of missing")

	print("Missile checks: %d passed / %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
