extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/profile_store.gd")
const Navigation = preload("res://scripts/systems/enemy_navigation.gd")

class MemoryStore extends Store:
	func load_profile() -> Dictionary: return _default_profile()
	func save_profile(_profile: Dictionary) -> bool: return true

var game

func _initialize() -> void:
	call_deferred("measure")

func reset_run() -> void:
	game.profile.activeRun = {}
	game.start_run()
	game.set_process(false)
	game.player.hp = 1e9
	game.player.max_hp = 1e9
	game.player.shield = 0.0
	game.player.position = game._get_playfield_rect(root.size).get_center()
	game.player_target = game.player.position
	game.enemies.clear()
	game.enemy_projectiles.clear()

func measure() -> void:
	root.size = Vector2i(430, 760)
	game = Scene.instantiate()
	game.profile_store = MemoryStore.new()
	root.add_child(game)
	for id in Navigation.TYPES:
		reset_run()
		game._spawn_enemy_at({"position": game.player.position + Vector2(116, 0)}, id)
		var enemy: Dictionary = game.enemies[0]
		var spec: Dictionary = Navigation.TYPES[id]
		var previous_angle: float = (enemy.position - game.player.position).angle()
		var angular_travel := 0.0
		var start_distance: float = enemy.position.distance_to(game.player.position)
		var first_contact := -1.0
		var contact_ticks := 0
		var previous_cooldown := 0.0
		var duration: float = float(spec.delay) + float(spec.approach) + 30.0
		for frame in range(int(duration * 30.0)):
			game._update_enemy_movement(1.0 / 30.0)
			game._resolve_collisions()
			var angle: float = (enemy.position - game.player.position).angle()
			angular_travel += absf(wrapf(angle - previous_angle, -PI, PI))
			previous_angle = angle
			if float(enemy.contact_cooldown) > previous_cooldown + 0.05:
				contact_ticks += 1
				if first_contact < 0.0: first_contact = frame / 30.0
			previous_cooldown = float(enemy.contact_cooldown)
		print("SPIRAL ", JSON.stringify({
			"type": id,
			"start_distance": start_distance,
			"end_distance": enemy.position.distance_to(game.player.position),
			"first_contact_seconds": first_contact,
			"contact_ticks": contact_ticks,
			"orbits": angular_travel / TAU,
			"top_speed": float(spec.top),
		}))
	reset_run()
	for index in range(44):
		var type_id: String = "void_boss" if index >= 40 else ["void_drone", "red_scout", "void_tank", "ranged_shooter"][index % 4]
		game._spawn_enemy_at({
			"position": game.player.position + Vector2.RIGHT.rotated(index * 2.39996) * (105.0 + index % 5 * 20.0),
		}, type_id)
	var visual_overlaps := 0
	var deep_overlaps := 0
	var same_layer_deep_overlaps := 0
	var cross_layer_overlaps := 0
	var stalled := 0
	var samples := 0
	var maximum_speed_ratio := 0.0
	for frame in range(5400):
		game._update_enemy_movement(1.0 / 30.0)
		game._resolve_collisions()
		if frame < 300 or frame % 10 != 0: continue
		samples += 1
		for index in range(game.enemies.size()):
			var a: Dictionary = game.enemies[index]
			var a_spec: Dictionary = Navigation.TYPES[str(a.type_id)]
			maximum_speed_ratio = maxf(maximum_speed_ratio, a.velocity.length() / float(a_spec.top))
			if a.velocity.length() < 0.5: stalled += 1
			for other_index in range(index + 1, game.enemies.size()):
				var b: Dictionary = game.enemies[other_index]
				var distance: float = a.position.distance_to(b.position)
				if distance < float(a.navigation_radius) + float(b.navigation_radius): visual_overlaps += 1
				if distance < (float(a.radius) + float(b.radius)) * 0.65:
					deep_overlaps += 1
					if int(a.flight_layer)==int(b.flight_layer): same_layer_deep_overlaps += 1
					else: cross_layer_overlaps += 1
	var contacted := 0
	for enemy in game.enemies:
		if bool(enemy.has_contacted): contacted += 1
	print("CROWD ", JSON.stringify({
		"visual_overlaps_per_sample": float(visual_overlaps) / samples,
		"deep_overlaps_per_sample": float(deep_overlaps) / samples,
		"same_layer_deep_overlaps_per_sample": float(same_layer_deep_overlaps) / samples,
		"cross_layer_overlaps_per_sample": float(cross_layer_overlaps) / samples,
		"stalled_per_sample": float(stalled) / samples,
		"ships_reaching_contact": contacted,
		"ships": game.enemies.size(),
		"maximum_speed_ratio": maximum_speed_ratio,
	}))
	game.queue_free()
	await process_frame
	quit()
