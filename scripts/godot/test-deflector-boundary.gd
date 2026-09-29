extends SceneTree

const Store := preload("res://scripts/profile_store.gd")
const Game := preload("res://scripts/void_drifter_game.gd")
const Navigation := preload("res://scripts/systems/enemy_navigation.gd")
const EnemyWeapons := preload("res://scripts/systems/enemy_weapons.gd")

var checks := 0
var failures := 0
var game: Game

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func fresh() -> void:
	game.enemies.clear()
	game.enemy_projectiles.clear()
	game.bullets.clear()
	game.particles.clear()
	game.player.position = game._get_playfield_rect(root.size).get_center()
	game.player_target = game.player.position
	game.player.hp = 1000000.0
	game.player.max_hp = 1000000.0
	game.player.shield = 0.0
	game.player.max_shield = 0.0

func spawn(type_id: String, distance := 180.0) -> Dictionary:
	game._spawn_enemy_at({"position":game.player.position + Vector2.RIGHT * distance, "edge":"right"}, type_id)
	return game.enemies.back()

func outside_deflector(enemy: Dictionary) -> bool:
	return enemy.position.distance_to(game.player.position) + 0.001 >= game._player_deflector_radius() + float(enemy.radius)

func run_tests() -> void:
	root.size = Vector2i(430, 760)
	var profile := Store.new()._default_profile()
	var store := Store.new()
	store.profile_path = OS.get_cache_dir().path_join("void-deflector-%d.json" % Time.get_ticks_usec())
	store.save_profile(profile)
	game = Game.new()
	game.profile_store = store
	root.add_child(game)
	game.set_process(false)
	game.profile = profile
	game.metaProgress = profile
	game.reset_world("menu")
	game.start_run()
	game.set_process(false)

	for type_id in Navigation.TYPES:
		fresh()
		var enemy := spawn(type_id)
		var minimum := INF
		for _frame in range(900):
			game._update_enemy_movement(1.0 / 30.0)
			game._resolve_collisions()
			minimum = minf(minimum, enemy.position.distance_to(game.player.position))
		expect(minimum + 0.001 >= game._player_deflector_radius() + float(enemy.radius), "%s never crosses the deflector during normal navigation" % type_id)

	fresh()
	var contact := spawn("void_drone", game._player_deflector_radius() + 2.0)
	game._resolve_collisions()
	expect(outside_deflector(contact) and bool(contact.has_contacted), "contact resolves on and ejects to the deflector boundary")

	fresh()
	var fast := spawn("void_swarm")
	var high_delta_safe := true
	for _frame in range(120):
		game._update_enemy_movement(0.20)
		game._resolve_collisions()
		high_delta_safe = high_delta_safe and outside_deflector(fast)
	expect(high_delta_safe, "high simulation deltas cannot tunnel a swarm through the deflector")

	fresh()
	var surface := game._player_deflector_surface(game.player.position + Vector2.RIGHT * 220.0)
	expect(is_equal_approx(surface.distance_to(game.player.position), game._player_deflector_radius()) and surface.x > game.player.position.x, "surface helper returns the nearest outer deflector point")
	var shooter := spawn("void_drone")
	shooter.attack_direction = Vector2.LEFT
	EnemyWeapons.fire(game, shooter)
	var fired: Dictionary = game.enemy_projectiles.back()
	var expected_direction: Vector2 = (game._player_deflector_surface(fired.position, Vector2.LEFT) - fired.position).normalized()
	expect(fired.velocity.normalized().dot(expected_direction) > 0.999, "enemy rail fire is aimed at the closest deflector surface")

	fresh()
	var radius := game._player_deflector_radius()
	var rail_start: Vector2 = game.player.position + Vector2.RIGHT * (radius + 60.0)
	var rail_end: Vector2 = game.player.position - Vector2.RIGHT * (radius + 60.0)
	game.enemy_projectiles = [{"id":99001, "weapon_id":"enemy_railgun", "position":rail_end, "previous_position":rail_start, "radius":2.0, "velocity":Vector2.LEFT * 500.0, "damage":1.0, "damage_multiplier":1.0, "life":1.0, "visual_trail_points":[rail_start,rail_end]}]
	game._resolve_collisions()
	var traces: Array = game.particles.filter(func(effect): return str(effect.get("kind","")) == "enemy_trace")
	var trace: Dictionary = traces.back() if not traces.is_empty() else {}
	expect(game.enemy_projectiles.is_empty() and not trace.is_empty() and is_equal_approx(Vector2(trace.end).distance_to(game.player.position), radius + 2.0), "swept enemy rail stops and draws on the deflector surface")
	expect(absf(wrapf(game.gunship.hit_angle, -PI, PI)) < 0.01, "incoming rail feedback is placed on the nearest shield-side rim")

	fresh()
	var rocket := {"weapon_id":"boss_rocket", "position":game.player.position + Vector2.RIGHT * (radius + 50.0), "previous_position":game.player.position + Vector2.RIGHT * (radius + 50.0), "velocity":Vector2.UP * 85.0, "life":4.0, "visual_trail_points":[]}
	EnemyWeapons.move_projectile(game, rocket, 0.10)
	expect(Vector2(rocket.velocity).dot(Vector2.LEFT) > 0.0, "guided rocket turns toward the current nearest deflector surface")

	print("Deflector checks: %d passed / %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run_tests")
